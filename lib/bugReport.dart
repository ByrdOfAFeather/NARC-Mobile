import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:narc/APIWrapper.dart';

class BugReportScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _BugReportScreenState();
  }
}

class _BugReportScreenState extends State<BugReportScreen> {
  String _report;
  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(child:Scaffold(
      appBar: AppBar(
        title: Text("Report Bug"),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Please include what you were doing and what screen you were on!"
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 10,
                  validator: (String input) {
                    if (input.isEmpty) {
                      return "You can't submit an empty report!";
                    }
                    else {
                      _report = input;
                      return null;
                    }
                  },
                ),
                RaisedButton(
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      submitBugReport(_report);
                      _formKey.currentState.reset();
                    }
                  },
                  child: Text("Submit!")
                )
              ],
            ),
          )
        ],
      )
    ), onWillPop: () async {return false; });  // do nothing
  }
}