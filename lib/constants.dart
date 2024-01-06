import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static String baseUrl = 'https://scout.voth.name:3000/protected';

  //Templates endpoints
  static String getTemplatesEndpoint = '/templates/';
  static String getTemplateByNameEndpoint = '/template/';

  //Forms endpoints
  static String getFormEndpoint = '/forms/';
  static String submitFormEndpoint = '/form/';
  static String editFormEndpoint = '/form/';

  //Schedules endpoints
  static String getSchedulesEndpoint = '/schedule/';

  //Bytes endpoint
  static String bytesUrl = "/bytes/";

  //Blue alliance endpoints
  static String tbaBaseUrl = 'https://www.thebluealliance.com/api/v3';

  static void loadRemoteAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? host = prefs.getString(PrefsConstants.apiAddressPref);
    if(host != null && host != "") {
      baseUrl = host;
    }
  }
}

class PrefsConstants {
  static String matchSchedulePref = "match-schedule";
  static String activeConfigPref = "game-config";
  static String activeConfigNamePref = "game-config-name";
  static String namePref = "name";
  static String currentEventPref = "current-event";
  static String currentYearPref = "current-year";
  static String overrideCurrentEventPref = "current-event-override";
  static String numMatchesPref = "num-matches";
  static String schedulePref = "schedule";
  static String tbaPref = "tba-key";
  static String apiAddressPref = "api-address";
  static String emailPref = "email";
  static String jwtPref = "jwt";

}