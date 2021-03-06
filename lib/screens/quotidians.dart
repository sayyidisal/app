import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:memorare/components/error_container.dart';
import 'package:memorare/components/order_lang_button.dart';
import 'package:memorare/components/quote_card.dart';
import 'package:memorare/components/web/empty_content.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import'package:memorare/components/loading_animation.dart';
import 'package:memorare/components/web/sliver_app_header.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';
import 'package:memorare/state/colors.dart';
import 'package:memorare/state/topics_colors.dart';
import 'package:memorare/types/quotidian.dart';
import 'package:memorare/utils/app_localstorage.dart';
import 'package:memorare/utils/auth.dart';
import 'package:memorare/utils/converter.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:supercharged/supercharged.dart';

class Quotidians extends StatefulWidget {
  @override
  QuotidiansState createState() => QuotidiansState();
}

class QuotidiansState extends State<Quotidians> {
  bool canManage      = false;
  bool hasNext        = true;
  bool hasErrors      = false;
  bool isLoading      = false;
  bool isLoadingMore  = false;
  String lang         = 'en';
  int limit           = 30;
  bool descending     = false;
  final pageRoute     = QuotidiansRoute;

  List<Quotidian> quotidians = [];
  ScrollController scrollController = ScrollController();

  var lastDoc;

