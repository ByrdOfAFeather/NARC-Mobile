import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sqlcipher/sqlite.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:narc/APIWrapper.dart';
import 'package:narc/bugReport.dart';

import 'loginScreen.dart';
import 'narcCourses.dart';
import 'narcQuiz.dart';
import 'narcResults.dart';

FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
String _firebaseToken;
int globalNavigationIndex = 0;

saveResultsAndPushResultsScreen(message, navKey) async {
  final cryptor = new PlatformStringCryptor();
  String screen = message["data"]["screen"];
  dynamic results = jsonDecode(message["data"]["results"]);
  String name = results["for"];
  String quizPass = await storage.read(key: "token");
  String salt = await storage.read(key: "encryptionSalt");
  String key = await cryptor.generateKeyFromPassword(quizPass, salt);
  name = await cryptor.decrypt(name, key);


  navKey.currentState.pushReplacementNamed(screen, arguments: NarcResultsArguments(results: results, quizName: name));
}

Future<void> firebaseCloudMessagingListeners(navKey) async {
  _firebaseToken = await _firebaseMessaging.getToken();
  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
      // TODO: Make local notifications
      await saveResultsAndPushResultsScreen(message, navKey);
    },
    onResume: (Map<String, dynamic> message) async {
      await saveResultsAndPushResultsScreen(message, navKey);
    },
    onLaunch: (Map<String, dynamic> message) async {
      await saveResultsAndPushResultsScreen(message, navKey);
    },
  );
  _firebaseMessaging
      .requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
}

void main() async {
  SQLiteDatabase db = await getOrCreateDatabase("storage");
  try {
    db.execSQL("""CREATE TABLE savedresults (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quiz_name TEXT NOT NULL
    )""");
  } on SQLiteException {
    // Note: This does not actually catch, the library (flutter_sqlcipher) doesn't bubble up platform exceptions is
    // appears, so I'm left with a fake exception catch.
    // Do nothing the table is already created.
  }

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final navKey = GlobalKey<NavigatorState>();

    await firebaseCloudMessagingListeners(navKey);
    generateSalt() async {
      final cryptor = new PlatformStringCryptor();
      final String encryptionSalt = await cryptor.generateSalt();
      storage.write(key: "encryptionSalt", value: encryptionSalt);
    }
    generateSalt();

    // TODO: Test Token
    String tester = await storage.read(key: "token");
    if (tester != null) {
      runApp(MaterialApp(
          navigatorKey: navKey,
          title: 'NARC',
          theme: ThemeData(
            cursorColor: Colors.black,
            primarySwatch: Colors.green,
          ),
          routes: {
            "/results": (context) => NarcResultsGetPassword(),
            "/courses": (context) => NarcCourses()
          },
          home: NarcCourses()));
    }
    else {
      runApp(MaterialApp(
          navigatorKey: navKey,
          title: 'NARC',
          theme: ThemeData(
            cursorColor: Colors.black,
            primarySwatch: Colors.green,
          ),
          routes: {
            "/results": (context) => NarcResultsGetPassword(),
            "/courses": (context) => NarcCourses()
          },
          home: NarcMain(title: "NARC", navKey: navKey, firebaseToken: _firebaseToken,)));
    }
  }

// So Here's what I'm thinking in terms of saving data
// if the user is already logging in, they have an account
// I only need to ask registering users and then have a settings
// menu

class StorageSingleton {
  static FlutterSecureStorage storage;

  static FlutterSecureStorage getStorage() {
    if (storage == null) {
      storage = new FlutterSecureStorage();
    }
    return storage;
  }
}


class CanvasItemsBuilder extends StatefulWidget {
  final String title;
  final dynamic getFunction;
  final dynamic onTapFunction;

  const CanvasItemsBuilder({Key key, this.title, this.getFunction, this.onTapFunction}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _CanvasItemsBuilderState();
  }
}

class _CanvasItemsBuilderState extends State<CanvasItemsBuilder> {
  var navigatorListBody = new List(2);
  var navigatorListAppBar = new List(2);


  @override
  Widget build(BuildContext context) {
    navigatorListBody[0] = FutureBuilder(
      future: widget.getFunction(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.data.length == 0) {
          return Container(child: Center(child: Text("No items found!")));
        }
        return
          ListView.builder(
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
    );

    navigatorListBody[1] = BugReportScreen();
    navigatorListAppBar[1] = null;

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
                onPressed: globalNavigationIndex == 0 ? null : () => setState((){ globalNavigationIndex = 0;}),
              ),
              IconButton(
                icon: Icon(Icons.bug_report),
                disabledColor: Colors.green,
                onPressed: globalNavigationIndex == 1 ? null : () => setState((){ globalNavigationIndex = 1;},
              )),
              IconButton(
                icon: Icon(Icons.folder),
                disabledColor: Colors.green,
                onPressed: globalNavigationIndex == 2 ? null : () => { /* TODO: results implementation */ }),
            ],
          )
      ),
    );
  }

}

class NarcModules extends StatefulWidget {
  final String title;
  final int id;

  NarcModules({Key key, this.title, this.id}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NarcModuleState();
  }
}

class _NarcModuleState extends State<NarcModules> {

  @override
  Widget build(BuildContext context) {
    return CanvasItemsBuilder(title: "Modules", getFunction: () {
      return getModules(widget.id.toString());
    }, onTapFunction: (moduleID, _) {
      storage.write(key: "currentModule", value: moduleID.toString());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NarcQuizzes(title: "Quizzes", moduleID: moduleID.toString())),
      );
    }, );
  }
}

class NarcQuizzes extends StatefulWidget {
  final String title;
  final String moduleID;

  NarcQuizzes({Key key, this.title, this.moduleID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NarcQuizzesState();
  }
}

class _NarcQuizzesState extends State<NarcQuizzes> {
  String password;
  String confirmPassword;
  String validationError = "";
  static final _formKey = GlobalKey<FormState>();

  void navigationFunction(int index) {
    setState(() {
      globalNavigationIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CanvasItemsBuilder(title:"Quizzes", getFunction: () {
      return getQuizzes(widget.moduleID);
    }, onTapFunction: (id, name) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
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
                      Container(
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                            RaisedButton(
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
                                                quizID: id.toString(),
                                                password: password,
                                                quizName: name,
                                              )));
                                    }
                                  }
                                },
                                child: Text("Submit")),
                            RaisedButton(
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
                              child: Text("Why?"),
                            ),
                          ]))
                    ],
                  ),
                )
              ]),
            );
          });
    });
  }
}
