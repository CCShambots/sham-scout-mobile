import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sham_scout_mobile/formItems.dart';
import 'package:sham_scout_mobile/home.dart';
import 'package:sham_scout_mobile/schedule.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class MatchForm extends StatefulWidget {
  final bool redAlliance;
  final ScheduleMatch scheduleMatch;

  const MatchForm({Key? key, required this.scheduleMatch, required this.redAlliance}): super(key: key);

  @override
  State<MatchForm> createState() => MatchFormState();

}

class MatchFormState extends State<MatchForm> {

  GameConfig config = GameConfig(title: "none", year: 2023, items: []);
  String team = "0";
  String year = "0";

  bool loadedValues = false;

  bool haveChangedSomething = false;

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    //Remove newline characters to avoid problems
    final parsedJson = jsonDecode(GameConfig.parseOutRatingJson(jsonEncode(jsonDecode(prefs.getString("game-config")!))));

    print(parsedJson);

    final GameConfig loadedConfig = GameConfig.fromJson(parsedJson);

    List<String> loadedNumbers = prefs.getString(PrefsConstants.matchSchedulePref)!.split(",");
    loadedNumbers.removeLast();

    String outputTeamNum = loadedNumbers![widget.scheduleMatch.matchNum * 6 + widget.scheduleMatch.station.index];

    //Load in saved values and place them on the form
    loadedConfig.loadSavedValues(widget.scheduleMatch.matchNum, int.parse(outputTeamNum));

    setState(() {
      config = loadedConfig;
      team = outputTeamNum;
      year = prefs.getString(PrefsConstants.currentYearPref)!;

    });
  }

  Widget buildImagePopup(BuildContext context) {
    return AlertDialog(
      title: Text("$team's Robot"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
              ),
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0)
                ),
                child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: "${ApiConstants.baseUrl}${ApiConstants.bytesUrl}$team-img-$year"
                ),
              )
            ],
          )
        ]
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    Color redColor = isDarkMode ? Colors.red[800]! : Colors.red[100]!;
    Color blueColor = isDarkMode ? Colors.blue[800]! : Colors.blue[100]!;

    Color redHeader = isDarkMode ? Colors.red[900]! : Colors.red[400]!;
    Color blueHeader = isDarkMode ? Colors.blue[900]! : Colors.blue[400]!;


    return WillPopScope(
      onWillPop: () async {
        if(haveChangedSomething) {
          openModal(context);
          return false;
        } else {
          return true;
        }
      },
        child: GestureDetector(
          onTap: () => {
            setState(() {
              haveChangedSomething = true;
            })
          },
          child: Scaffold(
              appBar: AppBar(
                backgroundColor: widget.redAlliance ? redHeader : blueHeader,
                leading: BackButton(onPressed: () => openModal(context)),
                title: Text("${widget.scheduleMatch.getMatch()} - $team - ${widget.scheduleMatch.getStation()}"),
                actions: [
                  IconButton(
                      icon: Icon(Icons.question_mark),
                      onPressed: () {
                        showDialog(context: context, builder: buildImagePopup);
                      },
                  )
                ],
              ),
              body: Scaffold(
                backgroundColor: widget.redAlliance ? redColor : blueColor,
                body: SingleChildScrollView(
                    child: Column(
                      children: [...config.items.map((e) =>
                      e.widget
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("--- END OF FORM ---", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
                      )
                      ],
                    )
                ),

              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  config.saveMatchFromUI(
                      widget.scheduleMatch.station.index,
                      widget.scheduleMatch.matchNum,
                      int.parse(team),
                      widget.scheduleMatch.id
                  )
                      .then((value) => Navigator.of(context).pop());
                  },
                tooltip: 'Save',
                child: const Icon(Icons.save),
              ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        )
        )
    );

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