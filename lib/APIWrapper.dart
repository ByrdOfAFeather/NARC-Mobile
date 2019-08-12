import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_android/android_content.dart' show Context;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sqlcipher/sqlite.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:narc/main.dart';

final String baseURL = "https://www.byrdof.dev";
final String loginURL = "$baseURL/api/token_auth/";
final String createURL = "$baseURL/api/create_user/";


FlutterSecureStorage storage = StorageSingleton.getStorage();
Map<String, bool> threadControl = {};
Map<String, String> threadOutput = {};


class GenericCanvasItem {
  final int genericID;
  final String genericName;
  GenericCanvasItem({this.genericID, this.genericName});
  factory GenericCanvasItem.fromJson(Map<String, dynamic> json) {
    return GenericCanvasItem(
      genericID: json['id'],
      genericName: json['name'],
    );
  }
  factory GenericCanvasItem.fromJsonQuiz(Map<String, dynamic> json) {
    return GenericCanvasItem(
      genericID: json['content_id'],
      genericName: json['title'],
    );
  }
}


double toDouble(value) {
  if (value is double) {
    return value;
  }
  else {
    return value.toDouble();
  }
}

Future<String> attemptLogin(String username, String password, String notificationToken) async {
  String device;
  if (Platform.isAndroid) {
    device = "android";
  }
  else {
    device = "ios";
  }
  dynamic data = {"password": password, "username": username, "notification_token": notificationToken, "device": device};
  try {
    var response = await http.post(loginURL, body: json.encode(data), headers: {"content-type": "application/json"});
    if (response.statusCode == 200) {
      dynamic responseData = json.decode(response.body);
      return responseData["success"]["data"]["token"];
    }
    else {
      return "";
    }
  } on SocketException {
    return "SE";
  }
}

Future<dynamic> attemptAccountCreation(String username, String password, String notificationToken) async {
  String device;
  if (Platform.isAndroid) {
    device = "android";
  }
  else {
    device = "ios";
  }

  dynamic data = {"password": password, "username": username, "notification_token": notificationToken, "device": device};
  var response = await http.post(createURL, body: json.encode(data), headers:{"content-type": "application/json"});
  return json.decode(response.body);
}

Future<bool> testToken(String token, String url) async {
  HttpClient client = HttpClient();
  try {
    HttpClientRequest request = await client.getUrl(
        Uri.parse("https://" + url + "/api/v1/courses")
    );
    request.headers.set(HttpHeaders.authorizationHeader, "Bearer " + token);
    HttpClientResponse response = await request.close();
    if (response.statusCode == 200) {
      return true;
    }
    else {
      return false;
    }
  } on SocketException {
    return false;
  }
}

Future<HttpClientResponse> getCanvasItem(url, token) async {
  HttpClient client = HttpClient();
  HttpClientRequest request = await client.getUrl(
      Uri.parse(url));
  request.headers.set(HttpHeaders.authorizationHeader, "Bearer " + token);
  return await request.close();
}


Future<List<GenericCanvasItem>> _getGeneric(requestEndpoint, token) async {
  HttpClientResponse response = await getCanvasItem(requestEndpoint, token);
  if (response.statusCode == 200) {
    List<GenericCanvasItem> generic = [];
    StringBuffer result = new StringBuffer();
    await for (var content in response.transform(Utf8Decoder())) {
      result.write(content);
    }
    String responseText = result.toString();
    var jsonValues = json.decode(responseText);
    for (var course in jsonValues) {
      generic.add(GenericCanvasItem.fromJson(course));
    }
    return generic;
  }

  else {
    return new List<GenericCanvasItem>();
  }
}


Future<List<GenericCanvasItem>> getCourses() async {
  String token = await storage.read(key: "apiKey");
  String url = await storage.read(key: "url");
  String endPoint = "https://" + url + "/api/v1/courses";
  return  _getGeneric(endPoint, token);
}

Future<List<GenericCanvasItem>> getModules(String courseID) async {
  String token = await storage.read(key: "apiKey");
  String url = await storage.read(key: "url");
  String endPoint = "https://" + url + "/api/v1/courses/$courseID/modules";
  return  _getGeneric(endPoint, token);
}

