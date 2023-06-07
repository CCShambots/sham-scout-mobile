import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GameConfig {

  GameConfig({
    required this.title,
    required this.year,
    required this.items,
  });

  factory GameConfig.fromJson(Map<String, dynamic> data) {

    final title = data['title'] as String;
    final year = data['year'] as int;
    final items = List.from(data['items']).map((e) => ConfigItem.fromJson(e)).toList();

    return GameConfig(title: title, year: year, items: items);

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
  Widget widget = Text("");

  ConfigItem(
    this.type,
    this.label,
    this.min,
    this.max
  ) {
    this.widget = generateWidget();
  }

  factory ConfigItem.fromJson(Map<String, dynamic> data) {
    final type = data['type'] as String;
    final label = data['label'] as String;
    final min = data['min'] != null ? data['min'] as int : -1;
    final max = data['max'] != null ? data['max'] as int : -1;

    return ConfigItem(type, label, min, max);
  }

  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  Widget generateWidget() {

    switch(type) {

      case ("title"): {
        return Text(label, style: optionStyle,);
      }
      case ("checkbox"): {
        return CheckBoxField(label: label);
      }
      case ("rating"): {
        return RatingField(label: label, min: min, max: max);
      }
      case ("number"): {
        return NumberField(label: label);
      }
      case ("short_text"): {
        return ShortTextField(label: label);
      }

      default: {
        return Text("Unknown Field!");
      }
    }
  }

}

const TextStyle labelTextStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

class ShortTextField extends StatefulWidget {
  final String label;

  const ShortTextField({Key? key, required this.label, }): super(key: key);

  @override
  State<ShortTextField> createState() => ShortTextFieldState();

}

class ShortTextFieldState extends State<ShortTextField>{

  int val = 0;

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

class NumberField extends StatefulWidget {
  final String label;

  const NumberField({Key? key, required this.label, }): super(key: key);

  @override
  State<NumberField> createState() => NumberFieldState();

}

class NumberFieldState extends State<NumberField>{

  int val = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(widget.label, style: labelTextStyle),
        Row(
          children: [
            IconButton(
                onPressed: () => {if(val > 0) setState(() {val -=1;})},
                icon: Icon(Icons.remove),
                color: Colors.black,
            ),
            Text(val.toString()),
            IconButton(
                onPressed: () => {setState(() {val +=1;})},
                icon: Icon(Icons.add),
                color: Colors.black,
            ),

          ]
        )
      ],
    );
  }

}

class RatingField extends StatefulWidget {
  final String label;
  final int max;
  final int min;

  const RatingField({Key? key, required this.label, required this.min, required this.max, }): super(key: key);

  @override
  State<RatingField> createState() => RatingFieldState();

}

class RatingFieldState extends State<RatingField>{

  double val = 0;

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
                    setState(() {
                      val = value;
                    });
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

class CheckBoxField extends StatefulWidget {
  final String label;

  const CheckBoxField({Key? key, required this.label}): super(key: key);

  @override
  State<CheckBoxField> createState() => CheckBoxFieldState();

}

class CheckBoxFieldState extends State<CheckBoxField>{

  bool val = false;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(widget.label, style: labelTextStyle,),
          Checkbox(value: val, onChanged: (e) => setState(() {
            val = e ?? false;
          }))
        ],
    );
  }

}