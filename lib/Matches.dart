import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/MatchForm.dart';
import 'package:sham_scout_mobile/Schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Matches extends StatefulWidget {

  const Matches({super.key});

  @override
  State<StatefulWidget> createState() => MatchesState();

}

class MatchesState extends State<Matches> {

  List<Match> matchSchedule = [];

  @override
  void initState() {
    loadMatchSchedule();
    super.initState();
  }

  Future<void> loadMatchSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String matchScheduleCode = prefs.getString("match-schedule")!;

    setState(() {
      matchSchedule = Match.parseCode(matchScheduleCode);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(
              children:
                matchSchedule.map((e) =>
                  Container(
                      // padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                      ),
                    child:Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text((matchSchedule.indexOf(e)+1).toString()),
                              ],
                            )
                        ),
                        Expanded(
                            flex: 9,
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      color: Colors.red[100]
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                    children: [
                                      TeamLink(matchIndex: matchSchedule.indexOf(e), station: Station.Red1, team: e.red1),
                                      TeamLink(matchIndex: matchSchedule.indexOf(e), station: Station.Red2, team: e.red2),
                                      TeamLink(matchIndex: matchSchedule.indexOf(e), station: Station.Red3, team: e.red3),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      color: Colors.blue[100]
                                  ),
                                  child:Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TeamLink(matchIndex: matchSchedule.indexOf(e), station: Station.Blue1, team: e.blue1),
                                      TeamLink(matchIndex: matchSchedule.indexOf(e), station: Station.Blue2, team: e.blue2),
                                      TeamLink(matchIndex: matchSchedule.indexOf(e), station: Station.Blue3, team: e.blue3),
                                    ],
                                  ),
                                )
                              ],
                            )
                        )
                      ],
                    ),
                  ),
                ).toList(),
            )
        )
    );
  }

}

class TeamLink extends StatelessWidget{

  final int matchIndex;
  final Station station;
  final String team;

  const TeamLink({super.key, required this.matchIndex, required this.station, required this.team});

  //TODO: not always red alliance..?
  @override
  Widget build(BuildContext context) {
    return TextButton(child: Text(team), onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MatchForm(
            scheduleMatch:ScheduleMatch(station, matchIndex),
            redAlliance: station.index < 3,
          ),
        ),
      );
    });
  }

}

class Match {

  final String red1;
  final String red2;
  final String red3;
  final String blue1;
  final String blue2;
  final String blue3;

  Match({
    required this.red1,
    required this.red2,
    required this.red3,
    required this.blue1,
    required this.blue2,
    required this.blue3,
  });

  static List<Match> parseCode(String input) {
    List<Match> matches = [];

    List<String> splitResult = input.split(",");

    splitResult.removeLast();

    print(splitResult);
    print(splitResult.length);

    for(int i = 0; i < splitResult.length; i+=6) {
      matches.add(Match(
        red1: splitResult[i],
        red2: splitResult[i+1],
        red3: splitResult[i+2],
        blue1: splitResult[i+3],
        blue2: splitResult[i+4],
        blue3: splitResult[i+5],
      ));
    }

    return matches;
  }
}