Future<List<GenericCanvasItem>> getQuizzes(String moduleID) async {
  String courseID = await storage.read(key: "currentCourse");
  String token = await storage.read(key: "apiKey");
  String url = await storage.read(key: "url");
  String endPoint = "https://$url/api/v1/courses/$courseID/modules/$moduleID/items";
  HttpClientResponse response = await getCanvasItem(endPoint, token);
  if (response.statusCode == 200) {
    List<GenericCanvasItem> generic = [];
    StringBuffer result = new StringBuffer();
    await for (var content in response.transform(Utf8Decoder())) {
      result.write(content);
    }
    String responseText = result.toString();

    var jsonValues = json.decode(responseText);
    for (var json in jsonValues) {
      if (json["type"] == "Quiz") {
        generic.add(GenericCanvasItem.fromJsonQuiz(json));
      }
    }
    return generic;
  }

  else {
    return new List<GenericCanvasItem>();
  }
}

updateMaxMin(Map<String, double>runningTotals, localPageLeaves, localTimeBetween, localTimeSpent) {
  double overallPageLeavesMax = runningTotals["overall_page_leaves_max"];
  double overallPageLeavesMin = runningTotals["overall_page_leaves_min"];

  double overallTimeTakenMax = runningTotals["overall_time_taken_max"];
  double overallTimeTakenMin = runningTotals["overall_time_taken_min"];

  double overallTimeBetweenMax = runningTotals["overall_time_between_max"];
  double overallTimeBetweenMin = runningTotals["overall_time_between_min"];

  runningTotals["overall_page_leaves_max"] = (
      overallPageLeavesMax == null || overallPageLeavesMax < localPageLeaves)
      ? localPageLeaves : overallPageLeavesMax;
  runningTotals["overall_page_leaves_min"] = (
      overallPageLeavesMin== null || overallPageLeavesMin > localPageLeaves)
      ? localPageLeaves : overallPageLeavesMin;

  runningTotals["overall_time_taken_max"] = (
      overallTimeTakenMax == null || overallTimeTakenMax < localTimeSpent)
      ? localPageLeaves : overallTimeTakenMax;
  runningTotals["overall_time_taken_min"] = (
      overallTimeTakenMin == null || overallTimeTakenMin > localTimeSpent)
      ? localPageLeaves : overallTimeTakenMin;

  runningTotals["overall_time_between_max"] = (
      overallTimeBetweenMax == null || overallTimeBetweenMax < localTimeBetween)
      ? localPageLeaves : overallTimeBetweenMax;
  runningTotals["overall_time_between_min"] = (
      overallTimeBetweenMin == null || overallTimeBetweenMin > localTimeBetween)
      ? localPageLeaves : overallTimeBetweenMin;
}

parseUserData(dynamic submissionEvents, dynamic submission, dynamic outputDict, Map<String, double> runningTotals) {
  double localPageLeaves = 0;
  double localTimeBetween = 0;
  double localTimeBetweenDeno = 0;

  DateTime localStart;
  DateTime prevTime;
  DateTime curTime;
  for (var events in submissionEvents["quiz_submission_events"]) {
    if (events["event_type"] == "page_blurred") {
      localPageLeaves += 1;
    }

    else if (events["event_type"] == "session_started") {
      localStart = DateTime.parse(events["created_at"]);
    }

    else if (events["event_type"] != "question_answered") {
      continue;
    }

    else {
      if (prevTime == null) {
        prevTime = DateTime.parse(events["created_at"]);
      }
      else {
        curTime = DateTime.parse(events["created_at"]);
        int curCalc = curTime.difference(prevTime).inMilliseconds;
        curCalc = curCalc < 0 ? curCalc * -1 : curCalc;
        localTimeBetween += curCalc;
        localTimeBetweenDeno += 1;
        runningTotals["overall_time_between"] += curCalc;
        runningTotals["divide_by_between"] += 1;
        prevTime = curTime;
      }
    }
  }

  if (localTimeBetweenDeno == 0 && prevTime != null) {
    int curCalc = localStart.difference(prevTime).inMilliseconds;
    curCalc = curCalc < 0 ? curCalc * -1 : curCalc;
    outputDict["average_time_between_questions"] = curCalc;
    runningTotals["overall_time_between"] += curCalc;
    outputDict["time_taken"] = submission["time_spent"];
    runningTotals["overall_time_taken"] += submission["time_spent"];
    outputDict["page_leaves"] = localPageLeaves;
    runningTotals["overall_page_leaves"] += localPageLeaves;
    runningTotals["divide_by"] += 1;
    updateMaxMin(runningTotals, localPageLeaves, localTimeBetween, submission["time_spent"]);
    return true;
  }

  else if (localTimeBetweenDeno == 0){
    // This is the case where either there are no questions or the user did not answer any
    // The user is deleted as the user cannot cheat if they didn't answer a question!
    return false;
  }

  else {
    outputDict["average_time_between_questions"] = localTimeBetween / localTimeBetweenDeno;
    outputDict["time_taken"] = submission["time_spent"];
    runningTotals["overall_time_taken"] += submission["time_spent"];
    outputDict["page_leaves"] = localPageLeaves;
    runningTotals["overall_page_leaves"] += localPageLeaves;
    runningTotals["divide_by"] += 1;
    updateMaxMin(runningTotals, localPageLeaves, localTimeBetween, submission["time_spent"]);
    return true;
  }
}

