import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameConfig {

  GameConfig({
    required this.title,
    required this.year,
    required this.items,
  });

  static String parseOutRatingJson(String starting) {
    String val = starting.replaceAllMapped(
        RegExp(r'{*"Rating"*:*{*"min"*:([0-9]+),*"max":([0-9]+)}}'),
            (Match m) =>
            "\"Rating\", \"min\":${m[1]},\"max\":${m[2]}"
    );

    print(val);
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
      'match': match,
      'station': station,
      'team': teamNum,
      'scout': prefs.getString("name"),
      'title': title,
      'year': year,
      'fields': items.where((element) => element.isValidInput()).map((e) => e.generateJSON(prefs)).toList()
    };

    String json = jsonEncode(data);

    File file = await generateFile(station, match, teamNum);

    int currentNum = 0;

    //If this is another entry by the same scout for whatever reason, generate a new file
    while(file.existsSync()) {
      currentNum++;

      file = await generateFile(station, match, teamNum, currentNum);
    }

    file.createSync();

    file.writeAsStringSync(json);

    print(await file.readAsString());
  }

  Future<File> generateFile(int station, int match, int teamNum, [int num = 0]) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final directory = await getApplicationDocumentsDirectory();

    if(!directory.existsSync()) directory.createSync();

    String? name = prefs.getString("name");

    File file =  File('${directory.path}/matches/m${match}s$station-${name ?? "unknown"}-$num.json');

    if(!file.parent.existsSync()) file.parent.createSync();

    return file;
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
  FormItem widget = TitleItem(label: "");

  ConfigItem(
    this.type,
    this.label,
    this.min,
    this.max
  ) {
    widget = generateWidget();
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
      'name': label,
      'value': prefs.get(label) as dynamic
    };
  }

  //TODO: properly implement text inputs
  bool isValidInput() {
    return type == "checkbox" ||
        type == "rating" ||
        type == "number"
    ;
  }


  FormItem generateWidget() {

    switch(type) {

      case ("Title"): {
        return TitleItem(label: label);
      }
      case ("CheckBox"): {
        return CheckBoxField(label: label);
      }
      case ("Rating"): {
        return RatingField(label: label, min: min, max: max);
      }
      case ("Number"): {
        return NumberField(label: label);
      }
      case ("Short_text"): {
        return ShortTextField(label: label);
      }

      default: {
        return TitleItem(label: "Unknown Field!");
      }
    }
  }

}

const TextStyle labelTextStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
const TextStyle titleStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);


class ShortTextField extends FormItem {
  final String label;

  const ShortTextField({Key? key, required this.label, }): super(key: key);

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

}

class NumberField extends FormItem {
  final String label;

  const NumberField({Key? key, required this.label, }): super(key: key);

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

}

class RatingField extends FormItem {
  final String label;
  final int max;
  final int min;

  const RatingField({Key? key, required this.label, required this.min, required this.max, }): super(key: key);

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

}

class CheckBoxField extends FormItem {
  final String label;

  const CheckBoxField({Key? key, required this.label}): super(key: key);

  @override
  State<CheckBoxField> createState() => CheckBoxFieldState(label: label, initial: false);

}

class CheckBoxFieldState extends FormItemState<CheckBoxField>{

  CheckBoxFieldState({required label, required initial}): super(label: label, initial: initial);

  bool val = false;

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

  const TitleItem({Key? key, required this.label}): super(key: key);

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

  const FormItem({super.key});

  @override
  State<StatefulWidget> createState() => FormItemState(label: "", initial: 0);

}

class FormItemState<T extends FormItem> extends State<T> {
  String label;
  var initial;

  FormItemState({required this.label, required this.initial});

  late SharedPreferences prefs;

  @override
  void initState() {
    loadPrefs();
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