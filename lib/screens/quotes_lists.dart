import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:memorare/actions/lists.dart';
import 'package:memorare/components/error_container.dart';
import 'package:memorare/components/order_button.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import'package:memorare/components/loading_animation.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';
import 'package:memorare/state/colors.dart';
import 'package:memorare/state/user_state.dart';
import 'package:memorare/types/user_quotes_list.dart';
import 'package:memorare/utils/snack.dart';

class QuotesLists extends StatefulWidget {
  @override
  _QuotesListsState createState() => _QuotesListsState();
}

class _QuotesListsState extends State<QuotesLists> {
  bool descending     = true;
  bool hasErrors      = false;
  bool hasNext        = true;
  bool isLoading      = false;
  bool isLoadingMore  = false;
  int limit           = 10;

  final scrollController = ScrollController();

  List<UserQuotesList> userQuotesLists = [];

  var lastDoc;

  String newName            = '';
  String newDescription     = '';
  String newIconUrl         = '';
  bool newIsPublic          = false;

  String updateName         = '';
  String updateDescription  = '';
  bool updateIsPublic       = false;

  String oldName            = '';
  String oldDescription     = '';
  bool oldIsPublic          = false;

  @override
  initState() {
    super.initState();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body(),
      floatingActionButton: Observer(
        builder: (_) {
          return FloatingActionButton(
            onPressed: () => showCreateListDialog(),
            child: Icon(Icons.add),
            backgroundColor: stateColors.primary,
            foregroundColor: Colors.white,
          );
        },
      ),
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
            appBar(),
            bodyListContent(),
          ],
        ),
      )
    );
  }

  Widget appBar() {
    return Observer(
      builder: (_) {
        return SliverAppBar(
          floating: true,
          snap: true,
          expandedHeight: 120.0,
          backgroundColor: stateColors.softBackground,
          automaticallyImplyLeading: false,
          flexibleSpace: Stack(
            children: <Widget>[
              FadeInY(
                delay: 1.0,
                beginY: 50.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: FlatButton(
                    onPressed: () {
                      if (userQuotesLists.length == 0) { return; }

                      scrollController.animateTo(
                        0,
                        duration: Duration(seconds: 2),
                        curve: Curves.easeOutQuint
                      );
                    },
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 60.0,
                      child: Text(
                        'Lists',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 25.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 20.0,
                top: 50.0,
                child: OrderButton(
                  ascendingText: 'First updated',
                  descending: descending,
                  descendingText: 'Last updated',
                  onOrderChanged: (newDescending) {
                    descending = newDescending;
                    fetch();
                  },
                ),
              ),

              Positioned(
                left: 20.0,
                top: 50.0,
                child: IconButton(
                  onPressed: () {
                    FluroRouter.router.pop(context);
                  },
                  tooltip: 'Back',
                  icon: Icon(Icons.arrow_back),
                ),
              ),
            ],
          ),
        );
      },
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

    if (userQuotesLists.length == 0) {
      return SliverList(
        delegate: SliverChildListDelegate([
            FadeInY(
              delay: 2.0,
              beginY: 50.0,
              child:
              Container(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: <Widget>[
                    Opacity(
                      opacity: .8,
                      child: Icon(
                        Icons.format_list_bulleted,
                        size: 120.0,
                        color: Color(0xFFFF005C),
                      ),
                    ),

                    Opacity(
                      opacity: .8,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: Text(
                          "You've created no list yet",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25.0,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
                      child: Opacity(
                        opacity: .6,
                        child: Text(
                          "You can create one by taping on the '+' button" ,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        showCreateListDialog();
                      },
                      icon: Icon(Icons.add,),
                    )
                  ],
                ),
              ),
            ),
          ]
        ),
      );
    }

    return sliverQuotesList();
  }

  Widget cardItem({Widget iconImg, UserQuotesList quoteList}) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 500.0,
            height: 120.0,
            child: Card(
              child: InkWell(
                onTap: () async {
                  final mustRefresh = await FluroRouter.router.navigateTo(
                    context,
                    ListRoute.replaceFirst(':id', quoteList.id),
                  );

                  if (mustRefresh == null) { return; }

                  if (mustRefresh) {
                    fetch();
                  }
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
                              showDeleteListDialog(quoteList);
                              return;
                            }

                            if (value == 'edit') {
                              showEditListDialog(quoteList);
                              return;
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                              ),
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

  Widget sliverQuotesList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
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

  void showCreateListDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, childSetState) {
            return SimpleDialog(
              title: Text(
                'Create a new list'
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10.0,
                  ),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: stateColors.primary),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: stateColors.primary,
                          width: 2.0
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      newName = newValue;
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10.0,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: stateColors.primary),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: stateColors.primary,
                          width: 2.0
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      newDescription = newValue;
                    },
                    onSubmitted: (_) {
                      create();
                      Navigator.of(context).pop();
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: newIsPublic,
                        onChanged: (newValue) {
                          childSetState(() {
                            newIsPublic = newValue;
                          });
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Opacity(
                          opacity: .6,
                          child: Text(
                            'Is public?'
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 15.0,),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10.0,
                  ),
                  child: Row(
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

                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                      ),

                      RaisedButton(
                        color: stateColors.primary,
                        onPressed: () {
                          create();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Create',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void showDeleteListDialog(UserQuotesList quotesList) {
    final name = quotesList.name;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete $name list?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Opacity(
                  opacity: 0.6,
                  child: Text(
                    'This action is irreversible.',
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  'Cancel',
                ),
              ),
            ),
            RaisedButton(
              color: Colors.red,
              onPressed: () {
                deleteList(quotesList);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  void showEditListDialog(UserQuotesList quotesList) {
    updateName = quotesList.name;
    updateDescription = quotesList.description;
    updateIsPublic = quotesList.isPublic;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, childSetState) {
            return SimpleDialog(
              title: Text(
                'Edit $updateName',
                overflow: TextOverflow.ellipsis,
              ),
              // contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10.0,
                  ),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: stateColors.primary),
                      hintText: updateName,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: stateColors.primary,
                          width: 2.0
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      updateName = newValue;
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10.0,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: stateColors.primary),
                      hintText: updateDescription,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: stateColors.primary,
                          width: 2.0
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      updateDescription = newValue;
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: updateIsPublic,
                        onChanged: (newValue) {
                          childSetState(() {
                            updateIsPublic = newValue;
                          });
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Opacity(
                          opacity: .6,
                          child: Text(
                            'Is public?'
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 15.0,),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FlatButton(
                        onPressed: () {
                          updateName = '';
                          updateDescription = '';
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                      ),

                      RaisedButton(
                        color: stateColors.primary,
                        onPressed: () {
                          updateList(quotesList);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Update',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // --------------------------
  // ^
  // |_ Silent widget functions
  // --------------------------

  void create() async {
    final quotesList = await createList(
      context: context,
      name: newName,
      description: newDescription,
      iconUrl: newIconUrl,
      isPublic: newIsPublic,
    );

    if (quotesList == null) {
      showSnack(
        context: context,
        message: 'There was and issue while creating the list. Try again later',
        type: SnackType.error,
      );

      return;
    }

    setState(() {
      userQuotesLists.add(quotesList);
    });
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

  Future fetch() async {
    setState(() {
      isLoading = true;
    });

    try {
      userQuotesLists.clear();

      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        FluroRouter.router.navigateTo(context, SigninRoute);
        return;
      }

      final snapshot = await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('lists')
        .orderBy('updatedAt', descending: descending)
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

  void fetchMore() async {
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
        .orderBy('updatedAt', descending: descending)
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

  void updateList(UserQuotesList quotesList) async {
    oldDescription = quotesList.description;
    oldName = quotesList.name;
    oldIsPublic = quotesList.isPublic;

    setState(() { // optimistic
      quotesList.description = updateDescription;
      quotesList.name = updateName;
      quotesList.isPublic = updateIsPublic;
    });

    try {
      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        FluroRouter.router.navigateTo(context, SigninRoute);
        return;
      }

      await Firestore.instance
        .collection('users')
        .document(userAuth.uid)
        .collection('lists')
        .document(quotesList.id)
        .updateData({
          'description' : updateDescription,
          'name'        : updateName,
          'isPublic'    : updateIsPublic,
          'updatedAt'   : DateTime.now(),
        });

      setState(() {});

    } catch (error) {
      debugPrint(error.toString());

      setState(() { // rollback
        quotesList.description = oldDescription;
        quotesList.name = oldName;
        quotesList.isPublic = oldIsPublic;
      });

      showSnack(
        context: context,
        message: 'There was and issue while updating the list. Try again later',
        type: SnackType.error,
      );
    }
  }
}
