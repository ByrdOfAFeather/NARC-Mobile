import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'APIWrapper.dart';
import 'main.dart';
import 'narcCourses.dart';

class NarcGetCanvasInfo extends StatefulWidget{

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
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Canvas Access token",
                              hintText: "You can create this under your Canvas user settings!"
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'You have to enter an API key!';
                              }
                              else if (tokenTestError.isNotEmpty) {
                                return tokenTestError;
                              }
                              else {
                                apiKey = value;
                                return null;
                              }
                            }
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: TextFormField (
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                              labelText: "Canvas URL",
                              hintText: "ex: canvas.instructure.com"
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return "You have to enter a URL!";
                            }
                            else if (tokenTestError.isNotEmpty) {
                              return tokenTestError;
                            }
                            else {
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
                              final snackBar = new SnackBar(content: Text("Validating Token...."),);
                              _scaffoldKey.currentState.showSnackBar(snackBar);
                              tokenTestError = "";
                              if (_formKey.currentState.validate()) {
                                test() async {
                                  bool goodToken = await testToken(apiKey, url);
                                  if (goodToken) {
                                    FlutterSecureStorage storage = StorageSingleton.getStorage();
                                    storage.write(key:"apiKey", value:apiKey);
                                    storage.write(key:"url", value:url);
                                    _scaffoldKey.currentState.removeCurrentSnackBar();
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => NarcCourses()),
                                    );
                                  }
                                  else {
                                    tokenTestError = "Error! Please Check URL and your Token!";
                                    _scaffoldKey.currentState.removeCurrentSnackBar();
                                    _formKey.currentState.validate();
                                  }
                                }
                                test();
                              }
                              else {
                                _scaffoldKey.currentState.removeCurrentSnackBar();
                              }
                            },
                            child: Text("Submit", style: TextStyle(color: Colors.white),)
                        ),
                      )
                    ]
                ),
              ),
            ],
          )
      ),
    );
  }
}