Future<String> getKey(String baseIndex,  String password, cryptor) async {
  String indexOrg = baseIndex + password;
  String salt = await storage.read(key: "encryptionSalt");
  return await cryptor.generateKeyFromPassword(indexOrg, salt);
}

Future<SQLiteDatabase> getOrCreateDatabase(String quizName) async {
  var cacheDir = await Context.cacheDir;
  await cacheDir.create(recursive: true);

  var cacheFile = File("${cacheDir.path}/$quizName.db");
  var db = await SQLiteDatabase.openOrCreateDatabase(cacheFile.path);
  return db;
}

deleteSQLDB(String quizName) async {
  var cacheDir = await Context.cacheDir;
  await cacheDir.create(recursive: true);

  var cacheFile = File("${cacheDir.path}/$quizName.db");
  await SQLiteDatabase.deleteDatabase(cacheFile.path);
}

writeEncryptedUserData(String key, String keyBase, PlatformStringCryptor cryptor, dynamic data, SQLiteDatabase database) async {
  String averageTimeBetweenQuestions = await cryptor.encrypt(data["average_time_between_questions"].toString(), key);
  String timeTaken =  await cryptor.encrypt(data["time_taken"].toString(), key);
  String pageLeaves = await cryptor.encrypt(data["page_leaves"].toString(), key);
  String id =  await cryptor.encrypt(data["id"].toString(), key);
  String name = await cryptor.encrypt(data["name"].toString(), key);
  await database.insert(table: "userdata", values: <String, dynamic> {
    "base": keyBase,
    "id": id,
    "name": name,
    "page_leaves": pageLeaves,
    "average_time_between_questions": averageTimeBetweenQuestions,
    "time_taken": timeTaken,
  });
}

dynamic anonymizeData(dynamic data, String password, String quizName) async {
  // TODO: Test relinking of values
  SQLiteDatabase database;
  await deleteSQLDB(quizName);
  database = await getOrCreateDatabase(quizName);
  await database.execSQL("""
    CREATE TABLE userdata (
      base TEXT PRIMARY KEY NOT NULL, 
      id TEXT NOT NULL, 
      name TEXT NOT NULL, 
      page_leaves TEXT NOT NULL, 
      average_time_between_questions TEXT NOT NULL, 
      time_taken TEXT NOT NULL
    )
  """);

  final cryptor = new PlatformStringCryptor();
  var generator = new Random.secure();
  dynamic anonData = {};

  String currentUser;
  for (var v in data.entries) {
    v = v.value;
    currentUser = generator.nextInt(1000000).toString();
    // THIS MIGHT CAUSE PROBLEMS
    String baseIndexOrg = toDouble(v["average_time_between_questions"]).toString() +
        toDouble(v["time_taken"]).toString() + toDouble(v["page_leaves"]).toString();
    List<int> baseIndexBytes = Utf8Encoder().convert(baseIndexOrg);
    String baseIndex = sha256.convert(baseIndexBytes).toString();
    String key = await getKey(baseIndex, password, cryptor);
    await writeEncryptedUserData(key, baseIndex, cryptor, v, database);
    anonData[currentUser] = {};
    anonData[currentUser]["name"] = null;
    anonData[currentUser]["id"] = currentUser;
    anonData[currentUser]["average_time_between_questions"] = v["average_time_between_questions"];
    anonData[currentUser]["time_taken"] = v["time_taken"];
    anonData[currentUser]["page_leaves"] = v["page_leaves"];
  }
  String salt = await storage.read(key: "encryptionSalt");
  String quizPass = await storage.read(key: "token");
  String key = await cryptor.generateKeyFromPassword(quizPass, salt);
  anonData["quiz_name"] = await cryptor.encrypt(quizName, key);
  return anonData;
}

