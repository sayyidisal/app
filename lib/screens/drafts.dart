import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memorare/actions/drafts.dart';
import 'package:memorare/components/error_container.dart';
import 'package:memorare/components/loading_animation.dart';
import 'package:memorare/components/order_button.dart';
import 'package:memorare/components/quote_card.dart';
import 'package:memorare/components/web/empty_content.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import 'package:memorare/components/web/sliver_app_header.dart';
import 'package:memorare/data/add_quote_inputs.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';
import 'package:memorare/state/colors.dart';
import 'package:memorare/state/topics_colors.dart';
import 'package:memorare/state/user_state.dart';
import 'package:memorare/types/temp_quote.dart';
import 'package:memorare/types/topic_color.dart';
import 'package:memorare/utils/snack.dart';

class Drafts extends StatefulWidget {
  @override
  _DraftsState createState() => _DraftsState();
}

class _DraftsState extends State<Drafts> {
  bool hasNext        = true;
  bool hasErrors      = false;
  bool isLoading      = false;
  bool isLoadingMore  = false;
  String lang         = 'en';
  int limit           = 30;
  int order           = -1;
  bool descending     = true;

  List<TempQuote> drafts = [];
  List<TempQuote> offlineDrafts = [];
  ScrollController scrollController = ScrollController();

