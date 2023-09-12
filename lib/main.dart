import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const tenSec = Duration(seconds: 10);

  static checkConnection() async{
    var url = Uri.parse(ApiConstants.statusEndpoint);

    try {
      var response = await http.get(url).timeout(const Duration(seconds: 5), onTimeout: () {
        return http.Response('Disconnected Error', 408);
      });

      ConnectionStatus.connected = response.statusCode == 200;

    } catch(e) {
      ConnectionStatus.connected = false;
    }
  }

}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  runApp(const MyApp());

  //Regularly check the api connection

  Timer.periodic(ConnectionStatus.tenSec, (timer) {ConnectionStatus.checkConnection();});

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

  String name = "Welcome!";

  bool connection = false;

  int selectedIndex = 2;
  final pageViewController = PageController(initialPage: 2);


  @override
  void initState() {
    super.initState();
    loadName();

    Timer.periodic(ConnectionStatus.tenSec, (timer) {
      setState(() {
        connection = ConnectionStatus.connected;
      });
    });
  }

  Future<void> loadName() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString(PrefsConstants.namePref) != null ? 'Welcome, ${prefs.getString(PrefsConstants.namePref) ?? ""}!' : "Welcome!";
    });
  }

  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> widgetOptions = <Widget>[
    Matches(),
    Scan(),
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

  @override
  Widget build(BuildContext context) {

    //Reload the user's name
    loadName();

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
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label:'Scan',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label:'Home',
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