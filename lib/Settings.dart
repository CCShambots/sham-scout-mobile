
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

  TextEditingController controller = TextEditingController();

  String name = "Harrison";

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

    controller.text = currentKey;

    getShifts(currentKey);

    setState(() {
      //Load the current event
        currentEventKey = currentKey;
        name = loadedName;
        eventKeyOverride = override;
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

  Future<void> syncMatchSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    //TODO: Make this happen

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
                  controller: controller,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                      onPressed: syncMatchSchedule,
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
                    controller.text = currentEventKey;
                  },
                  child: const Text('Cancel')
              ),
            ]
        ));
  }

}