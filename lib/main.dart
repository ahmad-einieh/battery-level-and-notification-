import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'battery app'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final Battery battery = Battery();
  int level = 0;
  BatteryState bs = BatteryState.discharging;
  late StreamSubscription subscription;
  late Timer timer;
  late Timer timer1;

  @override
  void initState() {
    super.initState();
    initSetting();
    WidgetsBinding.instance!.addObserver(this);
    listenBatteryState();
    listenBatteryLevel();
    timer1 = Timer.periodic(const Duration(seconds: 65), (_) {
      checkIsFull();
    });
  }

  void listenBatteryState() => battery.onBatteryStateChanged
      .listen((batteryState) => setState(() => bs = batteryState));

  void listenBatteryLevel() {
    updateBatteryLevel();
  }

  Future updateBatteryLevel() async {
    final batteryLevel = await battery.batteryLevel;
    setState(() => level = batteryLevel);
    timer = Timer.periodic(
        const Duration(seconds: 30), (_) async => updateBatteryLevel());
  }

  Future<void> checkIsFull() async {
    if (level > 99  && (bs == BatteryState.charging)) {
      displayNoti();
    }/* else if (kDebugMode) {
      print("not do");
    }*/
  }

  @override
  void dispose() {
    timer.cancel();
    timer1.cancel();
    subscription.cancel();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isBackground = state == AppLifecycleState.paused;
    final isfoucse = state == AppLifecycleState.inactive;
    final isClosed = state == AppLifecycleState.detached;
    final isResume = state == AppLifecycleState.resumed;

    if (isBackground || isClosed || isfoucse || isResume) {
      listenBatteryState();
      listenBatteryLevel();
      timer1 = Timer.periodic(const Duration(seconds: 30), (_) {
        checkIsFull();
      });
    }
    /*
    if(isbackground) // service.stop();
    else // service.start();
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: buildBatteryLevel(level)));
  }

  Widget buildBatteryLevel(int batteryLevel) => Text(
        "$batteryLevel %",
        style: const TextStyle(
            fontSize: 46, color: Colors.green, fontWeight: FontWeight.bold),
      );

  Future<void> displayNoti() async {
    notifications.show(
        0,
        "full",
        "your device is full",
        const NotificationDetails(
          android: AndroidNotificationDetails('channel id', 'channel name',
              channelDescription: 'channel description',
              importance: Importance.max),
          iOS: IOSNotificationDetails(),
          linux: LinuxNotificationDetails(),
          macOS: MacOSNotificationDetails(),
        ));
  }
}

void initSetting() async {
  var initilizeAndroid = const AndroidInitializationSettings('a');
  var initilizeIOS = const IOSInitializationSettings();
  var initilizemac = const MacOSInitializationSettings();
  var initilizelinux =
      const LinuxInitializationSettings(defaultActionName: "a");
  var allInit = InitializationSettings(
      android: initilizeAndroid,
      macOS: initilizemac,
      iOS: initilizeIOS,
      linux: initilizelinux);
  await notifications.initialize(allInit);
}
