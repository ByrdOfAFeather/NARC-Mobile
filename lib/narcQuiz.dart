import 'package:flutter/material.dart';

import 'APIWrapper.dart';

class NarcQuiz extends StatefulWidget {
  final String quizID;
  final String password;
  final String quizName;

  NarcQuiz({Key key, this.quizID, this.password, this.quizName}) : super(key: key);

  State<StatefulWidget> createState() {
    return _NarcQuizState();
  }
}

class _NarcQuizState extends State<NarcQuiz> {
  Future<String> response;

  @override
  void initState() {
    response = startSeparationTask(widget.quizID, widget.password, widget.quizName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    precacheImage(new AssetImage('assets/narc.png'), context);

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizName),
          centerTitle: true,
        ),
        body: FutureBuilder(
            future: response,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null && snapshot.connectionState != ConnectionState.done) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Image.asset(
                      'assets/narc.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    Column(children: <Widget>[
                      Padding(
                          child:Center(child: CircularProgressIndicator()), padding: EdgeInsets.symmetric(vertical: 16),),
                      Center(child: Text("Building Dataset, please do not leave this page or close the app"))
                    ]),
                  ],
                );
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Image.asset(
                    'assets/narc.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  Column(children: <Widget>[
                    Padding(child:Center(child: Text(snapshot.data)), padding: EdgeInsets.symmetric(vertical: 16)),
                    RaisedButton(
                      // TODO: The root cause of this issue is that going back from results goes to modules instead of quizzes
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Back"),
                    )
                  ]),
                ],
              );
            }));
  }
}