import 'package:flutter/material.dart';
import 'package:narc/canvasInfoScreen.dart';

import 'APIWrapper.dart';

class NarcRegister extends StatefulWidget {
  final String notificationToken;
  NarcRegister({Key key, this.notificationToken}) : super(key: key);

  @override
  State<StatefulWidget> createState() {

    return _NarcRegisterState();
  }
}

class _NarcRegisterState extends State<NarcRegister> {
  final _controller = TextEditingController();
  static final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _usernameValidator = "";
  String _passwordValidator = "";
  String _confirmPasswordValidator = "";
  String _username;
  String _password;
  String _confirmPassword;
  String _email;
  bool _saveData = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("NARC"),
        centerTitle: true,
      ),
      body: ListView(children: <Widget>[
        Column(
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
                        controller: _controller,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: "Username",
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return "Username can't be empty!";
                          } else if (_usernameValidator.isNotEmpty) {
                            return _usernameValidator;
                          } else {
                            _username = value;
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
                        } else if (_passwordValidator.isNotEmpty) {
                          return _passwordValidator;
                        }
                        else if (_confirmPasswordValidator.isNotEmpty) {
                          return _confirmPasswordValidator;
                        }
                        else {
                          _password = value;
                          return null;
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: "Confirm Password"),
                      obscureText: true,
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Passwords must match!";
                        } else if (_passwordValidator.isNotEmpty) {
                          return _passwordValidator;
                        }
                        else if (_confirmPasswordValidator.isNotEmpty) {
                          return _confirmPasswordValidator;
                        }
                        else {
                          _confirmPassword = value;
                          return null;
                        }
                      },
                    ),
                  ),
                  Container(child:Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                    Text("Allow NARC to save data? (Currently not supported)"),
                    Checkbox(
                      value: _saveData,
                      onChanged: (bool newValue) {
                        setState(() {
                          _saveData = _saveData;
                        });
                      },
                    ),
                    IconButton(
                        icon: Icon(Icons.info_outline),
                        highlightColor: Colors.green,
                        onPressed: () {
                          showDialog(context: context, builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Allowing NARC to save data"),
                              content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                Text("NARC works better when it has more data to work with. All data saved through the "
                                    "program will be anonymized by removing both the student name and student ID. The "
                                    "data saved through the program will be able to be permantly deleted at the user's discretion. "
                                    "However, all data that NARC has saved will be realeased publically on a rolling basis. "
                                    "All users who have allowed NARC to save data will be emailed before the release happens "
                                    "so that they may delete any data they do not want to be publically shared. "
                                    "Once the data is released, users can still delete any data that was "
                                    "released from NARC and it will not be released in subsequent rollouts, but previous datasets will still "
                                    "contain the data and anyone who downloaded the data will still have access to it."
                                    "for FERPA & COPPA compliance please see the privacy policy portion of NARC's website "
                                    "at www.byrdof.dev "),
                                RaisedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      },
                                    child: Text("OK")
                                )
                              ],),
                            );
                          });
                      },
                    )
                  ],)),
                  Container(
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                        RaisedButton(
                            color: Colors.green,
                            onPressed: () {
                              final snackBar = new SnackBar(content: Text("Registering user..."));
                              _scaffoldKey.currentState.showSnackBar(snackBar);
                              _usernameValidator = "";
                              _passwordValidator = "";
                              _confirmPasswordValidator = "";
                              if (_formKey.currentState.validate()) {
                                _confirmPasswordValidator = _password == _confirmPassword ? "" : "Passwords must match!";
                                if (_formKey.currentState.validate()) {
                                  testInput() async {
                                    dynamic getApiKey = await attemptAccountCreation(
                                        _username, _password, widget.notificationToken);
                                    if (getApiKey["error"] == null) {
                                      storage.write(key: "token", value: getApiKey["success"]["data"]["token"]);
                                      if (_saveData) {
                                        storage.write(key: "canStore", value: "true");
                                      }
                                      _scaffoldKey.currentState.removeCurrentSnackBar();
                                      Navigator.pop(context);
                                      Navigator.pushReplacement(
                                          context, MaterialPageRoute(builder: (context) => NarcGetCanvasInfo()));
                                    }
                                    else {
                                      _scaffoldKey.currentState.removeCurrentSnackBar();
                                      if (getApiKey["error"]["data"]["username"] != null) {
                                        this._usernameValidator = "Username already in use!";
                                      }
                                      else if (getApiKey["error"]["data"]["password"] != null) {
                                        this._passwordValidator = "Password does not meet minimum requirements!";
                                      }
                                      _formKey.currentState.validate();
                                    }
                                  }
                                  testInput();
                                }
                                else {
                                  _scaffoldKey.currentState.removeCurrentSnackBar();
                                }
                              }
                              else {
                                _scaffoldKey.currentState.removeCurrentSnackBar();
                              }
                            },
                            child: Text("Register", style: TextStyle(color: Colors.white))),
                      ]))
                ],
              ),
            )
          ],
        ),
      ]),
    );
  }
}
