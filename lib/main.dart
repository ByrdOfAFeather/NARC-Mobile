// Standard Library
import 'dart:convert';
import 'package:flutter/material.dart';

// External Imports
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sqlcipher/sqlite.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';

// App imports
import 'package:narc/APIWrapper.dart';
import 'package:narc/mainMenu.dart';
import 'package:vibration/vibration.dart';

import 'loginScreen.dart';
import 'narcResults.dart';

// TODO: ERROR WHEN LOGGING BACK IN FROM THE SAME DEVICE

final routes = {
  "/courses": (context) => MainMenuWrapper,
  "/resultsMenu": (context) => ResultsMenuWrapper,
  "/results": (context) => NarcResultsGetPassword()
};


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
Future<void> firebaseCloudMessagingListeners(GlobalKey<NavigatorState> navKey) async {
  _firebaseToken = await _firebaseMessaging.getToken();
  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
      if (message["data"]["type"] == "notification") {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate();
        }
      } else {
        await saveResultsAndPushResultsScreen(message, navKey);
      }
    },
    onResume: (Map<String, dynamic> message) async {
      navKey.currentState.pushNamedAndRemoveUntil("/resultsMenu", (_) => false);
    },
    onLaunch: (Map<String, dynamic> message) async {
      navKey.currentState.pushNamed(
        "/resultsMenu",
      );
    },
  );
  _firebaseMessaging
      .requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
}

final navKey = GlobalKey<NavigatorState>(); // Get a navigator key for setting up firebase navigations

void main() async {
  SQLiteDatabase db = await getOrCreateDatabase("storage"); // Main database for storing results

  db.execSQL("""CREATE TABLE IF NOT EXISTS savedresults (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quizName TEXT NOT NULL,
  results TEXT NOT NULL 
  )"""); // If the table for results doesn't exist, create it

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
        routes: routes,
        home: MainMenuWrapper));
  } else {
    runApp(MaterialApp(
        navigatorKey: navKey,
        title: 'NARC',
        theme: ThemeData(
          cursorColor: Colors.black,
          primarySwatch: Colors.green,
        ),
        routes: routes,
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