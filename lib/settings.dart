
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/handleCode.dart';
import 'package:sham_scout_mobile/shift.dart';
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
  List<String> templates = [];

  TextEditingController eventKeyController = TextEditingController();
  TextEditingController tbaKeyController = TextEditingController();

  String name = "NONE";

  String template = "";

  String tbaKey = "";

  @override
  void initState() {
    loadVariables();
    super.initState();
  }

  Future<void> loadVariables() async{
    final prefs = await SharedPreferences.getInstance();

    String currentKey = prefs.getString(PrefsConstants.currentEventPref) ?? "none";
    String loadedName = prefs.getString(PrefsConstants.namePref) ?? "NONE";
    bool override = prefs.getBool(PrefsConstants.overrideCurrentEventPref) ?? true;
    String tba = prefs.getString(PrefsConstants.tbaPref) ?? "";

    String configName = prefs.getString(PrefsConstants.activeConfigNamePref) ?? "";

    eventKeyController.text = currentKey;
    tbaKeyController.text = tba;

    getShifts(currentKey);

    getTemplates();

    setState(() {
      //Load the current event
        currentEventKey = currentKey;
        name = loadedName;
        eventKeyOverride = override;
        tbaKey = tba;
        template = configName;
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
      var url = Uri.parse("${ApiConstants.baseUrl}/schedules/get/event/$eventKey");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          shifts = List.from(jsonDecode(response.body)["shifts"]).map((e) => Shift.fromJson(e)).toList();
          if(name == "NONE") {
            name = shifts[0].scouter;
          }
        });
      }
    } catch (e) {
      log(e.toString());
    }

  }

  Future<void> getTemplates() async {
    try {
      var url = Uri.parse("${ApiConstants.baseUrl}/templates/get");

      var response=  await http.get(url);

      if(response.statusCode == 200) {

        var json = jsonDecode(response.body) as List<dynamic>;

        List<String> thisTemplates = json.whereType<String>().toList();
        if(!thisTemplates.contains(template)) {
          setState(() {
            template = thisTemplates[0];
          });
        }

        setState(() {
          templates = thisTemplates;
        });
      }

    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> setScouter(String scouter) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(PrefsConstants.namePref, scouter);

    String code = Shift.generateCode(scouter, shifts);

    HandleCode.handleQRCode(code);

    setState(() {
      name = scouter;
    });
  }

  Future<void> setGameConfig(String configName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var url = Uri.parse("${ApiConstants.baseUrl}/templates/get/name/$configName");

    var response =  await http.get(url);

    prefs.setString(PrefsConstants.activeConfigPref, response.body);
    prefs.setString(PrefsConstants.activeConfigNamePref, configName);

    setState(() {
      template = configName;
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

    var result = List.from(jsonDecode(response.body))
        .where((element) => element["key"].indexOf("_qm") != -1)
        .toList();

    int sortMatchNum(e1, e2) {
      String e1Key = e1["key"];
      var e2Key = e2["key"];

      int e1Num = int.parse(e1Key.substring(e1Key.indexOf("_qm")+3));
      int e2Num = int.parse(e2Key.substring(e1Key.indexOf("_qm")+3));

      return e1Num-e2Num;
    }

    result.sort(sortMatchNum);

    for (var element in result) {
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

        }

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
                    items: shifts.isNotEmpty ? shifts.map((e) => e.scouter).toSet().toList().map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList() : [DropdownMenuItem(value: name, child: Text("FAIL"))],
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
                  ) : Text(tbaKey == "" ? "TBA Key not set! Talk to the Scouting Manager" : "TBA Key Set!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
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
              ),
              PrefsConstants.editorMode ?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("Select Game Config"),
                  DropdownButton<String>(
                    value: template,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onChanged: (String? value) {
                      setGameConfig(value!);
                    },
                    items: templates.map<DropdownMenuItem<String>>((String value) {
                      print("evaluating: $value");
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                  )
                ],
              ) : Container(),
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