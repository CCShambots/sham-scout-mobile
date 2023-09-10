import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sham_scout_mobile/Schedule.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GameConfig {

  GameConfig({
    required this.title,
    required this.year,
    required this.items,
  });

  static Future<List<ScheduleMatch>> loadUnplayedSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    List<ScheduleMatch> matches = prefs.getStringList(PrefsConstants.schedulePref)!.map((e) => ScheduleMatch.fromCode(e)).toList();

    List<String> fileNames = await GameConfig.loadSubmittedForms();
    List<ScheduleMatch> submittedMatches = fileNames.map((e) => ScheduleMatch.fromSavedFile(e)).toList();

    matches.removeWhere((element) => submittedMatches.where((submitted) => submitted.equal(element)).isNotEmpty);

    return matches;
  }

  static String parseOutRatingJson(String starting) {
    String val = starting.replaceAllMapped(
        RegExp(r'{*"Rating"*:*{*"min"*:([0-9]+),*"max":([0-9]+)}}'),
            (Match m) =>
            "\"Rating\", \"min\":${m[1]},\"max\":${m[2]}"
    );

    return val;
  }

  factory GameConfig.fromJson(Map<String, dynamic> data) {

    final title = data['name'] as String;
    final year = data['year'] as int;
    final items = List.from(data['fields']).map((e) => ConfigItem.fromJson(e)).toList();

    return GameConfig(title: title, year: year, items: items);

  }

  Future<void> saveMatchForm(int station, int match, int teamNum) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //TODO: Use a "for item"??

    Map<String, dynamic> data = {
      'match_number': match + 1,
      'team': teamNum,
      'scouter': prefs.getString(PrefsConstants.namePref),
      'event_key': prefs.getString(PrefsConstants.currentEventPref),
      'fields': Map.fromIterable(
          items.where((element) => element.isValidInput()).map((e) => e.generateJSON(prefs)).toList(),
          key: (e) => e.keys.first,
          value: (e) => e[e.keys.first]
      )
    };

    String json = jsonEncode(data);

    File file = await generateFile(station, match+1, teamNum);

    file.createSync();

    //If there's already something there, this will just overwrite it (i.e. rewriting)
    file.writeAsStringSync(json);

    //Save to the server through the api

    saveListToAPI([json]);

    print(await file.readAsString());
  }

  //TODO: Delete when fixed
  Future<void> saveListToAPI(List<String> json) async {
    String compositeString = "[";

    for (var element in json) {
      compositeString += "$element,";
    }

    compositeString = "${compositeString.substring(0, compositeString.length-1)}]";

    saveToAPI(compositeString);
  }

  Future<void> saveToAPI(String json) async {
    try {
      var url = Uri.parse("${ApiConstants.baseUrl}/template/$title/submit");
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json,
      );

      print(response.body);

      if (response.statusCode != 200) {
        print("FAILED API POST");
        print(response.statusCode);
        print(response.body);
      }
    } catch (e) {
      print("API Post request errored out!");
    }
  }

  Future<File> generateFile(int station, int match, int teamNum, [int num = 0]) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final directory = await getApplicationDocumentsDirectory();

    if(!directory.existsSync()) directory.createSync();

    String? name = prefs.getString(PrefsConstants.namePref);

    File file =  File('${directory.path}/matches/m${match}s${station}-$teamNum-${name ?? "unknown"}-$num.json');

    if(!file.parent.existsSync()) file.parent.createSync();

    return file;
  }

  static Future<List<String>> loadSubmittedForms() async{
    final docsDirectory = await getApplicationDocumentsDirectory();

    if(!docsDirectory.existsSync()) docsDirectory.createSync();

    final directory = Directory("${docsDirectory.path}/matches/");
    if(!directory.existsSync()) directory.createSync();

    List<FileSystemEntity> entities = directory.listSync();
    
    List<File> files = entities.whereType<File>().toList();

    return files.map((e) => e.path).toList();
  }

  static Future<void> deleteSubmittedForms() async {
    List<String> forms = await loadSubmittedForms();

    for (var element in forms) {
      File file = File(element);
      if(file.existsSync()) {
        file.deleteSync();
      }
    }
  }


  /// If they exist, load the saved values from working on the form before
  Future<void> loadSavedValues(int match, int teamNum) async {

    final directory = await getApplicationDocumentsDirectory();

    if(!directory.existsSync()) directory.createSync();

    List<String> submittedForms = await loadSubmittedForms();

    String? path = submittedForms.where((element) =>
        RegExp("m${match+1}s[0-9]-$teamNum").hasMatch(element)).firstOrNull;

    if(path != null) {
      File file =  File(path);

      if(file.existsSync()) {
        Map<String, dynamic> fields = jsonDecode(file.readAsStringSync())["fields"];

        for (var label in fields.keys) {
          String type = fields[label].keys.first;
          items.where((element) => element.label == label).firstOrNull!.updateSavedValue(fields[label][type]);
        }
      }
    }
  }

  final int year;
  final String title;
  final List<ConfigItem> items;

}



