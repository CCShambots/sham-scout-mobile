import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeDisplay extends StatefulWidget {

  const QRCodeDisplay({super.key});

  @override
  State<StatefulWidget> createState() => QRCodeDisplayState();

}

class QRCodeDisplayState extends State<QRCodeDisplay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text("Scan me!"),
      ),
      body: Center(
      child: QrImageView(
          data: '{"match":1,"station":1,"team":5907,"title":"CHARGED UP","year":2023,"fields":[{"label":"Mobility","value":false},{"label":"Attempt Balance","value":false},{"label":"Dock","value":false},{"label":"Engage","value":false},{"label":"Auto Cycles","value":0},{"label":"Pick ups","value":0},{"label":"Low","value":0},{"label":"Mid","value":0},{"label":"High","value":0},{"label":"Endgame Attempt Balance","value":false},{"label":"Endgame Dock","value":false},{"label":"Endgame Engage","value":false},{"label":"BALLS SHOT HIGH","value":false}]}',
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

    );
  }

}