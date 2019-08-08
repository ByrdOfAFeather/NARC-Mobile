import 'package:flutter/material.dart';
import 'package:flutter_sqlcipher/sqlite.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';

import 'APIWrapper.dart';

class NarcResultsArguments {
  final dynamic results;
  final String quizName;

  NarcResultsArguments({this.results, this.quizName});
}

class NarcResultsGetPassword extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NarcResultsGetPasswordState();
  }
}

class _NarcResultsGetPasswordState extends State<NarcResultsGetPassword> {
  String password;
  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final NarcResultsArguments args = ModalRoute.of(context).settings.arguments;
    dynamic results = args.results;
    String name = args.quizName;

    if (results["message"] != null) {
      deleteSQLDB(name);
      return Scaffold(
          appBar: AppBar(title: Text(name + " Results")),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Center(child: Text(results["message"]))],
          ));
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(name + " Results"),
        ),
        body: AlertDialog(
          title: Text("Input Password for $name"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  validator: (String value) {
                    if (value.isEmpty) {
                      return "You must input a password";
                    } else {
                      password = value;
                      return null;
                    }
                  },
                ),
                RaisedButton(
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        showDialog(context: context, builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Disclosure"),

                            content: Form(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text("NARC is currently a piece of experimental software and is not "
                                          "meant to be used as a sole or deciding factor in determining cases of academic "
                                          "dishonesty. Please do not use these results as the only indiciator that someone has "
                                          "cheated or that someone has not cheated. As well, do not use this as the determining indicator "
                                          "that someone has cheated or that someone has not cheated. "),
                                      RaisedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => NarcResults(
                                                    password: password,
                                                    quizName: name,
                                                    results: results,
                                                  )));
                                        },
                                        child: Text("OK")
                                      )
                                    ]
                                )
                            ),
                          );
                        });
                      }
                    },
                    child: Text("Submit"))
              ],
            ),
          ),
        ));
  }
}

class NarcResults extends StatefulWidget {
  final dynamic results;
  final String quizName;
  final String password;

  NarcResults({Key key, this.quizName, this.password, this.results}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NarcResults();
  }
}

class TestTaker {
  final String name;
  final timeTaken;
  final averageTimeBetweenQuestions;
  final pageLeaves;

  TestTaker({this.name, this.timeTaken, this.averageTimeBetweenQuestions, this.pageLeaves});
}

class _NarcResults extends State<NarcResults> {
  List<TestTaker> cheaters;
  List<TestTaker> nonCheaters;
  Future<Map<String, List<TestTaker>>> combined;

  static final _formKey = GlobalKey<FormState>();

  initState() {
    super.initState();
    combined = buildMap(widget.results["cheaters"], widget.results["non_cheaters"]);
  }

  Future<Map<String, List<TestTaker>>> buildMap(cheaters, nonCheaters) async {
    cheaters = await decryptData(cheaters);
    nonCheaters = await decryptData(nonCheaters);
    return {"cheaters": cheaters, "nonCheaters": nonCheaters};
  }

  decodeData(String code, String password) async {
    final cryptor = new PlatformStringCryptor();
    String indexOrg = code;
    String salt = await storage.read(key: "encryptionSalt");
    String key = await cryptor.generateKeyFromPassword(indexOrg + password, salt);
    SQLiteDatabase database = await getOrCreateDatabase(widget.quizName);

    // Note that base is a unique identifier so this will only return a single value!
    for (var row in await database.rawQuery("""
    SELECT name, time_taken, average_time_between_questions, page_leaves FROM userdata WHERE base = "$code"
    """)) {
      try {
        String name = await cryptor.decrypt(row["name"], key);
        String timeTaken = await cryptor.decrypt(row["time_taken"], key);
        String averagePageLeaves = await cryptor.decrypt(row["average_time_between_questions"], key);
        String pageLeaves = await cryptor.decrypt(row["page_leaves"], key);
        return TestTaker(
            name: name, timeTaken: timeTaken, averageTimeBetweenQuestions: averagePageLeaves, pageLeaves: pageLeaves);
      } on MacMismatchException {
        return null;
      }
    }
  }

  Future<List<TestTaker>> decryptData(data) async {
    List<TestTaker> users = [];
    List<String> genericList = new List<String>.from(data);
    for (var generic in genericList) {
      TestTaker currentTaker = await decodeData(generic, widget.password);
      if (currentTaker == null) {
        return null;
      }
      users.add(await decodeData(generic, widget.password));
    }
    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizName + " Results"),
        ),
        body: Column(
          children: <Widget>[
            FutureBuilder(
              future: combined,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.data == null && snapshot.connectionState != ConnectionState.done) {
                  return Center(child:CircularProgressIndicator());
                }
                else if (snapshot.data["cheaters"] == null || snapshot.data["nonCheaters"] == null) {
                  return Column(children: <Widget>[
                    Padding(child:Center(child: Text("Password is invalid")), padding: EdgeInsets.symmetric(vertical: 16),),
                    // TODO: This pops back to modules not quizzes hrm
                    RaisedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Back"),
                    )
                  ]);
                }
                else {
                  return Flexible(child: ListView.builder(
                      itemCount: snapshot.data["cheaters"].length + snapshot.data["nonCheaters"].length + 2,
                      itemBuilder: (BuildContext context, int index) {
                        if (snapshot.data["cheaters"].length >= index) {
                          if (index == 0) {
                            return Card
                              (color: Colors.black,
                                child:ListTile(title:Center(child: Text("CHEATERS", style: TextStyle(color: Colors.white),))));
                          }
                          index -= 1;
                          return Card(
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                    context, MaterialPageRoute(builder: (context) => NarcIndividualView(user: snapshot.data["cheaters"][index])));
                              },
                              title: Center(child:Text(snapshot.data["cheaters"][index].name)),
                            ),
                          );
                        }
                        else {
                          if (index == snapshot.data["cheaters"].length + 1) {
                            return Card
                              (color: Colors.black,
                                child:ListTile(title:Center(child: Text("INNOCENTS", style: TextStyle(color: Colors.white),))));
                          }
                          index -= snapshot.data["cheaters"].length;
                          index -= 2;
                          return Card(
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                    context, MaterialPageRoute(builder: (context) => NarcIndividualView(user: snapshot.data["nonCheaters"][index])));
                              },
                              title: Center(child: Text(snapshot.data["nonCheaters"][index].name)),
                            ),
                          );
                      }}));
                }
              }
            ),
          ],
        ));
  }
}

class NarcIndividualView extends StatefulWidget {
  final TestTaker user;

  NarcIndividualView({Key key, this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NarcIndividualViewState();
  }
}

class _NarcIndividualViewState extends State<NarcIndividualView> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(child: Text(widget.user.pageLeaves.toString())),
          Center(child: Text(widget.user.averageTimeBetweenQuestions.toString())),
          Center(child: Text(widget.user.timeTaken.toString())),
        ],
      ),
    );
  }
}
