import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/FormItems.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchForm extends StatefulWidget {
  final String matchInfo;
  final bool redAlliance;

  const MatchForm({Key? key, required this.matchInfo, required this.redAlliance}): super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.redAlliance ? Colors.red[400] : Colors.blue[400],
        leading: BackButton(onPressed: () => Navigator.of(context).pop(),),
        title: Text(widget.matchInfo),
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
        onPressed: () {},
        tooltip: 'Save',
        child: const Icon(Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

}