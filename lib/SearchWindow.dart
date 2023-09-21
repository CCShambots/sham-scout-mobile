
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:sham_scout_mobile/formItems.dart';
import 'package:sham_scout_mobile/matchForm.dart';
import 'package:http/http.dart' as http;
import 'package:sham_scout_mobile/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SearchWindow extends StatefulWidget {
  const SearchWindow({super.key});

  @override
  State<StatefulWidget> createState() => SearchWindowState();


}

class SearchWindowState extends State<SearchWindow> {

  String val = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextField(
          decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter Form ID"
          ),
          onSubmitted: (value) async {
            print(value);

            SharedPreferences prefs = await SharedPreferences.getInstance();

            String configName = prefs.getString(PrefsConstants.activeConfigNamePref) ?? "";

            print(configName);

            Uri targetUri = Uri.parse("${ApiConstants.baseUrl}/forms/get/template/$configName/id/$value");
            print(targetUri.toString());
            http.Response response = await http.get(targetUri);

            print("RESPONSE: ${response.body}");

            List<dynamic> resultJson = jsonDecode(response.body);
            Map<String, dynamic> json = resultJson[0];

            int matchNum = json["match_number"];
            int teamNum = json["team"];


            List<String> schedule = (prefs.getString(PrefsConstants.matchSchedulePref) ?? "").split(",");

            int startIndex = (matchNum-1) * 6;
            int stationIndex = schedule.sublist(startIndex, startIndex + 6).indexOf(teamNum.toString());

            Station station = ScheduleMatch.stationFromIndex(stationIndex);

            File fileToSave = await GameConfig.generateFile(stationIndex, matchNum, teamNum);

            print(fileToSave.path);

            json.addAll({"id": value});

            fileToSave.writeAsStringSync(jsonEncode(json));

            if(mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MatchForm(
                    scheduleMatch:ScheduleMatch(station, matchNum-1),
                    redAlliance: station.index < 3,
                  ),
                ),
              );
            }
          },
        )
      )
    );
  }

}