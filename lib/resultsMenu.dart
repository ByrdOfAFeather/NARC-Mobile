import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sqlcipher/sqlite.dart';
import 'package:narc/APIWrapper.dart';

import 'narcResults.dart';

class ResultsMenu extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _ResultsMenuState();
  }
}

class _ResultsMenuState extends State<ResultsMenu> {

  Future<List<List<String>>> getSavedResults() async {
    List<List<String>> results = new List();
    SQLiteDatabase db = await getOrCreateDatabase("storage");
    for (var result in await db.rawQuery("""SELECT DISTINCT id, quizName, results FROM savedresults""")) {
      results.add([result["quizName"], result["results"], "${result["id"]}"]);
    }
    return results;
  }

  Future<void> deleteRow(id) async {
    SQLiteDatabase db = await getOrCreateDatabase("storage");
    await db.delete(table: "savedresults", where: "id = ?", whereArgs: [id]);
    return;
  }

  Future<void> _refreshResults() async {
    setState(() {
      getSavedResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(child:Scaffold(
        appBar: AppBar(
          title: Text("Results"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: RefreshIndicator(child: FutureBuilder(
          future: getSavedResults(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null && snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator());
            }
            else if ((snapshot.data == null || snapshot.data.isEmpty) && snapshot.connectionState == ConnectionState.done) {
              return Container(child: Center(child: Text("No results found!")));
            }
            else {
              return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(context, "/results", arguments: NarcResultsArguments(
                              results: jsonDecode(snapshot.data[index][1]),
                              quizName: snapshot.data[index][0]));
                        },
                        title: Text(snapshot.data[index][0]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            deleteSQLDB(snapshot.data[index][0]);
                            await deleteRow(snapshot.data[index][2]);
                            setState(() {
                              getSavedResults();
                            });
                          },
                        ),
                      ),
                    );
                  }
              );
            }
          },
        ), onRefresh: _refreshResults)),
        onWillPop: () async {return false;}  // Do nothing
    );
  }
}