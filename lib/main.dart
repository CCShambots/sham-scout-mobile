import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/History.dart';
import 'package:sham_scout_mobile/Home.dart';
import 'package:sham_scout_mobile/Matches.dart';
import 'package:sham_scout_mobile/Schedule.dart';
import 'package:sham_scout_mobile/Scan.dart';
import 'package:sham_scout_mobile/Settings.dart';
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

  final pageViewController = PageController(initialPage: 2);


  @override
  void initState() {
    super.initState();
    loadName();
  }

  Future<void> loadName() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString('name') != null ? 'Welcome, ${prefs.getString('name') ?? ""}!' : "Welcome!";
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
        items: const <BottomNavigationBarItem>[
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