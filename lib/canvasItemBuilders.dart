// Generic builder for items from Canvas (Courses, Modules, Quizzes)
import 'package:flutter/material.dart';
import 'package:narc/resultsMenu.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bugReport.dart';

// Generic builder for items from Canvas (Courses, Modules, Quizzes)
class MainMenuBuilder extends StatefulWidget {
  final String title;
  final dynamic getFunction;
  final dynamic onTapFunction;
  final int initGlobalNavigationIndex;

  MainMenuBuilder({Key key, this.title, this.getFunction, this.onTapFunction, this.initGlobalNavigationIndex}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MainMenuBuilderState();
  }
}


class StatelessSettingsMenu extends StatefulWidget {
  State<StatefulWidget> createState() {
    return _StatelessSettingsMenu();
  }
}

class _StatelessSettingsMenu extends State<StatelessSettingsMenu> {
  bool _canSaveSetting = false;

  _launchPrivacyPolicy() async {
    const url = "https://www.byrdof.dev/privacy_policy";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch';
    }
  }


  // TODO: Implementation
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text("Settings"),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                child: Row(children: <Widget>[
                  Text("Allow NARC to save data?"),
                  Checkbox(
                    value: _canSaveSetting,
                    onChanged: (newVal) {
                      setState(() {
                        _canSaveSetting = newVal;
                      });
                    },
                  )
                ]),
              ),
              FlatButton(
                child: Text("View Privacy Policy"),
                onPressed: _launchPrivacyPolicy,
              )
            ],
          ),
        ));
  }
}


class _MainMenuBuilderState extends State<MainMenuBuilder> {
  var navigatorListBody = new List(3);
  var navigatorListAppBar = new List(3);
  bool assignedDef = false;
  int globalNavigationIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!assignedDef) {
      globalNavigationIndex = widget.initGlobalNavigationIndex;
      assignedDef = !assignedDef;
    }
    navigatorListBody[0] = FutureBuilder(
      future: widget.getFunction(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return new Center(child: new CircularProgressIndicator());
        } else if (snapshot.data.length == 0) {
          return Container(child: Center(child: Text("No items found!")));
        }
        return ListView.builder(
          itemCount: snapshot.data.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
                child: ListTile(
                  onTap: () {
                    widget.onTapFunction(snapshot.data[index].genericID, snapshot.data[index].genericName);
                  },
                  onLongPress: () {
                    // do nothing
                  },
                  title: Text(snapshot.data[index].genericName),
                ));
          },
        );
      },
    );


    navigatorListAppBar[0] = AppBar(
      title: Text(widget.title),
      centerTitle: true,
      actions: <Widget>[
        PopupMenuButton(
          itemBuilder: (BuildContext context) {
            return [
              // TODO: Come back and fix form updates
              PopupMenuItem<String>(
                  value: "Settings",
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context, "Settings");
                      showDialog(
                          context: context,
                          builder: (context) => StatelessSettingsMenu());
                    },
                    child: Center(child: Text("Settings")),
                  ))
            ];
          },
        )
      ],
    );

    navigatorListBody[1] = BugReportScreen();
    navigatorListAppBar[1] = null;

    navigatorListAppBar[2] = null;
    navigatorListBody[2] = ResultsMenu();

    // TODO: When a new item is added, there is no way to refresh without exiting the app and logging back in
    return Scaffold(
      appBar: navigatorListAppBar[globalNavigationIndex],
      body: navigatorListBody[globalNavigationIndex],
      bottomNavigationBar: BottomAppBar(
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.home),
                disabledColor: Colors.green,
                onPressed: globalNavigationIndex == 0
                    ? null
                    : () => setState(() {
                  globalNavigationIndex = 0;
                }),
              ),
              IconButton(
                  icon: Icon(Icons.bug_report),
                  disabledColor: Colors.green,
                  onPressed: globalNavigationIndex == 1
                      ? null
                      : () => setState(
                        () {
                      globalNavigationIndex = 1;
                    },
                  )),
              IconButton(
                  icon: Icon(Icons.folder),
                  disabledColor: Colors.green,
                  onPressed: globalNavigationIndex == 2
                      ? null
                      : () => setState(() {
                    globalNavigationIndex = 2;
                  })),
            ],
          )),
    );
  }
}