  var lastDoc;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body()
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
          if (scrollNotif.metrics.pixels < scrollNotif.metrics.maxScrollExtent) {
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
            SliverAppHeader(
              title: 'Drafts',
              rightButton: OrderButton(
                descending: descending,
                onOrderChanged: (order) {
                  setState(() {
                    descending = order;
                  });

                  fetch();
                },
              ),
            ),
            bodyListContent(),
          ],
        ),
      )
    );
  }

  Widget bodyListContent() {
    if (isLoading) {
      return SliverList(
        delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.only(top: 150.0),
              child:  LoadingAnimation(),
            ),
          ]
        ),
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

    if (drafts.length == 0) {
      return SliverList(
        delegate: SliverChildListDelegate([
            FadeInY(
              delay: 2.0,
              beginY: 50.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: EmptyContent(
                  icon: Opacity(
                    opacity: .8,
                    child: Icon(
                      Icons.edit,
                      size: 60.0,
                      color: Color(0xFFFF005C),
                    ),
                  ),
                  title: 'No drafts',
                  subtitle: 'You can save them when you are not ready to propose your quotes.',
                  onRefresh: () => fetch(),
                ),
              ),
            ),
          ]
        ),
      );
    }

    if (MediaQuery.of(context).size.width > 600.0) {
      return SliverPadding(
        padding: const EdgeInsets.all(20.0),
        sliver: gridQuotes(),
      );
    }

    return listQuotes();
  }

  Widget listQuotes() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final draft = drafts.elementAt(index);

          TopicColor topicColor = appTopicsColors.topicsColors.first;

          if (draft.topics.length > 0) {
            topicColor = appTopicsColors.find(draft.topics.first);
          }

          return InkWell(
            onTap: () => editDraft(draft),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(padding: const EdgeInsets.only(top: 20.0),),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: <Widget>[
                      if (draft.isOffline)
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: ClipOval(
                            child: Material(
                              color: Colors.red,
                              child: InkWell(
                                splashColor: Colors.orange,
                                child: SizedBox(width: 24, height: 24,),
                                onTap: () => showOfflineHelper(),
                              ),
                            ),
                          ),
                        ),

                      Expanded(
                        child: Text(
                          draft.name,
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Center(
                  child: quotePopupMenuButton(
                    draft: draft,
                    index: index,
                    color: Color(topicColor.decimal),
                  ),
                ),

                Padding(padding: const EdgeInsets.only(top: 10.0),),
                Divider(),
              ],
            ),
          );
        },
        childCount: drafts.length,
      ),
    );
  }

  Widget gridQuotes() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300.0,
        crossAxisSpacing: 20.0,
        mainAxisSpacing: 20.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final draft = drafts.elementAt(index);

          TopicColor topicColor = appTopicsColors.topicsColors.first;

          if (draft.topics.length > 0) {
            topicColor = appTopicsColors.find(draft.topics.first);
          }

          return QuoteCard(
            onTap: () => editDraft(draft),
            title: draft.name,
            popupMenuButton: quotePopupMenuButton(
              draft: draft,
              index: index,
              color: Color(topicColor.decimal),
            ),
          );
        },
        childCount: drafts.length,
      ),
    );
  }

  Widget moreButton({int index, TempQuote draft}) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'delete') {
          deleteAction(draft: draft, index: index);
          return;
        }

        if (value == 'edit') {
          editDraft(draft);
          return;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text(
              'Edit',
              style: TextStyle(
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future fetch() async {
    setState(() {
      isLoading = true;
      drafts.clear();
    });

    try {
      fetchOffline();

      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        throw Error();
      }

      final snapColl = await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('drafts')
        .orderBy('createdAt', descending: descending)
        .limit(limit)
        .getDocuments();

      if (snapColl.documents.isEmpty) {
        setState(() {
          hasNext = false;
          isLoading = false;
        });

        return;
      }

      snapColl.documents.forEach((doc) {
        final data = doc.data;
        data['id'] = doc.documentID;

        final draft = TempQuote.fromJSON(data);
        drafts.add(draft);
      });

      lastDoc = snapColl.documents.last;

      setState(() {
        isLoading = false;
        hasErrors = false;
        hasNext = snapColl.documents.length == limit;
      });

    } catch (error) {
      debugPrint(error.toString());
      hasErrors = true;
    }
  }

  Future fetchMore() async {
    if (lastDoc == null) { return; }

    setState(() {
      isLoadingMore = true;
    });

    try {
      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        throw Error();
      }

      final snapColl = await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('drafts')
        .startAfterDocument(lastDoc)
        .orderBy('createdAt', descending: descending)
        .limit(limit)
        .getDocuments();

      if (snapColl.documents.isEmpty) {
        setState(() {
          hasNext = false;
          isLoading = false;
        });

        return;
      }

      snapColl.documents.forEach((doc) {
        final data = doc.data;
        data['id'] = doc.documentID;

        final draft = TempQuote.fromJSON(data);
        drafts.add(draft);
      });

      lastDoc = snapColl.documents.last;

      setState(() {
        isLoading = false;
        hasErrors = false;
        hasNext = snapColl.documents.length == limit;
      });

    } catch (error) {
      debugPrint(error.toString());
      hasErrors = true;
    }
  }

  void fetchOffline() {
    final savedDrafts = getOfflineDrafts();
    drafts.addAll(savedDrafts);
  }

  void deleteAction({TempQuote draft, int index}) async {
    setState(() {
      drafts.removeAt(index);
    });

    bool success = false;

    if (draft.isOffline) {
      success = deleteOfflineDraft(createdAt: draft.createdAt.toString());
    }
    else {
      success = await deleteDraft(
        context: context,
        draft: draft,
      );
    }

    if (!success) {
      drafts.insert(index, draft);

      showSnack(
        context: context,
        message: "Couldn't delete the temporary quote.",
        type: SnackType.error,
      );
    }
  }

  Widget quotePopupMenuButton({
    TempQuote draft,
    int index,
    Color color,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: color,
      ),
      onSelected: (value) {
        if (value == 'edit') {
          editDraft(draft);
          return;
        }

        if (value == 'delete') {
          showDeleteDialog(draft: draft, index: index,);
          return;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
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

  void editDraft(TempQuote draft) async {
    AddQuoteInputs.isOfflineDraft = draft.isOffline;
    AddQuoteInputs.draft = draft;
    AddQuoteInputs.populateWithTempQuote(draft);

    await FluroRouter.router.navigateTo(context, AddQuoteContentRoute);

    fetch();
  }

  void showDeleteDialog({TempQuote draft, int index}) {
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
                  deleteAction(draft: draft, index: index);
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

  void showOfflineHelper() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          content: Container(
            child: Text(
              "This quote is saved in your device's offline storage. You can save it in the cloud after an edit. It can prevent data loss."
            ),
          ),
        );
      }
    );
  }
}
