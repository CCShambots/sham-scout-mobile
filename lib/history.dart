import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/formItems.dart';
import 'package:sham_scout_mobile/matchForm.dart';
import 'package:sham_scout_mobile/QRCodeDisplay.dart';
import 'package:sham_scout_mobile/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class History extends StatefulWidget {

  const History({super.key});

  @override
  State<StatefulWidget> createState() => HistoryState();

}

class HistoryState extends State<History> {

  List<ScheduleMatch> submittedMatches = [];

  @override
  void initState() {
    loadSubmittedMatches();
    super.initState();
  }

  Future<void> loadSubmittedMatches() async {
    List<String> fileNames = await GameConfig.loadSubmittedForms();
    setState(() {
      submittedMatches = fileNames.map((e) => ScheduleMatch.fromSavedFile(e)).toList();
      submittedMatches.sort((e1, e2) => e2.matchNum-e1.matchNum);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: submittedMatches.isNotEmpty ? SingleChildScrollView(
            child: Column(
              children: submittedMatches.map((e) =>
                  ScheduleItem(match: e, teamNum: e.teamNum.toString(), onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MatchForm(
                          scheduleMatch:e,
                          redAlliance: e.getStation().toLowerCase().contains("red"),
                        ),
                      ),
                    );
                  },)
              ).toList()
            )
        ):
          Center(
            child:Text("No Completed Matches Yet!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          //Only Show QR Codes if there are matches to show
          if(submittedMatches.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => QRCodeDisplay()
              ),
            );
          }
        },
        tooltip: "Create QR Codes",
        child: const Icon(Icons.qr_code),
      ),
    );
  }

}