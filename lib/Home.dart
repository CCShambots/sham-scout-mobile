
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();

}

class HomeState extends State<Home> {

  int totalMatches = 0;
  int matchesScouted = 0;

  String templates = "";

  @override
  void initState() {
    loadPrefs();
    getUsers();
    super.initState();
  }

  Future<void> getUsers() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.templatesEndpoint);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          templates = response.body;
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> loadPrefs() async{
    final prefs = SharedPreferences.getInstance();


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              Text("howdy there"),
            ],
          ),
          Row(
            children: [
              Text(templates)
            ],
          )
        ],
      )
    );
  }

}