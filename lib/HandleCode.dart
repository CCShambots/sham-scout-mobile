import 'package:shared_preferences/shared_preferences.dart';

class HandleCode {

  static String currentPartialCode = "";
  static int lastSplitIndex = 0;
  static bool splitDone = false;

  static Future<CodeType> handleQRCode(String? value ) async {

    final prefs = await SharedPreferences.getInstance();

    String code = value ?? "";

    if(handleSplit(code)) {
      if(splitDone) {
        code = currentPartialCode;
        lastSplitIndex = 0;
        splitDone = false;
      } else {
        return CodeType.Split;
      }
    }

    currentPartialCode = "";

    print('code ${code}');

    CodeType type = getCodeType(code);

    //Remove the code type prefix of the code
    code = code.substring(4);

    switch(type) {
      case CodeType.Schedule: {
        saveSchedule(code, prefs);
        break;
      }

      case CodeType.GameConfig: {
        saveGameConfig(code, prefs);
        break;
      }

      default:
      {
        //Do nothing because there's nothing to do
      }
    }


    return type;
  }

  static saveGameConfig(String code, SharedPreferences prefs) {
    //just save the json and parse it later
    prefs.setString("game-config", code);
  }
  
  static saveSchedule(String code, SharedPreferences prefs) {

    String name = code.substring(0, code.indexOf(':'));
    code = code.substring(name.length + 1);

    prefs.setString('name', name);

    List<String> matches = <String>[];

    while(code.isNotEmpty) {

      String thisShift = code.substring(0, code.indexOf(','));

      if(thisShift.contains('-')) {
        //The shift has multiple matches, so split them

        int startMatch = int.parse(thisShift.substring(thisShift.indexOf("m")+1, thisShift.indexOf("-")));
        int endMatch = int.parse(thisShift.substring(thisShift.indexOf("-")+1, thisShift.length));
        
        for(int i = startMatch; i<=endMatch; i++) {
          matches.add(thisShift.substring(0, 3) +  i.toString());
        }
      } else {
        //There's just one match, so add it to the list
        matches.add(thisShift);
      }

      code = code.substring(thisShift.length + 1);

    }

    prefs.setInt('num-matches', matches.length);
    prefs.setStringList('schedule', matches);
  }

  static CodeType getCodeType(String code) {
    String relevant = code.substring(0, 3);

    switch(relevant) {
      case "sch": return CodeType.Schedule;
      case "cfg": return CodeType.GameConfig;
      default: return CodeType.None;
    }
  }

  /// Return true if part of a segment, return false
  static bool handleSplit(String code) {

    //Just move on if this is not a split code
    if(code.substring(0, 2) != "pt") return false;

    //Add the code w/o "pt:" to the partialCode
    currentPartialCode += code.substring(4);

    if(code.indexOf("f") == 2) {
      splitDone = true;
    } else {
      lastSplitIndex = int.parse(code[2]);
    }

    return true;
  }

  static void clearPartial() {
    currentPartialCode = "";
    lastSplitIndex = 0;
    splitDone = false;
  }

}
enum CodeType {
  None(type: "none", displayText: "Invalid Code!"),
  GameConfig(type: "cfg", displayText: "Loaded Game Config"),
  Split(type: "pt", displayText: "Read Next Part of Code"),
  Schedule(type: "sch", displayText: "Loaded Match Schedule!");

  const CodeType({
    required this.type,
    required this.displayText
  });

  final String type;
  final String displayText;
}
