
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

  String currentEvent = "";

  String templates = "";
  List<Shift> shifts = [];

  String name = "Harrison";

  @override
  void initState() {
    loadVariables();
    super.initState();
  }

  Future<void> loadVariables() async{
    final prefs = await SharedPreferences.getInstance();

    String currentKey = prefs.getString('current-event')!;
    String loadedName = prefs.getString("name")!;

    getShifts(currentKey);

    setState(() {
      //Load the current event
        currentEvent = currentKey;
        name = loadedName;
    });
  }

  Future<void> saveEventKey(String value) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("current-event", value);
    getShifts(value);

    setState(() {
      currentEvent = value;
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

    prefs.setString("name", scouter);

    String code = Shift.generateCode(scouter, shifts);
    print(code);

    HandleCode.handleQRCode(code);


    setState(() {
      name = scouter;
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
            children: [
            //TODO: Make this not scuffed/autocomplete/explained
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter event key"
                  ),
                  onSubmitted: (String? value) {
                    saveEventKey(value!);
                  },
                  controller: TextEditingController()..text = currentEvent,
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
                children: [
                  Flexible(
                      child: Text(templates, style: TextStyle(),)
                  )
                ],
              ),
            ],
          )
        )
    );
  }

}