class ConfigItem {

  String type = "";
  String label = "";
  int min = -1;
  int max = -1;
  FormItem widget = TitleItem(label: "", item: null);

  bool valSaved = false;
  dynamic savedVal;

  ConfigItem(
    this.type,
    this.label,
    this.min,
    this.max
  ) {
    widget = generateWidget();
  }

  void updateSavedValue(dynamic val) {
    savedVal = val;
    valSaved = true;
  }

  Future<dynamic> recoverSavedValue([Duration pollInterval = Duration.zero]) async {

    await Future.doWhile(() => Future.delayed(pollInterval).then((_) => !valSaved));

    return savedVal;
  }

  factory ConfigItem.fromJson(Map<String, dynamic> data) {
    final type = data['data_type'] as String;
    final label = data['name'] as String;
    final min = data['min'] != null ? data['min'] as int : -1;
    final max = data['max'] != null ? data['max'] as int : -1;

    return ConfigItem(type, label, min, max);
  }

  Map<String, dynamic> generateJSON(SharedPreferences prefs) {
    return {
      label: {
        type: prefs.get(label) as dynamic
      },
    };
  }

  //TODO: properly implement text inputs
  bool isValidInput() {
    return type == "CheckBox" ||
        type == "Rating" ||
        type == "Number" ||
        type == "ShortText"
    ;
  }


  FormItem generateWidget() {

    switch(type) {

      case ("Title"): {
        return TitleItem(label: label, item: this);
      }
      case ("CheckBox"): {
        return CheckBoxField(label: label, item: this,);
      }
      case ("Rating"): {
        return RatingField(label: label, min: min, max: max, item: this);
      }
      case ("Number"): {
        return NumberField(label: label, item: this);
      }
      case ("ShortText"): {
        return ShortTextField(label: label, item: this);
      }

      default: {
        return TitleItem(label: "Unknown Field!", item: this);
      }
    }
  }

}

const TextStyle labelTextStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
const TextStyle titleStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);


class ShortTextField extends FormItem {
  final String label;

  const ShortTextField({Key? key, required this.label, required item}): super(key: key, item: item);

  @override
  State<ShortTextField> createState() => ShortTextFieldState(label: label, initial: "");

}

class ShortTextFieldState extends FormItemState<ShortTextField>{

  final textController = TextEditingController();

  ShortTextFieldState({required label, required initial}): super(label: label, initial: initial);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(widget.label, style: labelTextStyle,),
        Expanded(child: TextField(
          controller: textController,
          onSubmitted:(String value) {
            prefs.setString(widget.label, value);
          } ,
        ))
      ],
    );
  }

  @override
  Future<void> waitForSavedValue() async {
    String savedVal = (await widget.item!.recoverSavedValue()) as String;
    textController.text = savedVal;
  }

}

class NumberField extends FormItem {
  final String label;

  const NumberField({Key? key, required this.label, required item}): super(key: key, item: item);

  @override
  State<NumberField> createState() => NumberFieldState(label: label, initial: 0);

}

class NumberFieldState extends FormItemState<NumberField>{

  NumberFieldState({required label, required initial}): super(label: label, initial: initial);

  int val = 0;

