import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memorare/components/web/empty_content.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import'package:memorare/components/loading_animation.dart';
import 'package:memorare/components/web/sliver_app_header.dart';
import 'package:memorare/state/colors.dart';
import 'package:memorare/state/user_state.dart';
import 'package:memorare/types/user_quotes_list.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';
import 'package:memorare/utils/snack.dart';

class QuotesLists extends StatefulWidget {
  @override
  _QuotesListsState createState() => _QuotesListsState();
}

class _QuotesListsState extends State<QuotesLists> {
  bool isLoading      = false;
  bool isLoadingMore  = false;
  bool hasNext        = true;
  int limit           = 10;

  final scrollController = ScrollController();
  bool isFabVisible = false;

  List<UserQuotesList> userQuotesLists = [];

  var lastDoc;

  String newListName        = '';
  String newListDescription = '';
  String newListIconUrl     = '';
  bool newListIsPublic      = false;

  @override
  initState() {
    super.initState();
    fetchLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isFabVisible ?
        FloatingActionButton(
          onPressed: () {
            scrollController.animateTo(
              0.0,
              duration: Duration(seconds: 1),
              curve: Curves.easeOut,
            );
          },
          child: Icon(Icons.arrow_upward),
        ) : null,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: body(),
      ),
    );
  }

  Widget body() {
    return NotificationListener(
      onNotification: (ScrollNotification scrollNotif) {
        // FAB visibility
        if (scrollNotif.metrics.pixels < 50 && isFabVisible) {
          setState(() {
            isFabVisible = false;
          });
        } else if (scrollNotif.metrics.pixels > 50 && !isFabVisible) {
          setState(() {
            isFabVisible = true;
          });
        }

        // Load more scenario
        if (scrollNotif.metrics.pixels < scrollNotif.metrics.maxScrollExtent - 100.0) {
          return false;
        }

        if (hasNext && !isLoadingMore) {
          fetchMoreLists();
        }

        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          SliverAppHeader(
            title: 'Lists',
            bottomButton: IconButton(
              icon: Icon(Icons.add),
              tooltip: 'Create a new list',
              onPressed: () => showCreateListDialog(),
            ),
          ),

          listContent(),
        ],
      ),
    );
  }

  Widget listContent() {
    if (isLoading) {
      return SliverList(
        delegate: SliverChildListDelegate([
            LoadingAnimation(
              textTitle: 'Loading lists...',
            ),
          ]
        ),
      );
    }

    if (userQuotesLists.length == 0) {
      return SliverList(
        delegate: SliverChildListDelegate([
            FadeInY(
              delay: 2.0,
              beginY: 50.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: EmptyContent(
                  icon: Opacity(
                    opacity: .8,
                    child: Icon(
                      Icons.list,
                      size: 60.0,
                      color: Color(0xFFFF005C),
                    ),
                  ),
                  title: "You've no quotes list at this moment",
                  subtitle: 'You can create one.',
                ),
              ),
            ),
          ]
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final quoteList = userQuotesLists.elementAt(index);

          final iconImg = quoteList.iconUrl.isNotEmpty ?
            Image.network(quoteList.iconUrl, width: 40.0, height: 40.0,) :
            Image.asset('assets/images/layers-${stateColors.iconExt}.png', width: 40.0, height: 40.0,);

          return FadeInY(
            delay: 2.0 + index.toDouble() * 0.1,
            beginY: 50.0,
            child: cardItem(
              iconImg: iconImg,
              quoteList: quoteList,
            ),
          );
        },
        childCount: userQuotesLists.length,
      ),
    );
  }

  Widget cardItem({Widget iconImg, UserQuotesList quoteList}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 500.0,
            height: 120.0,
            child: Card(
              child: InkWell(
                onTap: () {
                  FluroRouter.router.navigateTo(
                    context,
                    ListRoute.replaceFirst(':id', quoteList.id),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Stack(
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          iconImg,

                          Padding(
                            padding: const EdgeInsets.only(left: 40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  quoteList.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ),
                                ),
                                Opacity(
                                  opacity: .6,
                                  child: Text(
                                    quoteList.description,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Positioned(
                        right: 0.0,
                        top: 15.0,
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              deleteList(quoteList);
                              return;
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void deleteList(UserQuotesList quoteList) async {
    int index = userQuotesLists.indexOf(quoteList);

    setState(() {
      userQuotesLists.removeAt(index);
    });

    try {
      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        FluroRouter.router.navigateTo(context, SigninRoute);
        return;
      }

      // Add a new document containing information
      // to delete the subcollection (in order to delete its documents).
      await Firestore.instance
        .collection('todelete')
        .add({
          'objectId': quoteList.id,
          'path': 'users/<userId>/lists/<listId>/quotes',
          'userId': userAuth.uid,
          'target': 'list',
          'type': 'subcollection',
        });

      // Delete the quote collection doc.
      await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('lists')
        .document(quoteList.id)
        .delete();

    } catch (error) {
      setState(() {
        userQuotesLists.insert(index, quoteList);
      });

      debugPrint(error);

      showSnack(
        context: context,
        message: 'There was and issue while deleting the list. Try again later',
        type: SnackType.error,
      );
    }
  }

  void showCreateListDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(
            'Create a new list'
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
          children: <Widget>[
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Name',
                // labelStyle: TextStyle(color: Colors.),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    // color: accent,
                    width: 2.0
                  ),
                ),
              ),
              onChanged: (newValue) {
                newListName = newValue;
              },
            ),

            Padding(padding: EdgeInsets.only(top: 10.0),),

            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                // labelStyle: TextStyle(color: accent),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    // color: accent,
                    width: 2.0
                  ),
                ),
              ),
              onChanged: (newValue) {
                newListDescription = newValue;
              },
              onSubmitted: (_) {
                createList();
                Navigator.of(context).pop();
              },
            ),
            Padding(padding: EdgeInsets.only(top: 20.0),),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                  ),
                ),

                RaisedButton(
                  color: Colors.green,
                  onPressed: () {
                    createList();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ],
        );
      }
    );
  }

  void createList() async {
    try {
      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        FluroRouter.router.navigateTo(context, SigninRoute);
        return;
      }

      final docRef = await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('lists')
        .add({
          'createdAt'   : DateTime.now(),
          'description' : newListDescription,
          'name'        : newListName,
          'iconUrl'     : newListIconUrl,
          'isPublic'    : newListIsPublic,
          'updatedAt'   : DateTime.now(),
        });

      final doc = await docRef.get();

      final data = doc.data;
      data['id'] = doc.documentID;

      final quoteList = UserQuotesList.fromJSON(data);

      setState(() {
        userQuotesLists.add(quoteList);
      });

    } catch (error) {
      debugPrint(error.toString());

      showSnack(
        context: context,
        message: 'There was and issue while creating the list. Try again later',
        type: SnackType.error,
      );
    }
  }

  void fetchLists() async {
    setState(() {
      isLoading = true;
    });

    try {
      userQuotesLists.clear();

      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        setState(() {
          isLoading = false;
        });

        FluroRouter.router.navigateTo(context, SigninRoute);
        return;
      }

      final snapshot = await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('lists')
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

        final quoteList = UserQuotesList.fromJSON(data);
        userQuotesLists.add(quoteList);
      });

      lastDoc = snapshot.documents.last;

      setState(() {
        hasNext = snapshot.documents.length == limit;
        isLoading = false;
      });

    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  void fetchMoreLists() async {
    setState(() {
      isLoadingMore = true;
    });

    try {
      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        FluroRouter.router.navigateTo(context, SigninRoute);
        return;
      }

      final snapshot = await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('lists')
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

        final quoteList = UserQuotesList.fromJSON(data);
        userQuotesLists.add(quoteList);
      });

      lastDoc = snapshot.documents.last;

      setState(() {
        hasNext = snapshot.documents.length == limit;
        isLoadingMore = false;
      });

    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        isLoadingMore = false;
      });
    }
  }
}
