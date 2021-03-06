import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memorare/actions/quotes.dart';
import 'package:memorare/actions/quotidians.dart';
import 'package:memorare/components/error_container.dart';
import 'package:memorare/components/order_lang_button.dart';
import 'package:memorare/components/web/empty_content.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import 'package:memorare/components/loading_animation.dart';
import 'package:memorare/components/quote_card.dart';
import 'package:memorare/components/web/sliver_app_header.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';
import 'package:memorare/state/colors.dart';
import 'package:memorare/state/topics_colors.dart';
import 'package:memorare/state/user_state.dart';
import 'package:memorare/types/quote.dart';
import 'package:memorare/utils/app_localstorage.dart';
import 'package:memorare/utils/snack.dart';

class AdminQuotes extends StatefulWidget {
  @override
  AdminQuotesState createState() => AdminQuotesState();
}

class AdminQuotesState extends State<AdminQuotes> {
  bool canManage = false;
  bool hasNext = true;
  bool hasErrors = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  String lang = 'en';
  int limit = 30;
  bool descending = true;

  List<Quote> quotes = [];
  ScrollController scrollController = ScrollController();

  var lastDoc;

  @override
  initState() {
    super.initState();
    getSavedLangAndOrder();
    checkAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body(),
    );
  }

  Widget body() {
    return RefreshIndicator(
        onRefresh: () async {
          await fetch();
          return null;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollNotif) {
            if (scrollNotif.metrics.pixels <
                scrollNotif.metrics.maxScrollExtent) {
              return false;
            }

            if (hasNext && !isLoadingMore) {
              fetchMore();
            }

            return false;
          },
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              appBar(),
              bodyListContent(),
            ],
          ),
        ));
  }

  Widget appBar() {
    return SliverAppHeader(
      title: 'All published',
      rightButton: OrderLangButton(
        descending: descending,
        lang: lang,
        onLangChanged: (String newLang) {
          appLocalStorage.setPageLang(
            lang: newLang,
            pageRoute: QuotesRoute,
          );

          setState(() {
            lang = newLang;
          });

          fetch();
        },
        onOrderChanged: (bool order) {
          appLocalStorage.setPageOrder(
            descending: order,
            pageRoute: QuotesRoute,
          );

          setState(() {
            descending = order;
          });

          fetch();
        },
      ),
    );
  }

  Widget bodyListContent() {
    if (isLoading) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: LoadingAnimation(),
          ),
        ]),
      );
    }

    if (!isLoading && hasErrors) {
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

    if (quotes.length == 0) {
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
        ]),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constrains) {
        if (constrains.crossAxisExtent < 600.0) {
          return SliverPadding(
            padding: const EdgeInsets.only(
              top: 80.0,
            ),
            sliver: sliverList(),
          );

        } else {
          return SliverPadding(
            padding: const EdgeInsets.only(
              top: 80.0,
              left: 10.0,
              right: 10.0,
            ),
            sliver: sliverGrid(),
          );
        }
      },
    );
  }

  Widget quotePopupMenuButton({
    Quote quote,
    Color color,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: color,
      ),
      onSelected: (value) {
        if (value == 'quotidian') {
          addQuotidianAction(quote);
          return;
        }

        if (value == 'delete') {
          showDeleteDialog(quote);
          return;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
            value: 'quotidian',
            child: ListTile(
              leading: Icon(Icons.add),
              title: Text('Add to quotidians'),
            )),
        PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_sweep),
              title: Text('Delete'),
            )),
      ],
    );
  }

  Widget sliverGrid() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300.0,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final quote = quotes.elementAt(index);
          final topicColor = appTopicsColors.find(quote.topics.first);

          return QuoteCard(
            title: quote.name,
            onTap: () => FluroRouter.router.navigateTo(
              context, QuotePageRoute.replaceFirst(':id', quote.id)),
            popupMenuButton: quotePopupMenuButton(
              quote: quote,
              color: Color(topicColor.decimal),
            ),
          );
        },
        childCount: quotes.length,
      ),
    );
  }

  Widget sliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final quote = quotes.elementAt(index);
          final topicColor = appTopicsColors.find(quote.topics.first);

          return FadeInY(
            delay: index * 1.0,
            beginY: 50.0,
            child: InkWell(
              onTap: () => FluroRouter.router.navigateTo(
                  context, QuotePageRoute.replaceFirst(':id', quote.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      quote.name,
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Center(
                    child: quotePopupMenuButton(
                      quote: quote,
                      color: Color(topicColor.decimal),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                  ),
                  Divider(),
                ],
              ),
            ),
          );
        },
        childCount: quotes.length,
      ),
    );
  }

  void addQuotidianAction(Quote quote) async {
    final success = await addToQuotidians(
      quote: quote,
      lang: lang,
    );

    if (success) {
      showSnack(
        context: context,
        message: 'Quote successfully added.',
        type: SnackType.success,
      );
      return;
    }

    showSnack(
      context: context,
      message: 'Sorry, an error occurred while adding the quotes to quotidian.',
      type: SnackType.error,
    );
  }

  void checkAndFetch() async {
    final isUserConnected = await isAuthOk();

    if (!isUserConnected) {
      FluroRouter.router.navigateTo(context, SigninRoute);
      return;
    }

    fetch();
  }

  void deleteAction(Quote quote) async {
    int index = quotes.indexOf(quote);

    setState(() {
      quotes.removeAt(index);
    });

    final success = await deleteQuote(quote: quote);

    if (!success) {
      quotes.insert(index, quote);

      showSnack(
        context: context,
        message: "Couldn't delete the temporary quote.",
        type: SnackType.error,
      );
    }
  }

  Future fetch() async {
    setState(() {
      isLoading = true;
      quotes.clear();
    });

    try {
      final snapshot = await Firestore.instance
          .collection('quotes')
          .where('lang', isEqualTo: lang)
          .orderBy('createdAt', descending: descending)
          .limit(30)
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

        final quote = Quote.fromJSON(data);
        quotes.add(quote);
      });

      lastDoc = snapshot.documents.last;

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      debugPrint(error.toString());

      setState(() {
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
          .collection('quotes')
          .where('lang', isEqualTo: lang)
          .orderBy('createdAt', descending: descending)
          .startAfterDocument(lastDoc)
          .limit(30)
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

        final quote = Quote.fromJSON(data);
        quotes.insert(quotes.length - 1, quote);
      });

      lastDoc = snapshot.documents.last;

      setState(() {
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
    lang = appLocalStorage.getPageLang(pageRoute: QuotesRoute);
    descending = appLocalStorage.getPageOrder(pageRoute: QuotesRoute);
  }

  Future<bool> isAuthOk() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userAuth = await userState.userAuth;

      if (userAuth != null) {
        return true;
      }

      setState(() {
        isLoading = false;
      });

      return false;
    } catch (error) {
      debugPrint(error.toString());
      setState(() {
        isLoading = false;
      });

      return false;
    }
  }

  void showDeleteDialog(Quote quote) {
    showDialog(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: Text(
          'Confirm deletion?',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 40.0,
        ),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  FluroRouter.router.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(3.0),
                  ),
                ),
                color: stateColors.softBackground,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 15.0,
                  ),
                  child: Text(
                    'NO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.only(left: 15.0)),
              RaisedButton(
                onPressed: () {
                  FluroRouter.router.pop(context);
                  deleteAction(quote);
                },
                color: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(3.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 15.0,
                  ),
                  child: Text(
                    'YES',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
