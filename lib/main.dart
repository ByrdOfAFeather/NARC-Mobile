// Standard Library
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// External Imports
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sqlcipher/sqlite.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';

// App imports
import 'package:narc/APIWrapper.dart';
import 'package:narc/bugReport.dart';
import 'package:narc/resultsMenu.dart';
import 'canvasItemBuilders.dart';
import 'package:narc/resultsMenu.dart';
import 'package:url_launcher/url_launcher.dart';

import 'loginScreen.dart';
import 'narcCourses.dart';
import 'narcQuiz.dart';
import 'narcResults.dart';

// TODO: ERROR WHEN LOGGING BACK IN FROM THE SAME DEVICE

// Firebase global values
FirebaseMessaging _firebaseMessaging = FirebaseMessaging(); // Firebase messaging controller
String _firebaseToken; // Token to be passed to the website later to register this device

// This is called whenever a notification is received
saveResultsAndPushResultsScreen(message, navKey) async {
  final cryptor = new PlatformStringCryptor(); // Get a object for decryption
  String screen = message["data"]["screen"]; // Get the string from the notification
  dynamic results = jsonDecode(message["data"]["results"]); // Decode the notification's data
  String name = results["for"]; // Get the quiz's name from the data

  // Decrypt the quiz name
  String quizPass = await storage.read(key: "token");
  String salt = await storage.read(key: "encryptionSalt");
  String key = await cryptor.generateKeyFromPassword(quizPass, salt);
  name = await cryptor.decrypt(name, key);

  // TODO: save the data for later viewing
  SQLiteDatabase db = await getOrCreateDatabase("storage");
  db.insert(
      table: "savedresults", values: <String, String>{"quizName": "$name", "results": message["data"]["results"]});

  // TODO: Remove (?)
  // Push the results screen based on the data
  //  navKey.currentState.pushReplacementNamed(screen, arguments: NarcResultsArguments(results: results, quizName: name));
}

// This function sets up cloud base to follow instructions based on the type of notification received and the app state
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
  SQLiteDatabase db = await getOrCreateDatabase("storage"); // Main database for storing results

  db.execSQL("""CREATE TABLE IF NOT EXISTS savedresults (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quizName TEXT NOT NULL,
  results TEXT NOT NULL 
  )"""); // If the table for results doesn't exist, create it

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); // Force phone in portrait mode
  final navKey = GlobalKey<NavigatorState>(); // Get a navigator key for setting up firebase navigations
  await firebaseCloudMessagingListeners(navKey); // Wait for firebase to be setup

  generateSalt() async {
    // If the salt already exists don't generate a new one (so that results created in a different session can
    // still be accessed
    if (await storage.read(key: "encryptionSalt") != null) {
      return;
    } else {
      final cryptor = new PlatformStringCryptor();
      final String encryptionSalt = await cryptor.generateSalt();
      storage.write(key: "encryptionSalt", value: encryptionSalt);
    }
  }

  generateSalt(); // Setup the salt for the program

  // TODO: Test Token
  String tester = await storage.read(key: "token"); // If user token to the website doesn't exists, send to login
  if (tester != null) {
    runApp(MaterialApp(
        navigatorKey: navKey,
        title: 'NARC',
        theme: ThemeData(
          cursorColor: Colors.black,
          primarySwatch: Colors.green,
        ),
        routes: {"/results": (context) => NarcResultsGetPassword(), "/courses": (context) => NarcCourses()},
        home: NarcCourses()));
  } else {
    runApp(MaterialApp(
        navigatorKey: navKey,
        title: 'NARC',
        theme: ThemeData(
          cursorColor: Colors.black,
          primarySwatch: Colors.green,
        ),
        routes: {"/results": (context) => NarcResultsGetPassword(), "/courses": (context) => NarcCourses()},
        home: NarcLogin(
          title: "NARC",
          navKey: navKey,
          firebaseToken: _firebaseToken,
        )));
  }
}

class StorageSingleton {
  static FlutterSecureStorage storage;

  static FlutterSecureStorage getStorage() {
    if (storage == null) {
      storage = new FlutterSecureStorage();
    }
    return storage;
  }
}

// Route to remove animations to make Course -> Modules -> Quizzes feel a bit more natural
// (The constant moving of the bottom nav bar looks incredibly unnatural otherwise.
class CustomRoute<T> extends MaterialPageRoute<T> {
  CustomRoute({WidgetBuilder builder, RouteSettings settings}) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

// Generic builder for items from Canvas (Courses, Modules, Quizzes)
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


class _CanvasItemsBuilderState extends State<CanvasItemsBuilder> {
  var navigatorListBody = new List(3);
  var navigatorListAppBar = new List(3);
  int globalNavigationIndex = 0;

  @override
  Widget build(BuildContext context) {
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
    return CanvasItemsBuilder(
      title: "Modules",
      getFunction: () {
        return getModules(widget.id.toString());
      },
      onTapFunction: (moduleID, _) {
        storage.write(key: "currentModule", value: moduleID.toString());
        Navigator.push(
          context,
          CustomRoute(builder: (context) => NarcQuizzes(title: "Quizzes", moduleID: moduleID.toString())),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return CanvasItemsBuilder(
        title: "Quizzes",
        getFunction: () {
          return getQuizzes(widget.moduleID);
        },
        onTapFunction: (id, name) {
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
                                            content: Text(
                                                "FERPA requires that data be de-idetinfied when disclosing it with "
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
