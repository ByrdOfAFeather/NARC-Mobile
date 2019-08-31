import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:narc/bugReport.dart';
import 'package:narc/resultsMenu.dart';

import 'APIWrapper.dart';
import 'main.dart';
import 'narcQuiz.dart';

class CustomAlertDialog extends StatefulWidget {
  final name;
  final id;

  const CustomAlertDialog({Key key, this.name, this.id}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CustomAlertDialogState();
  }
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {
  String validationError;
  String confirmPassword;
  String password;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AlertDialog(
      title: Text("Set a password"),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "This should not be your Canvas password!",
                ),
                obscureText: true,
                validator: (value) {
                  if (value.isEmpty) {
                    return "Password can't be empty!";
                  } else if (validationError.isNotEmpty) {
                    return validationError;
                  } else {
                    password = value;
                    return null;
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                ),
                obscureText: true,
                validator: (String value) {
                  if (value.isEmpty) {
                    return "Passwords must match!";
                  } else if (validationError.isNotEmpty) {
                    return validationError;
                  } else {
                    confirmPassword = value;
                    return null;
                  }
                },
              ),
//                          Container(
//                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
              IconButton(
                icon: Icon(Icons.info_outline),
                color: Colors.green,
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Text("FERPA requires that data be de-idetinfied when disclosing it with "
                              "a third party. For this reason, a reidentificiton process has to take place "
                              "when the data is returned to you. To ensure this reidentification can only "
                              "take place by authorized users, a password must be provided to "
                              "secure the data."),
                        );
                      });
                },
              ),
              RaisedButton(
                  color: Colors.green,
                  onPressed: () {
                    validationError = "";
                    if (_formKey.currentState.validate()) {
                      validationError = password == confirmPassword ? "" : "Passwords must match!";
                      if (_formKey.currentState.validate()) {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NarcQuiz(
                                  quizID: widget.id.toString(),
                                  password: password,
                                  quizName: widget.name,
                                )));
                      }
                    }
                  },
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  )),
            ],
          ),
        )
      ]),
    );
  }
}

class CanvasMenu extends StatefulWidget {
  final Function onTapFunction;
  final Function getFunction;
  final String title;

  const CanvasMenu({Key key, this.onTapFunction, this.getFunction, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CanvasMenuState();
  }
}

class _CanvasMenuState extends State<CanvasMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: FutureBuilder(
          future: widget.getFunction(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null && snapshot.connectionState != ConnectionState.done) {
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
                      title: Text(snapshot.data[index].genericName),
                    ));
              },
            );
          },
        ));
  }
}

class MainMenu extends StatefulWidget {
  final CanvasMenu canvasMenu;
  final int startingIndex;

  MainMenu({Key key, this.canvasMenu, this.startingIndex}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MainMenuState();
  }
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  TabController _controller;

  void initState() {
    _controller = TabController(length: 3, vsync: this);
    _controller.animateTo(widget.startingIndex);
    super.initState();
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        children: <Widget>[widget.canvasMenu, BugReportScreen(), ResultsMenu()],
        controller: _controller,
      ),
      bottomNavigationBar: Material(
          color: Colors.green,
          child: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.home)),
              Tab(icon: Icon(Icons.bug_report)),
              Tab(icon: Icon(Icons.folder))
            ],
            controller: _controller,
          )),
    );
  }
}

Widget MainMenuWrapper = MainMenu(
  startingIndex: 0,
  canvasMenu: CanvasMenu(
    title: "Courses",
    onTapFunction: (id, _) {
      storage.write(key: "currentCourse", value: id.toString());
      navKey.currentState.push(CustomRoute(
          builder: (BuildContext context) => MainMenu(
            startingIndex: 0,
            canvasMenu: CanvasMenu(
              title: "Modules",
              getFunction: () {
                return getModules();
              },
              onTapFunction: (id, _) {
                storage.write(key: "moduleID", value: id.toString());
                navKey.currentState.push(CustomRoute(
                    builder: (BuildContext context) => MainMenu(
                      startingIndex: 0,
                        canvasMenu: CanvasMenu(
                            title: "Quizzes",
                            getFunction: () {
                              return getQuizzes();
                            },
                            onTapFunction: (id, name) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CustomAlertDialog(name: name, id: id);
                                },
                              );
                            }))));
              },
            ),
          )));
    },
    getFunction: () {
      return getCourses();
    },
  ),
);

Widget ResultsMenuWrapper = MainMenu(
  startingIndex: 2,
  canvasMenu: CanvasMenu(
    title: "Courses",
    onTapFunction: (id, _) {
      storage.write(key: "currentCourse", value: id.toString());
      navKey.currentState.push(CustomRoute(
          builder: (BuildContext context) => MainMenu(
            startingIndex: 0,
            canvasMenu: CanvasMenu(
              title: "Modules",
              getFunction: () {
                return getModules();
              },
              onTapFunction: (id, _) {
                storage.write(key: "moduleID", value: id.toString());
                navKey.currentState.push(CustomRoute(
                    builder: (BuildContext context) => MainMenu(
                      startingIndex: 0,
                        canvasMenu: CanvasMenu(
                            title: "Quizzes",
                            getFunction: () {
                              return getQuizzes();
                            },
                            onTapFunction: (id, name) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CustomAlertDialog(name: name, id: id);
                                },
                              );
                            }))));
              },
            ),
          )));
    },
    getFunction: () {
      return getCourses();
    },
  ),
);
