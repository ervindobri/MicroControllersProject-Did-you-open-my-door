import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart'as http;

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp();

  runApp(MyApp(app: app));
}

class MyApp extends StatelessWidget {
  final FirebaseApp app;

  const MyApp({Key key, this.app}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloseTheDoor',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Close The Door', app: app),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final FirebaseApp app;
  final String title;

  MyHomePage({Key key, this.app, this.title}) : super(key: key);


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseReference doorDataReference;

  bool sensorStatus = false;
  double sensorValue = 0.0;

  var postUrl = "https://fcm.googleapis.com/fcm/send";

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  String _token;
  bool isStopped = false;

  double _doorThreshold = 93.0; //global


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _firebaseMessaging.configure(
      onLaunch: (Map<String, dynamic> message) {
        print('onLaunch called');
      },
      onResume: (Map<String, dynamic> message) {
        print('onResume called');
      },
      onMessage: (Map<String, dynamic> message) {
        print('onMessage called');
      },
    );
    _firebaseMessaging.subscribeToTopic('all');
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(
      sound: true,
      badge: true,
      alert: true,
    ));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print('Hello');
    });
    _firebaseMessaging.getToken().then((token) {
      print(token); // Print the Token in Console
      _token = token;
    });
    doorDataReference = FirebaseDatabase.instance.reference();
    // readData();
    doorDataReference.child('START').onValue.listen((event) {
      var snapshot = event.snapshot;
      setState(() {
        sensorStatus = snapshot.value;
      });
    });
    doorDataReference.child('DISTANCE').onValue.listen((event) {
      var snapshot = event.snapshot;
      setState(() {
        sensorValue = double.parse(snapshot.value.toString());
      });
      if ( sensorValue != 0.0 && sensorValue < _doorThreshold){
        sendNotification();
      }
    });
  }


   Future<void> sendNotification()async {
     // var token = "epX3eqWgTT-PBSvgG7gk16:APA91bEAWxEOwnjZdbKKpjC2-QDPVfTgk77w8tWa_578NQrh-1aClremoRxQR0UOZQDhidcBvYV90YNp7rpIxruttCZqaCZYz3W-ZWz-zY5CiqX2QPHAIfG9hmlbpEv8_-o3SLFJZX_l";
     // print('token : $token');

     final data = {
       "notification": {
         "body": "Oh oh. Someone entered your room!",
         "title": "Intruder alert",
         "sound": "default",
         "color": "#990000",
       },
       "priority": "high",
       "data": {
         "click_action": "FLUTTER_NOTIFICATION_CLICK",
         "id": "1",
         "status": "done"
       },
       "to": "$_token"
     };

     final headers = {
       'Content-Type': 'application/json',
       'Authorization': 'key=AAAAe9SBnF0:APA91bEK6WJPcPyfVtZqIef6bQV5Az_4lCZDDncB42Mo9Kh4P0MwvIZgadEql-dU3oheMpr27GA-yVxt_IPrnct9NEfnoBk_LRM7EdOEQ4qIWVEC-76QIpGxpBhBakGjGdnrKru0M_nx'
     };


     try {
       var response = await http.post(postUrl, headers: headers, body: json.encode(data));
       print(response);
       return true;
     } catch (e, s) {
       print(e);
       return false;
     }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Padding(
                  padding: const EdgeInsets.only(top: 35.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 250,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: Offset(0,5)
                            )
                          ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              "Sensor status",
                              style: GoogleFonts.lato(
                                fontSize: 30,
                                fontWeight: FontWeight.w300
                              ),
                            // ignore: missing_return
                            ),
                            Text(
                              sensorStatus == false ? "OFF" : "ON",
                              style: GoogleFonts.lato(
                                  fontSize: 35,
                                  color:  !sensorStatus? Colors.pink.shade200 : Colors.teal.shade200,
                                  fontWeight: FontWeight.w900
                              ),
                            ),
                            FlatButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0)
                              ),
                                color: sensorStatus ? Colors.teal.shade500 : Colors.pink.shade700,
                                onPressed: ()async{
                                  //TURN ON OR OFF TRIGGER
                                  if (!sensorStatus){
                                    //TURN ON
                                    doorDataReference.child('START').set(true);
                                    sensorStatus = !sensorStatus;
                                  }
                                  else{
                                    //TURN OFF
                                    doorDataReference.child('START').set(false);
                                    sensorStatus = !sensorStatus;
                                  }
                                  print("SENSOR STATUS CHANGED!");
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      !sensorStatus ? "TURN ON" : "TURN OFF",
                                    style: GoogleFonts.lato(
                                        fontSize: 30,
                                        color:  Colors.white,
                                        fontWeight: FontWeight.w900
                                    ),
                                  ),
                                )
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Container(
                          width: 250,
                          // height: 100,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: Offset(0,5)
                                )
                              ]
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text
                                    (
                                      "${sensorValue.toStringAsFixed(2)} CM",
                                    style: GoogleFonts.roboto(
                                      color: Colors.teal,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w200
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text
                                    (
                                    "NO DANGER",
                                    style: GoogleFonts.lato(
                                        color: Colors.teal,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700
                                    ),

                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Icon(
                                      Icons.ac_unit_sharp,
                                    color: Colors.teal,
                                    size: 50,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 35.0),
                            child: new TextField(
                              decoration: new InputDecoration(labelText: "Update door threshold"),
                              keyboardType: TextInputType.number,
                              onSubmitted: (value){
                                  setState(() {
                                    _doorThreshold = double.parse(value);
                                  });
                                  doorDataReference.child('THRESHOLD').set(_doorThreshold);
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
