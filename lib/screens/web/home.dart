import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:memorare/components/web/discover.dart';
import 'package:memorare/components/web/footer.dart';
import 'package:memorare/components/web/full_page_quotidian.dart';
import 'package:memorare/components/web/top_bar.dart';
import 'package:memorare/components/web/topics.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';
import 'package:memorare/state/user_state.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Observer(
        builder: (context) {
          if (userState.isUserConnected) {
            return FloatingActionButton.extended(
              onPressed: () {
                FluroRouter.router.navigateTo(context, DashboardRoute);
              },
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              icon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            );
          }

          return Padding(padding: EdgeInsets.zero,);
        }
      ),
      body: ListView(
        controller: scrollController,
        children: <Widget>[
          TopBar(),
          FullPageQuotidian(),
          Topics(),
          Discover(),
          Footer(pageScrollController: scrollController,),
        ],
      ),
    );
  }
}
