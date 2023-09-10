
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/HandleCode.dart';
import 'package:sham_scout_mobile/Shift.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Settings extends StatefulWidget {

  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => SettingsState();

}

class SettingsState extends State<Settings> {

  String currentEventKey = "";
  bool eventKeyOverride = true;

  List<Shift> shifts = [];

  TextEditingController eventKeyController = TextEditingController();
  TextEditingController tbaKeyController = TextEditingController();

  String name = "";

  String tbaKey = "";

  @override
  void initState() {
    loadVariables();
    super.initState();
  }

  Future<void> loadVariables() async{
    final prefs = await SharedPreferences.getInstance();

    String currentKey = prefs.getString(PrefsConstants.currentEventPref)!;
    String loadedName = prefs.getString(PrefsConstants.namePref)!;
    bool override = prefs.getBool(PrefsConstants.overrideCurrentEventPref) ?? true;
    String tba = prefs.getString(PrefsConstants.tbaPref) ?? "";

    eventKeyController.text = currentKey;
    tbaKeyController.text = tba;

    getShifts(currentKey);

    setState(() {
      //Load the current event
        currentEventKey = currentKey;
        name = loadedName;
        eventKeyOverride = override;
        tbaKey = tba;
    });
  }

  Future<void> saveEventKey(String value) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(PrefsConstants.currentEventPref, value);
    getShifts(value);

    setState(() {
      currentEventKey = value;
    });

  }

  Future<void> setEventKeyOverride(bool val) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setBool(PrefsConstants.overrideCurrentEventPref, val);

    setState(() {
      eventKeyOverride = val;
    });
  }

  Future<void> getShifts(String eventKey) async {
    try {
      var url = Uri.parse("${ApiConstants.baseUrl}/schedules/$eventKey");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          shifts = List.from(jsonDecode(response.body)["shifts"]).map((e) => Shift.fromJson(e)).toList();
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> setScouter(String scouter) async {

    print(scouter);

    final prefs = await SharedPreferences.getInstance();

    prefs.setString(PrefsConstants.namePref, scouter);

    String code = Shift.generateCode(scouter, shifts);
    print(code);

    HandleCode.handleQRCode(code);


    setState(() {
      name = scouter;
    });
  }

  Future<void> saveTBAKey() async {
    final prefs = await SharedPreferences.getInstance();

    String val = tbaKeyController.text;

    prefs.setString(PrefsConstants.tbaPref, val);

    setState(() {
      tbaKey = val;
    });
  }

  static Future<void> syncMatchSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    String eventKey = prefs.getString(PrefsConstants.currentEventPref)!;
    String tbaKey = prefs.getString(PrefsConstants.tbaPref)!;

    var url = Uri.parse("${ApiConstants.tbaBaseUrl}/event/$eventKey/matches/simple");

    Map<String, String> headers = {"X-TBA-Auth-Key": tbaKey};

    var response = await http.get(url, headers: headers);
    
    String schedule = "";

    List.from(jsonDecode(response.body))
        .where((element) => element["key"].indexOf("_qm") != -1)
        .forEach((element) { 
          List<dynamic> redAllianceKeys = element["alliances"]["red"]["team_keys"];
          List<dynamic> blueAllianceKeys = element["alliances"]["blue"]["team_keys"];
          
          List<String> redAllianceNumbers = redAllianceKeys.map((e) => (e as String).substring(3)).toList();
          List<String> blueAllianceNumbers = blueAllianceKeys.map((e) => (e as String).substring(3)).toList();
          
          for (var element in redAllianceNumbers) {
            schedule = "$schedule$element,";
          }

          for (var element in blueAllianceNumbers) {
            schedule = "$schedule$element,";
          }

        });

        schedule = schedule.substring(0, schedule.length);

        prefs.setString(PrefsConstants.matchSchedulePref, schedule);

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
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter event key"
                  ),
                  onSubmitted: (String? value) {

                    if(value != currentEventKey) {
                      if(eventKeyOverride) {
                        saveEventKey(value!);
                      } else {
                        openModal(context, value!);
                      }
                    }
                  },
                  controller: eventKeyController,
                )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("Select Name"),
                  DropdownButton<String>(
                    value: name,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onChanged: (String? value) {
                      setScouter(value!);
                    },
                    items: shifts.map((e) => e.scouter).toSet().toList().map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                  )
                ],
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: PrefsConstants.editorMode ? TextField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter TBA Key"
                    ),
                    onSubmitted: (String? value) {
                      saveTBAKey();
                    },
                    controller: tbaKeyController,
                  ) : Text("TBA Key not set! Talk to the Scouting Manager", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                      onPressed: tbaKey != "" ? syncMatchSchedule : null,
                      icon: Icon(
                        Icons.sync,
                      ),
                      label: const Text("Sync Match Schedule")
                  )
                ],
              )
            ],
          )
        )
    );
  }

  void openModal(BuildContext context, String value) {
    showDialog(context: context, builder: (BuildContext context) =>
        AlertDialog(
            title: Text("Wait!"),
            content: Text("You scanned the event key via QR Code. Unless you know what you're doing, changing this could break all your submitted data!"),
            actions: <TextButton>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    saveEventKey(value);
                    setEventKeyOverride(true);
                  },
                  child: const Text('Apply')
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    eventKeyController.text = currentEventKey;
                  },
                  child: const Text('Cancel')
              ),
            ]
        ));
  }

}