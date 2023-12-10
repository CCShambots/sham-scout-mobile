import 'dart:math';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sham_scout_mobile/formItems.dart';
import 'package:sham_scout_mobile/matchForm.dart';
import 'package:sham_scout_mobile/schedule.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();

}

class HomeState extends State<Home> {

  int matchesToGo = -1;
  int matchesDone = -1;

  ScheduleMatch? nextMatch;

  @override
  void initState() {
    loadNextUpMatch();
    super.initState();
  }
  
  Future<void> loadNextUpMatch() async{

    final prefs = await SharedPreferences.getInstance();

    //Load team nums in each match
    List<String> loadedNumbers = (prefs.getString(PrefsConstants.matchSchedulePref) ?? "").split(",");

    if(loadedNumbers.isNotEmpty) {
      loadedNumbers.removeLast();

      List<ScheduleMatch> loaded = await GameConfig.loadUnplayedSchedule();

      List<String> finishedMatches = await GameConfig.loadSubmittedForms();

      ScheduleMatch? firstMatch = loaded.firstOrNull;
      firstMatch?.teamNum = int.parse(loadedNumbers[firstMatch.matchNum * 6 + firstMatch.station.index]);

      //Copy the list to make the state update
      setState(() {
        nextMatch = firstMatch;
        matchesToGo = loaded.isNotEmpty ? loaded.length : -1;
        matchesDone = finishedMatches.isNotEmpty ? finishedMatches.length : -1;
      });
    }
  }


  @override
  Widget build(BuildContext context) {

    loadNextUpMatch();

    TextStyle bigText = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
    TextStyle statisticsText = TextStyle(fontWeight: FontWeight.bold, fontSize: 48);

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Next Match:", style: bigText,),
                ],
              ),
              nextMatch != null ? ScheduleItem(nextMatch!, () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MatchForm(
                      scheduleMatch:nextMatch!,
                      redAlliance: nextMatch!.getStation().toLowerCase().contains("red"),
                    ),
                  ),
                ).then((value) => {
                    loadNextUpMatch()
                });
              },nextMatch!.teamNum.toString(),) : Text("No upcoming matches!", style: bigText,),
            ],
          ),
          matchesDone != -1 ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("$matchesDone", style: statisticsText)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Done", style: bigText,)
                    ],
                  )]
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("$matchesToGo", style: statisticsText)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("To Go", style: bigText,)
                    ],
                  ),

                ],
              )
            ],
          ) : Container(),
          matchesDone != -1 ? CircularPercentIndicator(
            radius: 100,
            lineWidth: 13.0,
            animation: true,
            percent: matchesDone / (matchesToGo + matchesDone),
            center: Text(
              "${(matchesDone / (matchesToGo + matchesDone) * 100).round()}%",
              style: statisticsText
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Theme.of(context).colorScheme.inversePrimary,
          ) : Container()
        ],
      )
    );
  }

}