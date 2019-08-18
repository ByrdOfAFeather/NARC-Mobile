import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:narc/mainMenu.dart';
import 'package:url_launcher/url_launcher.dart';

import 'APIWrapper.dart';
import 'main.dart';

class GetCanvasURL extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GetCanvasURLState();
  }
}

class _GetCanvasURLState extends State<GetCanvasURL> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool canTestURL = true;
  String urlTestError = "";
  String url;
  final _urlSnackBar = new SnackBar(
    content: Text("Testing URL....",),
    duration: Duration(minutes: 5),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("NARC"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: "Canvas URL", hintText: "ex: canvas.instructure.com"),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "You have to enter a URL!";
                        } else if (urlTestError.isNotEmpty) {
                          return urlTestError;
                        } else {
                          url = value;
                          return null;
                        }
                      },
                    ),
                  ),
                  RaisedButton(
                    color: Colors.green,
                    onPressed: () async {
                      urlTestError = "";
                      if (_formKey.currentState.validate()) {
                        _testURL() async {
                          canTestURL = false;
                          try {
                            _scaffoldKey.currentState.showSnackBar(_urlSnackBar);
                            http.Response request = await http.get("https://$url");
                            if (request.statusCode == 200) {
                              _scaffoldKey.currentState.removeCurrentSnackBar();
                              storage.write(key: "url", value: url);
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (context) => GetCanvasToken(url: url)));
                            } else {
                              _scaffoldKey.currentState.removeCurrentSnackBar();
                              urlTestError = "Please use a valid URL!";
                              _formKey.currentState.validate();
                              canTestURL = true;
                            }
                          } on Exception {
                            _scaffoldKey.currentState.removeCurrentSnackBar();
                            // TODO: More specific URL Exception
                            urlTestError = "Please use a valid URL!";
                            _formKey.currentState.validate();
                            canTestURL = true;
                          }
                        }
                        if (canTestURL) {
                          await _testURL();
                        }
                        else {
                          // Do nothing
                        }
                      }
                    },
                    child: Text("Next!", style: TextStyle(color: Colors.white),),
                  )
                ],
              ),
            ),
          ])),
    );
  }
}

class GetCanvasToken extends StatefulWidget {
  final String url;

  const GetCanvasToken({Key key, this.url}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GetCanvasTokenState();
  }
}

class _GetCanvasTokenState extends State<GetCanvasToken> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _checkingTokenSnackBar = new SnackBar(content: Text("Checking API token...."), duration: Duration(minutes: 5),);
  String tokenValidationError = "";
  String apiKey;


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("NARC"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Canvas API Token",
                    hintText: "This can be generated in your settings!",
                  ),
                  textAlign: TextAlign.center,
                  validator: (String newValue) {
                    if (newValue.isEmpty) {
                      return "API Token cannot be empty!";
                    }
                    else if (tokenValidationError.isNotEmpty) {
                      return tokenValidationError;
                    }
                    else {
                      apiKey = newValue;
                      return null;
                    }
                  },
                ),
                Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        RaisedButton(
                            onPressed: () async {
                              if (await canLaunch("https://${widget.url}/profile/settings")) {
                                await launch("https://${widget.url}/profile/settings");
                              }
                              else {
                                // TODO: Error
                              }
                            },
                            color: Colors.green,
                            child: Text("Go To Canvas Settings", style: TextStyle(color: Colors.white),)),
                        RaisedButton(
                          color: Colors.green,
                          onPressed: () async {
                            _scaffoldKey.currentState.showSnackBar(_checkingTokenSnackBar);
                            if (_formKey.currentState.validate()) {
                              _testToken() async {
                                bool goodToken = await testToken(apiKey, widget.url);
                                if (goodToken) {
                                  FlutterSecureStorage storage = StorageSingleton.getStorage();
                                  storage.write(key: "apiKey", value: apiKey);
                                  _scaffoldKey.currentState.removeCurrentSnackBar();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => MainMenuWrapper), (_) => false);
                                } else {
                                  tokenValidationError = "Error! Please Check your Token!";
                                  _scaffoldKey.currentState.removeCurrentSnackBar();
                                  _formKey.currentState.validate();
                                }
                              }

                              _testToken();
                            }
                            else {
                              _scaffoldKey.currentState.removeCurrentSnackBar();
                            }
                          },
                          child: Text("Submit", style: TextStyle(color: Colors.white),),
                        )
                      ],
                    ))
              ],
            ),
          )
        ],
      ),
    );
  }
}

/*
 
 */

class NarcGetCanvasInfo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NarcGetCanvasInfoState();
  }
}

class _NarcGetCanvasInfoState extends State<NarcGetCanvasInfo> {
  String apiKey;
  String url;
  String tokenTestError = "";
  static final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("NARC"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
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
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: "Canvas Access token",
                            hintText: "You can create this under your Canvas user settings!"),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'You have to enter an API key!';
                          } else if (tokenTestError.isNotEmpty) {
                            return tokenTestError;
                          } else {
                            apiKey = value;
                            return null;
                          }
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: "Canvas URL", hintText: "ex: canvas.instructure.com"),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "You have to enter a URL!";
                        } else if (tokenTestError.isNotEmpty) {
                          return tokenTestError;
                        } else {
                          url = value;
                          return null;
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                        color: Colors.green,
                        onPressed: () {
                          final snackBar = new SnackBar(
                            content: Text("Validating Token...."),
                          );
                          _scaffoldKey.currentState.showSnackBar(snackBar);
                          tokenTestError = "";
                          if (_formKey.currentState.validate()) {
                            test() async {
                              bool goodToken = await testToken(apiKey, url);
                              if (goodToken) {
                                FlutterSecureStorage storage = StorageSingleton.getStorage();
                                storage.write(key: "apiKey", value: apiKey);
                                storage.write(key: "url", value: url);
                                _scaffoldKey.currentState.removeCurrentSnackBar();
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => MainMenuWrapper),
                                );
                              } else {
                                tokenTestError = "Error! Please Check URL and your Token!";
                                _scaffoldKey.currentState.removeCurrentSnackBar();
                                _formKey.currentState.validate();
                              }
                            }

                            test();
                          } else {
                            _scaffoldKey.currentState.removeCurrentSnackBar();
                          }
                        },
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        )),
                  )
                ]),
              ),
            ],
          )),
    );
  }
}
