import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sham_scout_mobile/formItems.dart';
import 'package:sham_scout_mobile/pages/history.dart';
import 'package:sham_scout_mobile/pages/home.dart';
import 'package:sham_scout_mobile/matches.dart';
import 'package:sham_scout_mobile/pages/schedule.dart';
import 'package:sham_scout_mobile/scan.dart';
import 'package:sham_scout_mobile/pages/settings.dart';
import 'package:sham_scout_mobile/constants.dart';
import 'package:http/http.dart' as http;
import 'package:sham_scout_mobile/util/Session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SnackBarService {
  static final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  static void showSnackBar({required String content}) {
    scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(content)));
  }
}

class ConnectionStatus {
  static bool connected = false;
  static bool openBrowserForCookieGen = false;

  static const connectionInterval = Duration(seconds: 5);

  static checkConnection() async{

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var url = Uri.parse("${ApiConstants.baseUrl}/code");

    try {
      var client = HttpClient();
      var request = await client.getUrl(url);
      request.followRedirects = false;

      int responseCode =
      !Session.cookieExists ?
      (await request.close().timeout(const Duration(seconds: 5))).statusCode :
      (await Session.get(ApiConstants.baseUrl)).statusCode;

      switch(responseCode) {
        case 200:
          //All good, ready to use
          ConnectionStatus.connected = true;
          openBrowserForCookieGen = false;
          break;
        default:
          //Have no cookie, redirect user to page to generate
          if(!openBrowserForCookieGen) {
            await launchUrl(url);
          }
          openBrowserForCookieGen = true;
          break;
      }

    } catch(e) {
      ConnectionStatus.connected = false;
    }
  }

}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  Session.updateCookie();

  ApiConstants.loadRemoteAPI();

  runApp(const MyApp());

  //Regularly check the api connection

  Timer.periodic(ConnectionStatus.connectionInterval, (timer) {ConnectionStatus.checkConnection();});

  //Check connection immediately at startup to better inform users
  ConnectionStatus.checkConnection();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShamScout Mobile',
      scaffoldMessengerKey: SnackBarService.scaffoldKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Theme.of(context).colorScheme.background,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        brightness: Brightness.dark
      ),
      home: BottomNavigation(),
    );
  }
}

class BottomNavigation extends StatefulWidget {

  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() =>
      BottomNavigationBarState();
}

class BottomNavigationBarState extends State<BottomNavigation>{

  String name = "Select a Name!";

  bool connection = false;
  bool wasConnected = false;

  int selectedIndex = 2;
  final pageViewController = PageController(initialPage: 2);

  String email = "";
  var emailController = TextEditingController();
  String code = "";

  bool showCookieModal = false;
  bool cookieModalOpen = false;


  @override
  void initState() {
    super.initState();
    loadPrefsValues();

    Future.delayed(Duration(seconds: 2), () {
      handleConnectionCheckResult();
    });

    Timer.periodic(ConnectionStatus.connectionInterval, (timer) {
      handleConnectionCheckResult();
    });
  }

  void handleConnectionCheckResult() {
    setState(() {
      connection = ConnectionStatus.connected;
      showCookieModal = ConnectionStatus.openBrowserForCookieGen;
    });
  }

  Future<void> loadPrefsValues() async {

    final prefs = await SharedPreferences.getInstance();

    String email = prefs.getString(PrefsConstants.emailPref) ?? "";

    emailController.text = email;

    setState(() {
      name = prefs.getString(PrefsConstants.namePref) != null ? prefs.getString(PrefsConstants.namePref) ?? "" : name;
      this.email = email;
    });
  }

  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static List<Widget> widgetOptions = <Widget>[
    Matches(),
    Scan(),
    Home(),
    Schedule(),
    History(),
    Settings(),
  ];

  void onItemTapped(int index) {
    pageViewController.animateToPage(index, duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    pageViewController.dispose();
    super.dispose();
  }

  Future<void> backSaveForms(BuildContext context) async {
    print("backsaving");

    final prefs = await SharedPreferences.getInstance();

    String gameConfig = prefs.getString(PrefsConstants.activeConfigPref) ?? "";
    print(gameConfig);

    //Remove newline characters to avoid problems
    final parsedJson = jsonDecode(GameConfig.parseOutRatingJson(jsonEncode(jsonDecode(gameConfig != "" ? gameConfig : '{"name": "None", "year": 2023, "fields":[]}'))));

    final GameConfig loadedConfig = GameConfig.fromJson(parsedJson);

    if(mounted) {
      int numSaved = await loadedConfig.attemptUploadOfSubmittedForms(context);

      if(mounted && numSaved > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reconnected! Uploaded $numSaved matches to database")));
      }
    }

  }

  void updateEmail(String newEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString("email", newEmail);

    setState(() {
      email = newEmail;
    });
  }

  void openAuthModal(BuildContext context) {
    showDialog(context: context, builder: (BuildContext context) =>
        AlertDialog(
            content:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Input Login info"),
                TextField(
                  decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter Email Address'
                  ),
                  controller: emailController,
                  onChanged: (value) {
                    updateEmail(value);
                  },
                ),
                TextField(
                  decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter One-Time Code'
                  ),
                  onChanged: (value) {
                    setState(() {
                      code = value;
                    });
                  },
                )
              ],
            ),
            actions: <TextButton>[
              TextButton(
                  onPressed: () async {
                    setState(() {
                      cookieModalOpen = false;
                      showCookieModal = false;
                    });
                    SharedPreferences prefs = await SharedPreferences.getInstance();

                    Uri url = Uri.parse("${ApiConstants.baseUrl.replaceAll("/protected", "")}/auth/$code/$email");

                    http.Response resp = await http.get(url);
                    prefs.setString(PrefsConstants.jwtPref, resp.body);

                    Session.updateCookie();

                    if(resp.statusCode == 200) {
                      ConnectionStatus.openBrowserForCookieGen = false;
                    }

                    if(mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit')
              )
            ]
        )).then((val) {
      setState(() {
        cookieModalOpen = false;
        showCookieModal = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    //Reload the user's name
    loadPrefsValues();

    if(showCookieModal && !cookieModalOpen) {
      setState(() {
        cookieModalOpen = true;
      });

      Future.delayed(Duration.zero, () {
        openAuthModal(context);
      });
    }

    if(connection && !wasConnected) {
      backSaveForms(context);

      setState(() {
        wasConnected = connection;
      });
    }

    if(!connection) {
      setState(() {
        wasConnected = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
              icon: Icon(
                connection ? Icons.cloud_done : Icons.cloud_off,
                color: connection ? Colors.green : Colors.red,
              ),
              tooltip: connection ? "API Connected" : "API Disconnected",
              onPressed: null,
          )
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PageView(
        controller: pageViewController,
        children: widgetOptions,
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label:'Matches',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label:'Scan',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label:'Search',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label:'Upcoming',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label:'Completed',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label:'Settings',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onBackground,
        unselectedLabelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        onTap: onItemTapped,
      ),
    );
  }
}