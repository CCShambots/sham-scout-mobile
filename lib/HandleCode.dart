import 'package:sham_scout_mobile/constants.dart';
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

    //TODO: Delete print
    print('code ${code}');

    CodeType type = getCodeType(code);

    //Remove the code type prefix of the code
    code = code.substring(4);

    switch(type) {
      case CodeType.ScoutSchedule: {
        saveSchedule(code, prefs);
        break;
      }

      case CodeType.GameConfig: {
        saveGameConfig(code, prefs);
        break;
      }

      case CodeType.MatchSchedule: {
        saveMatchSchedule(code, prefs);
        break;
      }

      case CodeType.EventKey: {
        saveEventKey(code, prefs);
        break;
      }

      default:
      {
        //Do nothing because there's nothing to do
      }
    }

    return type;
  }

  static saveEventKey(String code, SharedPreferences prefs)  {
    //Just save the event key for later
    prefs.setString(PrefsConstants.currentEventPref, code.substring(0, code.indexOf(",")));
    prefs.setBool(PrefsConstants.overrideCurrentEventPref, false);

    print(code.substring(code.indexOf(",")+1));

    prefs.setString(PrefsConstants.tbaPref, code.substring(code.indexOf(",")+1));
  }

  static saveMatchSchedule(String code, SharedPreferences prefs) {
    //just save the code and parse it later
    prefs.setString(PrefsConstants.matchSchedulePref, code);
  }

  static saveGameConfig(String code, SharedPreferences prefs) {
    //just save the json and parse it later
    prefs.setString(PrefsConstants.activeConfigPref, code);
  }
  
  static saveSchedule(String code, SharedPreferences prefs) {

    String name = code.substring(0, code.indexOf(':'));
    code = code.substring(name.length + 1);

    prefs.setString(PrefsConstants.namePref, name);

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

    prefs.setInt(PrefsConstants.numMatchesPref, matches.length);
    prefs.setStringList(PrefsConstants.schedulePref, matches);
  }

  static CodeType getCodeType(String code) {
    String relevant = code.substring(0, 3);

    switch(relevant) {
      case "sch": return CodeType.ScoutSchedule;
      case "cfg": return CodeType.GameConfig;
      case "mtc": return CodeType.MatchSchedule;
      case "eve": return CodeType.EventKey;
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
  MatchSchedule(type: "mtc", displayText: "Loaded Event Match Schedule"),
  ScoutSchedule(type: "sch", displayText: "Loaded Scouter Schedule!"),
  EventKey(type: "eve", displayText: "Loaded event Key"),
  Split(type: "pt", displayText: "Read Next Part of Code"),
  ;

  const CodeType({
    required this.type,
    required this.displayText
  });

  final String type;
  final String displayText;
}
