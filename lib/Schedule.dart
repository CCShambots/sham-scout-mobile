import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/MatchForm.dart';
import 'package:sham_scout_mobile/QRCodeDisplay.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => ScheduleState();

}

class ScheduleState extends State<Schedule> {
  List<ScheduleMatch> matches = [];

  @override
  void initState() {
    super.initState();
    loadMatches();
  }

  Future<void> loadMatches() async{
      final prefs = await SharedPreferences.getInstance();

      //Make sure we don't double load matches
      matches.clear();

      matches.addAll(prefs.getStringList('schedule')!.map((e) => ScheduleMatch.fromCode(e)));


      //Copy the list to make the state update
      setState(() {
        matches = [...matches];
      });
  }

  static const TextStyle textStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {

    loadMatches();

    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: matches!.map((e) =>
                GestureDetector(
                  child:Container(
                    height: 50,
                    padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: e.station.redAlliance ? Colors.red[100] : Colors.blue[100]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          e.getMatch(),
                          style: textStyle,
                        ),
                        Text(
                            "Team num yay"
                        ),
                        Text(
                          e.getStation(),
                          style: textStyle,
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MatchForm(
                          scheduleMatch:e,
                          redAlliance: e.getStation().toLowerCase().contains("red"),
                        ),
                      ),
                    );
                  },
                )
              ,).toList()
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QRCodeDisplay()
            ),
          );
        },
        tooltip: "Create QR Codes",
        child: const Icon(Icons.qr_code),
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.,
    );
  }

}

class ScheduleMatch {
  final Station station;
  final int matchNum;

  const ScheduleMatch({
    required this.station,
    required this.matchNum
  });

  String getStation() {return station.displayName;}
  String getMatch() {return "Quals ${matchNum+1}";}

  static ScheduleMatch fromCode(String code) {
    return ScheduleMatch(
        station: stationFromindex(int.parse(code.substring(1, code.indexOf("m")))),
        matchNum: int.parse(code.substring(code.indexOf("m")+1))
    );
  }

  static Station stationFromindex(int index) {
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