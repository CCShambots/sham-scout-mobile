
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();

}

class HomeState extends State<Home> {

  int totalMatches = 0;
  int matchesScouted = 0;

  @override
  void initState() {
    loadPrefs();
    super.initState();
  }

  Future<void> loadPrefs() async{
    final prefs = SharedPreferences.getInstance();


  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("howdy there"),
    );
  }

}