  @override
  initState() {
    super.initState();
    checkAuth(context: context);
    getSavedLangAndOrder();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await fetch();
          return null;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollNotif) {
            if (scrollNotif.metrics.pixels < scrollNotif.metrics.maxScrollExtent - 100.0) {
              return false;
            }

            if (hasNext && !isLoadingMore) {
              fetchMore();
            }

            return false;
          },
          child: LayoutBuilder(
            builder: (context, constrains) {
              return bodyContent(
                maxWidth: constrains.maxWidth,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget appBar()  {
    return SliverAppHeader(
      title: 'Quotidians',
      onScrollToTop: () {
        if (quotidians.length == 0) { return; }

        scrollController.animateTo(
          0,
          duration: Duration(seconds: 2),
          curve: Curves.easeOutQuint
        );
      },
      rightButton: OrderLangButton(
        descending: descending,
        lang: lang,
        onLangChanged: (String newLang) {
          appLocalStorage.setPageLang(
            lang: newLang,
            pageRoute: pageRoute,
          );

          setState(() {
            lang = newLang;
          });

          fetch();
        },
        onOrderChanged: (bool order) {
          appLocalStorage.setPageOrder(
            descending: order,
            pageRoute: pageRoute,
          );

          setState(() {
            descending = order;
          });

          fetch();
        },
      ),
    );
  }

  Widget bodyContent({double maxWidth}) {
    return CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        appBar(),

        if (maxWidth < 600.0) customScrollViewChild(),
        if (maxWidth >= 600.0) ...groupedGrids(),
      ],
    );
  }

  Widget customScrollViewChild() {
    if (isLoading) {
      return loadingView();
    }

    if (quotidians.length == 0) {
      return emptyView();
    }

    if (!isLoading && hasErrors) {
      return errorView();
    }

    return groupedLists();
  }

  Widget emptyView() {
    return SliverList(
      delegate: SliverChildListDelegate([
          FadeInY(
            delay: 2.0,
            beginY: 50.0,
            child: EmptyContent(
              icon: Opacity(
                opacity: .8,
                child: Icon(
                  Icons.sentiment_neutral,
                  size: 120.0,
                  color: Color(0xFFFF005C),
                ),
              ),
              title: "You've no quote in validation at this moment",
              subtitle: 'They will appear after you propose a new quote',
              onRefresh: () => fetch(),
            ),
          ),
        ]
      ),
    );
  }

  Widget errorView() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: ErrorContainer(
            onRefresh: () => fetch(),
          ),
        ),
      ]),
    );
  }

  List<Widget> groupedGrid(String yearMonth, List<Quotidian> grouped) {
    final headerKey = GlobalKey();

    return [
      SliverStickyHeader(
        header: headerGroup(
          headerKey: headerKey,
          yearMonth: yearMonth,
          group: grouped,
        ),
        sliver: SliverPadding(
          key: headerKey,
          padding: const EdgeInsets.all(10.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300.0,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final quote = grouped.elementAt(index);
                return itemGrid(quote);
              },
              childCount: grouped.length,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> groupedGrids() {
    final List<Widget> widgets = [];

    if (isLoading) {
      widgets.add(loadingView());
      return widgets;
    }

    if (quotidians.length == 0) {
      widgets.add(emptyView());
      return widgets;
    }

    if (!isLoading && hasErrors) {
      widgets.add(errorView());
      return widgets;
    }

    final Map<String, List<Quotidian>> groups = quotidians.groupBy(
      (quotidian) => '${quotidian.date.year}-${quotidian.date.month}',
    );


    groups.forEach((yearMonth, groupedQuotidians) {
      final grid = groupedGrid(yearMonth, groupedQuotidians);
      widgets.addAll(grid);
    });

    return widgets;
  }

  List<Widget> groupedList(String yearMonth, List<Quotidian> group) {
    final headerKey = GlobalKey();

    return [
      StickyHeader(
        key: headerKey,
        header: headerGroup(
          headerKey: headerKey,
          yearMonth: yearMonth,
          group: group,
        ),
        content: itemList(group),
      ),
    ];
  }

  Widget groupedLists() {
    final Map<String, List<Quotidian>> groups = quotidians.groupBy(
      (quotidian) => '${quotidian.date.year}-${quotidian.date.month}',
    );

    final List<Widget> widgets = [];

    groups.forEach((yearMonth, groupedQuotidians) {
      final singleGroup = groupedList(yearMonth, groupedQuotidians);
      widgets.addAll(singleGroup);
    });

    return SliverList(
      delegate: SliverChildListDelegate(widgets),
    );
  }

  Widget headerGroup({
    GlobalKey<State<StatefulWidget>> headerKey,
    String yearMonth,
    List<Quotidian> group,
  }) {

    final splittedDate = yearMonth.split('-');

    final year = splittedDate[0];
    final month = getMonthFromNumber(splittedDate[1].toInt());

    return Container(
      color: stateColors.softBackground,
      child: Stack(
        children: <Widget>[
          FlatButton(
            onPressed: () {
              final renderObject = headerKey.currentContext.findRenderObject();
              renderObject.showOnScreen(duration: 1.seconds);
            },
            child: Padding(
              padding: const EdgeInsets.only(
                top: 35.0,
                bottom: 10.0,
              ),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Text(
                      '$month $year',
                    ),

                    SizedBox(
                      width: 100.0,
                      child: Divider(thickness: 2,),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 0.0,
            child: FlatButton(
              onPressed: () {
                deleteMonthDialog(yearMonth, group,);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 25.0,
                ),
                child: Icon(Icons.delete,),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget itemGrid(Quotidian quotidian) {
    final quote = quotidian.quote;
    final topicColor = appTopicsColors.find(quote.topics.first);

    return QuoteCard(
      onTap: () {
        FluroRouter.router.navigateTo(
          context,
          QuotePageRoute.replaceFirst(':id', quotidian.id)
        );
      },
      title: quote.name,
      popupMenuButton: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz,
          color: Color(topicColor.decimal),
        ),
        onSelected: (value) {
          if (value == 'delete') {
            deleteAction(quotidian);
            return;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
            )
          ),
        ],
      ),
      stackChildren: <Widget>[
        Positioned(
          bottom: 15.0,
          right: 60.0,
          child: Text(
            quotidian.date.day.toString(),
          ),
        ),
      ],
    );
  }

  /// Contains multiple children in a Column.
  Widget itemList(List<Quotidian> group) {
    return Column(
      children: group.map((quotidian) {
        final topicColor = appTopicsColors
          .find(quotidian.quote.topics.first);

        return InkWell(
          onTap: () {
            FluroRouter.router.navigateTo(
              context,
              QuotePageRoute.replaceFirst(':id', quotidian.quote.id),
            );
          },
          onLongPress: () => showQuoteSheet(quotidian: quotidian),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(padding: const EdgeInsets.only(top: 20.0),),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  quotidian.quote.name,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),

              Center(
                child: IconButton(
                  onPressed: () => showQuoteSheet(quotidian: quotidian),
                  icon: Icon(
                    Icons.more_horiz,
                    color: topicColor != null ?
                    Color(topicColor.decimal) : stateColors.primary,
                  ),
                ),
              ),

              Center(
                child: Opacity(
                  opacity: .6,
                  child: Text(
                    quotidian.date.day.toString(),
                  ),
                ),
              ),

              Padding(padding: const EdgeInsets.only(top: 10.0),),
              Divider(),
            ],
          ),
        );
      }).toList()
    );
  }

  Widget loadingView() {
    return SliverList(
      delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: LoadingAnimation(),
          ),
        ]
      ),
    );
  }

  void deleteAction(Quotidian quotidian) async {
    try {
      await Firestore.instance
        .collection('quotidians')
        .document(quotidian.id)
        .delete();

      setState(() {
        quotidians.removeWhere((element) => element.id == quotidian.id);
      });

      Scaffold.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'The quotidian has been successfully deleted.'
          ),
        )
      );

    } catch (error) {
      debugPrint(error.toString());

      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sorry, an error occurred while deleting the quotidian.'
          ),
        )
      );
    }
  }

  void deleteMonth(List<Quotidian> group) async {
    // NOTE: maybe do this job in a cloud function
    group.forEach((quotidian) async {
      await Firestore.instance
        .collection('quotidians')
        .document(quotidian.id)
        .delete();

      setState(() {
        quotidians.removeWhere((element) => element.id == quotidian.id);
      });
    });

  }

  void deleteMonthDialog(String yearMonth, List<Quotidian> grouped) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete $yearMonth group?',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15.0,
          ),
          actionsPadding: const EdgeInsets.all(10.0),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Divider(
                  thickness: 1.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: <Widget>[
                      Opacity(
                        opacity: .6,
                        child: Text(
                          'This action cannot be undone.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                FluroRouter.router.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    color: stateColors.foreground.withOpacity(.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            RaisedButton(
              onPressed: () {
                FluroRouter.router.pop(context);
                deleteMonth(grouped);
              },
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  'DELETE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  Future fetch() async {
    setState(() {
      isLoading = true;
      quotidians.clear();
    });


    try {
      final snapshot = await Firestore.instance
        .collection('quotidians')
        .where('lang', isEqualTo: lang)
        .orderBy('date', descending: descending)
        .limit(limit)
        .getDocuments();

      if (snapshot.documents.isEmpty) {
        setState(() {
          hasNext = false;
          isLoading = false;
        });

        return;
      }

      snapshot.documents.forEach((doc) {
        final data = doc.data;
        data['id'] = doc.documentID;

        final quotidian = Quotidian.fromJSON(data);
        quotidians.add(quotidian);
      });

      lastDoc = snapshot.documents.last;

      setState(() {
        hasNext = snapshot.documents.length == limit;
        isLoading = false;
      });

    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        hasNext = false;
        isLoading = false;
      });
    }
  }

  void fetchMore() async {
    if (lastDoc == null) {
      return;
    }

    isLoadingMore = true;

    try {
      final snapshot = await Firestore.instance
        .collection('quotidians')
        .where('lang', isEqualTo: lang)
        .orderBy('date', descending: descending)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .getDocuments();

      if (snapshot.documents.isEmpty) {
        setState(() {
          hasNext = false;
          isLoadingMore = false;
        });

        return;
      }

      snapshot.documents.forEach((doc) {
        final data = doc.data;
        data['id'] = doc.documentID;

        final quotidian = Quotidian.fromJSON(data);
        quotidians.add(quotidian);
      });

      setState(() {
        hasNext = snapshot.documents.length == limit;
        lastDoc = snapshot.documents.last;
        isLoadingMore = false;
      });

    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void getSavedLangAndOrder() {
    lang = appLocalStorage.getPageLang(pageRoute: pageRoute);
    descending = appLocalStorage.getPageOrder(pageRoute: pageRoute);
  }

  void showQuoteSheet({Quotidian quotidian}) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 60.0,
          ),
          child: Wrap(
            spacing: 30.0,
            alignment: WrapAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  IconButton(
                    iconSize: 40.0,
                    tooltip: 'Delete',
                    onPressed: () {
                      FluroRouter.router.pop(context);
                      deleteAction(quotidian);
                    },
                    icon: Opacity(
                      opacity: .6,
                      child: Icon(
                        Icons.delete_outline,
                      ),
                    ),
                  ),

                  Text(
                    'Delete',
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}