dynamic getData(String quizID) async {
  String courseID = await storage.read(key: "currentCourse");
  String token = await storage.read(key: "apiKey");
  String url = await storage.read(key: "url");
  String endPoint = "https://$url/api/v1/courses/$courseID/quizzes/$quizID/submissions?per_page=1000";
  var client = new Client();
  Map<String, String> headers = {"Authorization": "Bearer $token"};
  Response response = await client.get(endPoint, headers: headers);
  if (response.statusCode == 200) {
    Map<String, dynamic> usersToData = {};

    var quizSubmissions = json.decode(response.body);

    Map<String, double> runningTotals = {
      "overall_time_between": 0,
      "overall_time_taken": 0,
      "overall_page_leaves": 0,
      "divide_by_between": 0,
      "divide_by" : 0,
      "overall_time_taken_max": null,
      "overall_time_taken_min": 0,
      "overall_time_between_max": null,
      "overall_time_between_min": 0,
      "overall_page_leaves_max": null,
      "overall_page_leaves_min": 0,
    };

    for (var submission in quizSubmissions["quiz_submissions"]) {
      String userID = submission["user_id"].toString();
      String submissionID = submission["id"].toString();
      String endPoint = "https://$url/api/v1/courses/$courseID/quizzes/$quizID/submissions/$submissionID/events?per_page=50000";
      response = await client.get(endPoint, headers: headers);
      if (response.statusCode == 200) {
        var submissionEvents = json.decode(response.body);

        usersToData[userID] = {};
        bool tester = parseUserData(submissionEvents, submission, usersToData[userID], runningTotals);
        if (!tester) {
          // This is the case where the user doesn't have enough data to be included in the separation so they are
          // excluded from the data set.
          // TODO: This either needs to be more transparent to the user or needs to be added to a exclusive separation area
          usersToData.remove(userID);
        }

        String userEndPoint = "https://$url/api/v1/users/$userID/profile";
        response = await client.get(userEndPoint, headers: headers);
        var userProfile = json.decode(response.body);

        usersToData[userID]["name"] = userProfile["name"];
        usersToData[userID]["id"] = userID;
      }
      else {
        client.close();
        usersToData["error"] = "Canvas servers appear to be down! (Or maybe the API has been changed?)";
      }
    }
    client.close();
    return usersToData;
  }
  else {
    client.close();
    return {"error": "Canvas servers appear to be down! (Or maybe the API has been changed?)"};
  }
}

Future<String> startSeparationTask(String quizID, String password, String quizName) async {
  bool quizThreadExists = threadControl[quizName] == true;
  if (quizThreadExists) { return "already running!"; }

  var data = await getData(quizID);
  if (data["error"] != null) {
    return data["error"];
  }


  data = await anonymizeData(data, password, quizName);
  data["secret"] = "MyNameIsM";
  String canStore = await storage.read(key: "canStore");
  data["storage"] = canStore == null ? false : true;
  String token = await storage.read(key: "token");

  var response;
  try {
    response = await http.post("$baseURL/api/post_mobile/",
        body: {"data": json.encode(data)},
        headers: {"Authorization": "Token $token"}
    );
  } on SocketException {
    return "The server is currently experincing technical difficulties and could not handle your request.";
  }
  if (response.statusCode == 202) {
    threadControl[quizName] = false;
    return "Your data is currently in line for processing and you will be notified when it is completed!";
  }
  else if (response.statusCode == 200) {
    threadControl[quizName] = false;
    return "Your data is currently being processed and will be returned soon! You can now leave this page.";
  }
  else if (response.statusCode == 401) {
    threadControl[quizName] = false;
    return "You need to login again!";
  }
  else {
    threadControl[quizName] = false;
    return "An  unkown error occured! Please report this!";
  }
}

Future<String> submitBugReport(String report) async {
  String token = await storage.read(key: "token");
  String data = json.encode({"report": report});
  Response response = await http.post("$baseURL/api/submit_report/",
      body: {"data": data},
      headers: {"Authorization": "Token $token"}
      );
  if (response.statusCode == 200) {
    return "Report submitted!";
  }
  else {
    return "There was some sort of error :[";
  }
}