  void setVal(int newVal) {
    setState(() {
      val = newVal;
    });
    
    prefs.setInt(widget.label, newVal);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(widget.label, style: labelTextStyle),
        Row(
          children: [
            IconButton(
                onPressed: () => {if(val > 0) setVal(val-1)},
                icon: Icon(Icons.remove),
            ),
            Text(val.toString()),
            IconButton(
                onPressed: () => {setVal(val+1)},
                icon: Icon(Icons.add),
            ),

          ]
        )
      ],
    );
  }

  @override
  Future<void> waitForSavedValue() async {
    int savedVal = (await widget.item!.recoverSavedValue()) as int;
    setVal(savedVal);
  }

}

class RatingField extends FormItem {
  final String label;
  final int max;
  final int min;

  const RatingField({Key? key, required this.label, required this.min, required this.max, required item}): super(key: key, item: item);

  @override
  State<RatingField> createState() => RatingFieldState(label: label, initial: this.min);

}

class RatingFieldState extends FormItemState<RatingField>{

  RatingFieldState({required label, required initial}): super(label: label, initial: initial);

  double val = 0;

  void setVal(double newVal) {
    setState(() {
      val = newVal;
    });

    prefs.setDouble(widget.label, newVal);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(widget.label, style: labelTextStyle,),
        Row(
          children: [
            Text(widget.min.toString(), style: labelTextStyle,),
            Slider(
                value: val,
                label: val.round().toString(),
                onChanged: (double value) {
                    setVal(value);
                },
              min:  widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: widget.max - widget.min,
            ),
            Text(widget.max.toString(), style: labelTextStyle,),

          ],
        )
      ],
    );
  }

  @override
  Future<void> waitForSavedValue() async {
    double savedVal = (await widget.item!.recoverSavedValue()) as double;
    setVal(savedVal);
  }

}

class CheckBoxField extends FormItem {
  final String label;

  const CheckBoxField({Key? key, required this.label, required item}): super(key: key, item: item);

  @override
  State<CheckBoxField> createState() => CheckBoxFieldState(label: label, initial: false);

}

class CheckBoxFieldState extends FormItemState<CheckBoxField>{

  CheckBoxFieldState({required label, required initial}): super(label: label, initial: initial);

  bool val = false;

  @override
  Future<void> waitForSavedValue() async {
    bool savedVal = (await widget.item!.recoverSavedValue()) as bool;
    setVal(savedVal);
  }

  void setVal(bool newVal) {
    setState(() {
      val = newVal;
    });

    prefs.setBool(widget.label, newVal);

  }

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(widget.label, style: labelTextStyle,),
          Checkbox(
              value: val,
              onChanged: (e) => setVal(e ?? false)
          )
        ],
    );
  }

}

class TitleItem extends FormItem {

  final String label;

  const TitleItem({Key? key, required this.label, required item}): super(key: key, item: item);

  @override
  State<TitleItem> createState() => TitleItemState();

}

class TitleItemState extends State<TitleItem> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.label, style: titleStyle,);
  }

}

class FormItem extends StatefulWidget {
  final ConfigItem? item;

  const FormItem({super.key, required this.item});

  @override
  State<StatefulWidget> createState() => BaseFormItemState(label: "", initial: 0);

}

class BaseFormItemState extends FormItemState<FormItem> {

  BaseFormItemState({required label, required initial}):
        super(label: label, initial: initial);

  @override
  Future<void> waitForSavedValue() async {}

}

abstract class FormItemState<T extends FormItem> extends State<T> {
  String label;
  var initial;

  Future<void> waitForSavedValue();

  FormItemState({required this.label, required this.initial});

  late SharedPreferences prefs;

  @override
  void initState() {
    loadPrefs();
    waitForSavedValue();
    super.initState();
  }


  Future<void> loadPrefs() async {
    prefs = await SharedPreferences.getInstance();

    if(initial is int) {
      prefs.setInt(label, initial);
    } else if(initial is double) {
      prefs.setDouble(label, initial);
    } else if(initial is bool) {
      prefs.setBool(label, initial);
    } else if(initial is String) {
      prefs.setString(label, initial);
    } else if(initial is List<String>) {
      prefs.setStringList(label, initial);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text("");
  }

}