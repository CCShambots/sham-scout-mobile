class ApiConstants {
  // static String remoteUrl = 'http://192.168.0.180:8080';
  static String remoteUrl = 'http://192.168.1.188:8080';
  static String localUrl = 'http://localhost:8080';

  static String baseUrl = PrefsConstants.editorMode ? localUrl : remoteUrl;
  static String templatesEndpoint = '/templates/get';
  static String statusEndpoint = '$baseUrl/status';

  static String tbaBaseUrl = 'https://www.thebluealliance.com/api/v3';
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

  static bool editorMode = false;
}