import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/History.dart';
import 'package:sham_scout_mobile/Home.dart';
import 'package:sham_scout_mobile/Matches.dart';
import 'package:sham_scout_mobile/Schedule.dart';
import 'package:sham_scout_mobile/Scan.dart';
import 'package:sham_scout_mobile/Settings.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
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

  int selectedIndex = 2;
  String name = "Welcome!";

  bool connection = false;

  final pageViewController = PageController(initialPage: 2);


  @override
  void initState() {
    super.initState();
    loadName();
    checkAPIConnection();
  }

  Future<void> loadName() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString(PrefsConstants.namePref) != null ? 'Welcome, ${prefs.getString(PrefsConstants.namePref) ?? ""}!' : "Welcome!";
    });
  }

  Future<void> checkAPIConnection() async {

    var url = Uri.parse(ApiConstants.statusEndpoint);

    try {
      var response = await http.get(url);

      setState(() {
        connection = response.statusCode == 200;
      });

    } catch(e) {
      setState(() {
        connection = false;
      });
    }
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
              onPressed: checkAPIConnection,
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
              backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label:'Scan',
              backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label:'Home',
              backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label:'Upcoming',
              backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label:'Completed',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label:'Settings',
              backgroundColor: Colors.black,
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
        unselectedItemColor: Theme.of(context).colorScheme.background,
        onTap: onItemTapped,
      ),
    );
  }
}