import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/FormItems.dart';
import 'package:sham_scout_mobile/MatchForm.dart';
import 'package:sham_scout_mobile/QRCodeDisplay.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => ScheduleState();

}

class ScheduleState extends State<Schedule> {
  List<ScheduleMatch> matches = [];
  List<ScheduleMatch> submittedMatches = [];

  List<String> teamNums = [];

  @override
  void initState() {
    super.initState();
    loadMatches();
  }

  Future<void> loadMatches() async{

      final prefs = await SharedPreferences.getInstance();

      //Load team nums in each match
      List<String> loadedNumbers = prefs.getString(PrefsConstants.matchSchedulePref)!.split(",");
      loadedNumbers.removeLast();

      List<ScheduleMatch> loaded = await GameConfig.loadUnplayedSchedule();

      //Copy the list to make the state update
      if(mounted) {
        setState(() {
          matches = loaded;
          teamNums = loadedNumbers;
        });
      }
  }

  @override
  Widget build(BuildContext context) {

    loadMatches();

    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: matches.isNotEmpty ? matches!.map((e) =>
                ScheduleItem(match: e, teamNum: teamNums[e.matchNum * 6 + e.station.index], onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MatchForm(
                        scheduleMatch:e,
                        redAlliance: e.getStation().toLowerCase().contains("red"),
                      ),
                    ),
                  );
                },)
              ,).toList()
                : [
                  Center(
                  child:Text("No Upcoming Matches!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
                )
              ]
          ),
        ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.,
    );
  }

}

class ScheduleItem extends StatelessWidget {
  final ScheduleMatch match;
  final Function onTap;
  final String teamNum;

  const ScheduleItem({required this.match, required this.onTap, required this.teamNum});

  static const TextStyle textStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);


  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    Color redColor = isDarkMode ? Colors.red[800]! : Colors.red[100]!;
    Color blueColor = isDarkMode ? Colors.blue[800]! : Colors.blue[100]!;


    return GestureDetector(
      child:Container(
        height: 50,
        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: match.station.redAlliance ? redColor : blueColor
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              match.getMatch(),
              style: textStyle,
            ),
            Text(
              teamNum,
              style: textStyle,
            ),
            Text(
              match.getStation(),
              style: textStyle,
            )
          ],
        ),
      ),
      onTap: () {
        onTap();
      },
    );
  }
}

class ScheduleMatch {
  final Station station;
  final int matchNum;
  int teamNum;

  ScheduleMatch(
    this.station,
    this.matchNum,
    [this.teamNum = -1]
  );

  bool equal(ScheduleMatch other) {
    return (
      other.station == station &&
      other.matchNum == matchNum
    );
  }

  String getStation() {return station.displayName;}
  String getMatch() {return "Quals ${matchNum+1}";}

  static ScheduleMatch fromCode(String code) {
    return ScheduleMatch(
        stationFromIndex(int.parse(code.substring(1, code.indexOf("m")))),
        int.parse(code.substring(code.indexOf("m")+1))
    );
  }

  static ScheduleMatch fromSavedFile(String fileName) {
    //TODO: since station isn't in file name...
    RegExp exp = RegExp(r'm([0-9]+)s([0-9])-([0-9]+)');
    RegExpMatch? match = exp.firstMatch(fileName);

    return ScheduleMatch(stationFromIndex(int.parse(match![2]!)), int.parse(match![1]!)-1, int.parse(match![3]!));
  }

  static Station stationFromIndex(int index) {
    switch(index) {
      case 0: return Station.Red1;
      case 1: return Station.Red2;
      case 2: return Station.Red3;
      case 3: return Station.Blue1;
      case 4: return Station.Blue2;
      case 5: return Station.Blue3;
      default: return Station.Red1;
    }
  }

}

enum Station {
  Red1(displayName:"Red 1", redAlliance: true),
  Red2(displayName:"Red 2", redAlliance: true),
  Red3(displayName:"Red 3", redAlliance: true),
  Blue1(displayName:"Blue 1", redAlliance: false),
  Blue2(displayName:"Blue 2", redAlliance: false),
  Blue3(displayName:"Blue 3", redAlliance: false);

  const Station({
    required this.displayName,
    required this.redAlliance
  });

  final String displayName;
  final bool redAlliance;
}