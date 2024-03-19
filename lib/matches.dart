import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/pages/matchForm.dart';
import 'package:sham_scout_mobile/pages/schedule.dart';
import 'package:sham_scout_mobile/constants.dart';
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

    String matchScheduleCode = prefs.getString(PrefsConstants.matchSchedulePref)!;

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

    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    Color redColor = isDarkMode ? Colors.red[800]! : Colors.red[100]!;
    Color blueColor = isDarkMode ? Colors.blue[800]! : Colors.blue[100]!;

    return Scaffold(
        body: matchSchedule.isNotEmpty ?
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height, // or any other desired height
              ),
              child: ListView.builder(
                itemCount: matchSchedule.length,
                itemBuilder: (context, index) {
                  var e = matchSchedule[index];
                  return Container(
                      margin: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Theme
                              .of(context)
                              .cardColor,
                          borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceAround,
                                children: [
                                  Text((matchSchedule.indexOf(e) + 1)
                                      .toString()),
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
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10)
                                        ),
                                        color: redColor
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween,

                                      children: [
                                        TeamLink(
                                            matchIndex: matchSchedule.indexOf(
                                                e),
                                            station: Station.Red1,
                                            team: e.red1),
                                        TeamLink(
                                            matchIndex: matchSchedule.indexOf(
                                                e),
                                            station: Station.Red2,
                                            team: e.red2),
                                        TeamLink(
                                            matchIndex: matchSchedule.indexOf(
                                                e),
                                            station: Station.Red3,
                                            team: e.red3),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            bottomRight: Radius.circular(10),
                                            bottomLeft: Radius.circular(10)
                                        ),
                                        color: blueColor
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        TeamLink(
                                            matchIndex: matchSchedule.indexOf(
                                                e),
                                            station: Station.Blue1,
                                            team: e.blue1),
                                        TeamLink(
                                            matchIndex: matchSchedule.indexOf(
                                                e),
                                            station: Station.Blue2,
                                            team: e.blue2),
                                        TeamLink(
                                            matchIndex: matchSchedule.indexOf(
                                                e),
                                            station: Station.Blue3,
                                            team: e.blue3),
                                      ],
                                    ),
                                  )
                                ],
                              )
                          )
                        ],
                      )
                  );
                }
              )
        ) :
        Center(
          child: Text("No Match Schedule Found!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),)
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

    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return TextButton(
        child: Text(team,
        style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
      ),
      onPressed: () {
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