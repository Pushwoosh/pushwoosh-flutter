import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'dart:async';

class StopwatchApp extends StatelessWidget {
  const StopwatchApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StopWatchScreen(),
    );
  }
}

class StopWatchScreen extends StatefulWidget {
  const StopWatchScreen({super.key});

  @override
  State<StopWatchScreen> createState() => _StopWatchScreenState();
}

class _StopWatchScreenState extends State<StopWatchScreen> {
  int seconds = 0;
  bool isRunning = false;
  Timer? timer;

  /// channel key is used to send data from flutter to swift side over 
  /// a unique bridge (link between flutter & swift) 
  final DynamicIslandManager diManager = DynamicIslandManager(channelKey: 'PW');

  void startTimer() {
    setState(() {
      isRunning = true;
    });

    // invoking startLiveActivity Method
    diManager.startLiveActivity(
      jsonData: DynamicIslandStopwatchDataModel(elapsedSeconds: 0).toMap(),
    );

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
            // invoking the updateLiveActivity Method
      diManager.updateLiveActivity(
        jsonData: DynamicIslandStopwatchDataModel(
          elapsedSeconds: seconds,
        ).toMap(),
      );
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      seconds = 0;
      isRunning = false;
    });

    // invoking the stopLiveActivity Method
    diManager.stopLiveActivity();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch App\nCreated for iOS Live Activity'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Stopwatch: $seconds seconds',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: isRunning ? null : startTimer,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: isRunning ? stopTimer : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DynamicIslandManager {
  final String channelKey;
  late final MethodChannel _methodChannel;

  DynamicIslandManager({required this.channelKey}) {
    _methodChannel = MethodChannel(channelKey);
  }

  Future<void> startLiveActivity({required Map<String, dynamic> jsonData}) async {
    try {
      await _methodChannel.invokeListMethod('startLiveActivity', jsonData);
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
    }
  }

  Future<void> updateLiveActivity(
      {required Map<String, dynamic> jsonData}) async {
    try {
      await _methodChannel.invokeListMethod('updateLiveActivity', jsonData);
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
    }
  }

  Future<void> stopLiveActivity() async {
    try {
      await _methodChannel.invokeListMethod('stopLiveActivity');
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
    }
  }

}

class DynamicIslandStopwatchDataModel {
  final int elapsedSeconds;

  DynamicIslandStopwatchDataModel({
    required this.elapsedSeconds,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'elapsedSeconds': elapsedSeconds,
    };
  }
}