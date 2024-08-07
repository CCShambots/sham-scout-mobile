import 'package:http/http.dart' as http;
import 'package:sham_scout_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  static bool cookieExists = false;

  static Future<http.Response> get(String url) async {
    http.Response response = await http.get(Uri.parse(url), headers: headers);
    return response;
  }

  static Future<http.Response> post(String url, dynamic data) async {
    http.Response response = await http.post(Uri.parse(url), body: data, headers: headers);
    return response;
  }

  static Future<http.Response> patch(String url, dynamic data) async {
    http.Response response = await http.patch(Uri.parse(url), body: data, headers: headers);
    return response;
  }

  static void updateCookie() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cookieVal = prefs.getString(PrefsConstants.jwtPref) ?? "";

    if(cookieVal.contains("<!doctype")) {
      prefs.setString(PrefsConstants.jwtPref, "");
    } else if(cookieVal != "") {
      headers['cookie'] = cookieVal;
      cookieExists = true;
    }
  }
}