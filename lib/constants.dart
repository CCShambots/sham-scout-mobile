import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static String remoteUrl = 'http://192.168.22.41:8080';
  static String localUrl = 'http://localhost:8080';

  static String baseUrl = PrefsConstants.editorMode ? localUrl : remoteUrl;
  static String templatesEndpoint = '/templates/get';
  static String statusEndpoint = '$baseUrl/status';

  static String tbaBaseUrl = 'https://www.thebluealliance.com/api/v3';

  static void loadRemoteAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String host = prefs.getString(PrefsConstants.apiAddressPref)!;

    remoteUrl = host;
  }
}

class PrefsConstants {
  static String matchSchedulePref = "match-schedule";
  static String activeConfigPref = "game-config";
  static String activeConfigNamePref = "game-config-name";
  static String namePref = "name";
  static String currentEventPref = "current-event";
  static String overrideCurrentEventPref = "current-event-override";
  static String numMatchesPref = "num-matches";
  static String schedulePref = "schedule";
  static String tbaPref = "tba-key";
  static String apiAddressPref = "api-address";

  static bool editorMode = false;
}