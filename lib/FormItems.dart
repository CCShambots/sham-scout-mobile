import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sham_scout_mobile/Schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameConfig {

  GameConfig({
    required this.title,
    required this.year,
    required this.items,
  });

  static Future<List<ScheduleMatch>> loadUnplayedSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    List<ScheduleMatch> matches = prefs.getStringList('schedule')!.map((e) => ScheduleMatch.fromCode(e)).toList();

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

    Map<String, dynamic> data = {
      'match_number': match,
      'team': teamNum,
      'scout': prefs.getString("name"),
      'event_key': prefs.getString("current-event"),
      'fields': items.where((element) => element.isValidInput()).map((e) => e.generateJSON(prefs)).toList()
    };

    String json = jsonEncode(data);

    File file = await generateFile(station, match, teamNum);

    file.createSync();

    //If there's already something there, this will just overwrite it (i.e. rewriting)
    file.writeAsStringSync(json);

    print(await file.readAsString());
  }

  Future<File> generateFile(int station, int match, int teamNum, [int num = 0]) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final directory = await getApplicationDocumentsDirectory();

    if(!directory.existsSync()) directory.createSync();

    String? name = prefs.getString("name");

    File file =  File('${directory.path}/matches/m${match}s${station}-$teamNum-${name ?? "unknown"}-$num.json');

    if(!file.parent.existsSync()) file.parent.createSync();

    return file;
  }

  static Future<List<String>> loadSubmittedForms() async{
    final directory = await getApplicationDocumentsDirectory();

    if(!directory.existsSync()) directory.createSync();

    List<FileSystemEntity> entities =  Directory("${directory.path}/matches/").listSync();
    
    List<File> files = entities.whereType<File>().toList();

    return files.map((e) => e.path).toList();
  }


  /// If they exist, load the saved values from working on the form before
  Future<void> loadSavedValues(int match, int teamNum) async {

    print("running saved values ");

    final directory = await getApplicationDocumentsDirectory();

    print("running saved values 2");

    if(!directory.existsSync()) directory.createSync();

    print("running saved values 3");

    List<String> submittedForms = await loadSubmittedForms();

    print("running saved values 4");

    String? path = submittedForms.where((element) =>
        RegExp("m${match}s[0-9]-$teamNum").hasMatch(element)).firstOrNull;

    print("running saved values 5: $match $teamNum");

    if(path != null) {
      File file =  File(path);

      print("running saved values 6");
      print(path);

      if(file.existsSync()) {
        List<dynamic> fields = jsonDecode(file.readAsStringSync())["fields"];

        for (var element in fields) {
          String label =  element.keys.first;
          String type = element[label].keys.first;
          print(label);
          print(type);
          print(element[label][type]);
          print(items.map((e) => e.label));
          print(items.length);
          items.where((element) => element.label == label).firstOrNull!.updateSavedValue(element[label][type]);
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

    print("received: $val, on $label");
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
        type == "Number"
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
      case ("Short_text"): {
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

  ShortTextFieldState({required label, required initial}): super(label: label, initial: initial);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(widget.label, style: labelTextStyle,),
        Expanded(child: TextFormField(

        )
        )
      ],
    );
  }

  @override
  Future<void> waitForSavedValue() async {}

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
                color: Colors.black,
            ),
            Text(val.toString()),
            IconButton(
                onPressed: () => {setVal(val+1)},
                icon: Icon(Icons.add),
                color: Colors.black,
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