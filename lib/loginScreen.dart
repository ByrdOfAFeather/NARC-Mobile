import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:narc/canvasInfoScreen.dart';
import 'package:narc/registerScreen.dart';

import 'APIWrapper.dart';
import 'main.dart';
import 'narcCourses.dart';

class NarcMain extends StatefulWidget {
  final String firebaseToken;
  final String title;
  final GlobalKey<NavigatorState> navKey;
  NarcMain({Key key, this.title, this.navKey, this.firebaseToken}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NarcMainState();
  }
}

class _NarcMainState extends State<NarcMain> {
  String password;
  String username;
  static final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: ListView(children: <Widget>[
        Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Image.asset(
                  'assets/narc.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: TextFormField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: "Username",
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Username can't be empty!";
                        } else {
                          username = value;
                          return null;
                        }
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (value) {
                      if (value.isEmpty) {
                        return "Password can't be empty!";
                      } else {
                        password = value;
                        return null;
                      }
                    },
                  ),
                ),

                Container(
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                      RaisedButton(
                          color: Colors.green,
                          onPressed: () {
                            final snackBar = new SnackBar(content: Text("Trying to Login..."));
                            _scaffoldKey.currentState.showSnackBar(snackBar);

                            if (_formKey.currentState.validate()) {
                              testInput() async {
                                String getApiKey = await attemptLogin(username, password, widget.firebaseToken);
                                if (getApiKey.isNotEmpty) {
                                  FlutterSecureStorage storage = StorageSingleton.getStorage();
                                  storage.write(key: "token", value: getApiKey);
                                  String savedAPIToken = await storage.read(key: "apiKey");
                                  String savedURL = await storage.read(key: "url");
                                  _scaffoldKey.currentState.removeCurrentSnackBar();

                                  if (savedAPIToken == null || savedURL == null || await testToken(savedAPIToken, savedURL)) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => NarcGetCanvasInfo()),
                                    );
                                  }
                                  else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => NarcCourses()),
                                    );
                                  }

                                } else {
                                  _scaffoldKey.currentState.removeCurrentSnackBar();
                                  // TODO: Say failed to Login
                                }
                              }
                              testInput();
                            }
                            else {
                              _scaffoldKey.currentState.removeCurrentSnackBar();
                            }
                          },
                          child: Text("Login",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )),

                      RaisedButton(
                          color: Colors.green,
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                NarcRegister(notificationToken: widget.firebaseToken,)));
                          },
                          child: Text("Register", style: TextStyle(color: Colors.white))),
                    ]))
              ],
            ),
          )
        ]),
      ]),
    );
  }
}
