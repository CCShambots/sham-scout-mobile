import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sham_scout_mobile/SearchWindow.dart';
import 'package:sham_scout_mobile/formItems.dart';
import 'package:sham_scout_mobile/history.dart';
import 'package:sham_scout_mobile/home.dart';
import 'package:sham_scout_mobile/matches.dart';
import 'package:sham_scout_mobile/schedule.dart';
import 'package:sham_scout_mobile/scan.dart';
import 'package:sham_scout_mobile/settings.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionStatus {
  static bool connected = false;

  static const connectionInterval = Duration(seconds: 5);

  static checkConnection() async{
    var url = Uri.parse(ApiConstants.statusEndpoint);

    try {
      var response = await http.get(url).timeout(const Duration(seconds: 5), onTimeout: () {
        return http.Response('Disconnected Error', 408);
      });

      bool success = response.statusCode == 200;

      ConnectionStatus.connected = success;

    } catch(e) {
      ConnectionStatus.connected = false;
    }
  }

}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);


  ApiConstants.loadRemoteAPI();

  runApp(const MyApp());

  //Regularly check the api connection

  Timer.periodic(ConnectionStatus.connectionInterval, (timer) {ConnectionStatus.checkConnection();});

  //Check connection immediately at startup to better inform users
  ConnectionStatus.checkConnection();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShamScout Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Theme.of(context).colorScheme.background,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        brightness: Brightness.dark
      ),
      home: BottomNavigation(),
    );
  }
}

class BottomNavigation extends StatefulWidget {

  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() =>
      BottomNavigationBarState();
}

class BottomNavigationBarState extends State<BottomNavigation>{

  String name = "Select a Name!";

  bool connection = false;
  bool wasConnected = false;

  int selectedIndex = 2;
  final pageViewController = PageController(initialPage: 2);


  @override
  void initState() {
    super.initState();
    loadName();

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        wasConnected = connection;
        connection = ConnectionStatus.connected;
      });
    });

    Timer.periodic(ConnectionStatus.connectionInterval, (timer) {
      setState(() {
        wasConnected = connection;
        connection = ConnectionStatus.connected;
      });
    });
  }

  Future<void> loadName() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString(PrefsConstants.namePref) != null ? prefs.getString(PrefsConstants.namePref) ?? "" : name;
    });
  }

  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static List<Widget> widgetOptions = <Widget>[
    Matches(),
    !PrefsConstants.editorMode ?
    Scan() : SearchWindow(),
    Home(),
    Schedule(),
    History(),
    Settings(),
  ];

  void onItemTapped(int index) {
    pageViewController.animateToPage(index, duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    pageViewController.dispose();
    super.dispose();
  }

  Future<void> backSaveForms(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    //Remove newline characters to avoid problems
    final parsedJson = jsonDecode(GameConfig.parseOutRatingJson(jsonEncode(jsonDecode(prefs.getString("game-config") ?? '{"name": "None", "year": 2023, "fields":[]}'))));

    final GameConfig loadedConfig = GameConfig.fromJson(parsedJson);

    if(mounted) {
      int numSaved = await loadedConfig.attemptUploadOfSubmittedForms(context);

      if(mounted && numSaved > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reconnected! Uploaded $numSaved matches to database")));
      }
    }

  }

  @override
  Widget build(BuildContext context) {

    //Reload the user's name
    loadName();

    if(connection && !wasConnected) {
      backSaveForms(context);

      setState(() {
        wasConnected = connection;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
              icon: Icon(
                connection ? Icons.cloud_done : Icons.cloud_off,
                color: connection ? Colors.green : Colors.red,
              ),
              tooltip: connection ? "API Connected" : "API Disconnected",
              onPressed: null,
          )
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PageView(
        controller: pageViewController,
        children: widgetOptions,
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label:'Matches',
          ),
          !PrefsConstants.editorMode ?
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label:'Scan',
          ) :
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label:'Scan',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label:'Search',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label:'Upcoming',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label:'Completed',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label:'Settings',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onBackground,
        unselectedLabelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        onTap: onItemTapped,
      ),
    );
  }
}