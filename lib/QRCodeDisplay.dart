import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sham_scout_mobile/formItems.dart';
import 'package:sham_scout_mobile/schedule.dart';

class QRCodeDisplay extends StatefulWidget {

  const QRCodeDisplay({super.key});

  @override
  State<StatefulWidget> createState() => QRCodeDisplayState();

}

class QRCodeDisplayState extends State<QRCodeDisplay> {

  List<ScheduleMatch> submittedMatches = [];
  List<String> jsonValues = [];

  int formIndex = 0;

  TextStyle textStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 30
  );

  @override
  void initState() {
    loadSubmittedMatches();
  }

  Future<void> loadSubmittedMatches() async {
    List<String> fileNames = await GameConfig.loadSubmittedForms();
    setState(() {
      submittedMatches = fileNames.map((e) => ScheduleMatch.fromSavedFile(e)).toList();
      submittedMatches.sort((e1, e2) => e1.matchNum-e2.matchNum);

      jsonValues = fileNames.map((e) => File(e).readAsStringSync()).toList();
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text("Scan me!"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Match ${submittedMatches[formIndex].matchNum+1}", style: textStyle,),
            Text("Team ${submittedMatches[formIndex].teamNum}", style: textStyle,),
            Container(
              color: Colors.white,
              child: QrImageView(
                data: jsonValues[formIndex] ?? "",
                size: 350,
                // You can include embeddedImageStyle Property if you
                //wanna embed an image from your Asset folder
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: const Size(
                    150,
                    150,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () {
                      if(formIndex > 0) {
                        setState(() {
                          formIndex--;
                        });
                      }
                    },
                    iconSize: 75,
                    icon: Icon(Icons.keyboard_arrow_left)),
                Text("Form ${formIndex+1} of ${submittedMatches.length}", style: textStyle,),
                IconButton(
                    onPressed: () {
                    if(formIndex + 1 < submittedMatches.length) {
                      setState(() {
                        formIndex++;
                      });
                    }
                  },
                    iconSize: 75,
                    icon: Icon(Icons.keyboard_arrow_right))
              ],
            )
          ],
        ),
      ),

    );
  }

}