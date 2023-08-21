
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/FormItems.dart';
import 'package:sham_scout_mobile/MatchForm.dart';
import 'package:sham_scout_mobile/Schedule.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();

}

class HomeState extends State<Home> {

  int matchesToGo = 0;

  String templates = "";

  ScheduleMatch? nextMatch;

  @override
  void initState() {
    getUsers();
    loadNextUpMatch();
    super.initState();
  }

  //TODO: Make this work after you submit :)

  Future<void> loadNextUpMatch() async{

    final prefs = await SharedPreferences.getInstance();

    //Load team nums in each match
    List<String> loadedNumbers = prefs.getString("match-schedule")!.split(",");
    loadedNumbers.removeLast();

    List<ScheduleMatch> loaded = await GameConfig.loadUnplayedSchedule();

    ScheduleMatch? firstMatch = loaded.firstOrNull;
    firstMatch?.teamNum = int.parse(loadedNumbers[firstMatch.matchNum * 6 + firstMatch.station.index]);

    //Copy the list to make the state update
    setState(() {
      nextMatch = firstMatch;
      matchesToGo = loaded.length;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Next Match:"),
            ],
          ),
          nextMatch != null ? ScheduleItem(match: nextMatch!, teamNum: nextMatch!.teamNum.toString(), onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MatchForm(
                  scheduleMatch:nextMatch!,
                  redAlliance: nextMatch!.getStation().toLowerCase().contains("red"),
                ),
              ),
            );
          }) : Text("No upcoming matches!"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$matchesToGo")
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Matches to go!")
            ],
          )
        ],
      )
    );
  }

}