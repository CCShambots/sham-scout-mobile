import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/FormItems.dart';
import 'package:sham_scout_mobile/Schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchForm extends StatefulWidget {
  final bool redAlliance;
  final ScheduleMatch scheduleMatch;

  const MatchForm({Key? key, required this.scheduleMatch, required this.redAlliance}): super(key: key);

  @override
  State<MatchForm> createState() => MatchFormState();

}

class MatchFormState extends State<MatchForm> {

  GameConfig config = GameConfig(title: "none", year: 2023, items: []);

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final parsedJson = jsonDecode(prefs.getString('game-config') ?? "");

    final GameConfig loadedConfig = GameConfig.fromJson(parsedJson);

    setState(() {
      config = loadedConfig;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        openModal(context);
        return false;
      },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: widget.redAlliance ? Colors.red[400] : Colors.blue[400],
            leading: BackButton(onPressed: () => openModal(context)),
            title: Text("${widget.scheduleMatch.getMatch()} - ${widget.scheduleMatch.getStation()}"),
          ),
          body: Scaffold(
            backgroundColor: widget.redAlliance ? Colors.red[100] : Colors.blue[100],
            body: SingleChildScrollView(
                child: Column(
                  children: config.items.map((e) =>
                  e.widget
                  ).toList(),
                )
            ),

          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              config.saveMatchForm(widget.scheduleMatch.station.index, widget.scheduleMatch.matchNum, 5907)
                  .then((value) => Navigator.of(context).pop());
              },
            tooltip: 'Save',
            child: const Icon(Icons.save),
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    ));

  }

  void openModal(BuildContext context) {
    showDialog(context: context, builder: (BuildContext context) =>
        AlertDialog(
            content: Text("Do you want to discard your changes?"),
            actions: <TextButton>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel')
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Discard')
              )
            ]
        ));
  }

}