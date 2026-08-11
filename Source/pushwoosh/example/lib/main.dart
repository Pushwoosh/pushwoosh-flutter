// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'deep_link_screen.dart';
import 'live_activities.dart';
import 'in_app_presets.dart' as in_app_presets;
import 'dart:async';

/**
* 1. import Pushwoosh package
* 2. place the google-services.json file into android/app folder in your project directory.
*/
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';
import 'package:pushwoosh_geozones/pushwoosh_geozones.dart';
import 'package:pushwoosh_inbox/pushwoosh_inbox.dart';

/// iOS and Android demo apps live in separate Pushwoosh projects, so the app code differs per platform.
final String _demoAppCode =
    defaultTargetPlatform == TargetPlatform.iOS ? "7401E-DFDC6" : "11C10-EF18D";

/// Both endpoints serve the demo application: the shared one every app reaches by default, and the
/// per-application host the SDK composes from the app code. Switching between them exercises an
/// endpoint-only move, the case that must not re-register the device.
final List<(String, String)> _regions = [
  ('REGION: SHARED HOST', 'https://api.pushwoosh.com/json/1.3/'),
  ('REGION: PER-APP HOST', 'https://$_demoAppCode.api.pushwoosh.com/json/1.3/'),
];

void main() {
  runApp(const MyApp());
/**
* initialize Pushwoosh SDK.
* Example params: {"app_id": "application id"}
*/
  Pushwoosh.initialize({"app_id": _demoAppCode});

/**
 * Setup Default Live Activity
 */
  Pushwoosh.getInstance.defaultSetup();

/**
* To process various events, use the corresponding listeners as follows.
* Push receipt:
* **********************************************************
* Pushwoosh.getInstance.onPushReceived.listen((event) {}); *
* **********************************************************
* 
* Push open:
* **********************************************************
* Pushwoosh.getInstance.onPushAccepted.listen((event) {}); *
* **********************************************************
* 
*      PUSHWOOSH CODE
*          |   |
*         _|   |_
*         \     /
*          \   /
*           \_/
*/
  Pushwoosh.getInstance.onPushReceived.listen((event) {
    if (kDebugMode) {
      print(event.pushwooshMessage.payload);
    }
  });

  Pushwoosh.getInstance.onPushAccepted.listen((event) {
    if (kDebugMode) {
      print(event.pushwooshMessage.payload);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'PUSHWOOSH DEMO'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool notificationsEnabled = false;
  // Guards registerForRemoteNotification against overlapping calls: a
  // double-tap (or tap-then-untap) before the first await resolves would
  // otherwise fire two native calls whose results race each other.
  bool _isRegistering = false;
  bool foregroundAlertEnabled = true;
  String userId = '';
  String eventName = '';
  String tagKey = '';
  String tagValue = '';
  String language = '';
  String email = '';
  int badges = 0;
  int seconds = 0;
  bool isRunning = false;
  Timer? timer;
  StreamSubscription<String>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupJavaScriptInterface();
    _subscribeToDeepLinks();
    _syncRegistrationState();
  }

  @override
  void dispose() {
    // The subscription is tied to the life of this State, unlike the
    // onPushReceived/onPushAccepted listeners in main().
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  void _setupJavaScriptInterface() async {
    try {
      debugPrint("Setting up JavaScript interface...");
      
      await Future.delayed(Duration(seconds: 2));
      await Pushwoosh.getInstance.addJavascriptInterface('flutter', {
        'showToast': _showToast,
      });
      debugPrint("JavaScript interface 'flutter' registered successfully with methods: [showToast]");
    } catch (e) {
      debugPrint("Failed to register JavaScript interface: $e");
    }
  }

  Future<Map<String, dynamic>> _showToast(Map<String, dynamic> args) async {
    String message = args['message'] ?? 'Hello from JavaScript!';
    
    debugPrint("Toast shown: $message");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    return {
      'success': true,
      'message': 'Toast displayed successfully',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void _subscribeToDeepLinks() {
    /**
    * A deep link from a push notification arrives on this stream. The plugin
    * caches a link that arrived before this listener existed and replays it to
    * the first subscriber, so a cold start is covered too.
    *
    * PUSHWOOSH CODE
    *    |   |
    *   _|   |_
    *   \     /
    *    \   /
    *     \_/
    */
    _deepLinkSubscription =
        Pushwoosh.getInstance.onDeepLinkOpened.listen((String link) {
      debugPrint('Pushwoosh deep link opened: $link');
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) => DeepLinkScreen(deepLinkData: link),
      ));
    }, onError: (Object error) {
      debugPrint('Pushwoosh deep link stream error: $error');
    });
  }

  Future<void> _syncRegistrationState() async {
    /**
    * Push notification token or null if the device is not registered yet.
    * Read on start so the switch shows the real state after a cold launch:
    * the token is restored from platform storage before any call in this
    * process, so this is reliable even on the very first frame.
    *
    * PUSHWOOSH CODE
    *    |   |
    *   _|   |_
    *   \     /
    *    \   /
    *     \_/
    */
    try {
      final String? token = await Pushwoosh.getInstance.getPushToken;
      if (!mounted) return;
      setState(() {
        notificationsEnabled = token != null && token.isNotEmpty;
      });
    } catch (e) {
      // A failed read just leaves the state unknown for this run; the switch
      // stays at its default (OFF) rather than popping an alert on cold start.
      debugPrint('Failed to read push registration state: $e');
    }
  }

  Future<void> registerForRemoteNotification(bool value) async {
    // The switch is bound to notificationsEnabled, and that flag is only ever
    // written after a call succeeds — so a failure leaves the switch showing
    // its previous value with nothing to roll back. While the await is in
    // flight the switch keeps the old position: no intermediate state, no
    // spinner, one change and only by fact.
    //
    // _isRegistering additionally disables the switch for the duration of the
    // call, so a double-tap can't fire two overlapping native calls that race
    // each other's setState.
    setState(() {
      _isRegistering = true;
    });
    try {
      if (value == false) {
        /**
        * To unregister for push notifications, call the following method:
        *
        * PUSHWOOSH CODE
        *    |   |
        *   _|   |_
        *   \     /
        *    \   /
        *     \_/
        */
        await Pushwoosh.getInstance.unregisterForPushNotifications();
        if (!mounted) return;
        setState(() {
          notificationsEnabled = false;
        });
      } else {
        /**
        * To register for push notifications, call the following method:
        *
        * PUSHWOOSH CODE
        *    |   |
        *   _|   |_
        *   \     /
        *    \   /
        *     \_/
        */
        final String? token =
            await Pushwoosh.getInstance.registerForPushNotifications();
        if (!mounted) return;
        setState(() {
          notificationsEnabled = token != null && token.isNotEmpty;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      showAlert(context, 'ERROR', e.message ?? e.code);
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void showForegroundAlert(bool value) {
    setState(() {
      foregroundAlertEnabled = value;
      if (foregroundAlertEnabled == true) {
        showAlert(context, 'INFO', "FOREGROUND ALERTS ENABLED");
      } else {
        showAlert(context, 'INFO', "FOREGROUND ALERTS DISABLED");
      }
      /**
      * Show push notifications alert when push notification is received while the app is running, default is `true`
      * 
      * PUSHWOOSH CODE
      *    |   |
      *   _|   |_
      *   \     /
      *    \   /
      *     \_/
      */
      Pushwoosh.getInstance.setShowForegroundAlert(value);
    });
  }

  void showAlert(BuildContext context, String title, String content) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showToken() async {
    /**
    * Push notification token or null if device is not registered yet.
    *
    * PUSHWOOSH CODE
    *    |   |
    *   _|   |_
    *   \     /
    *    \   /
    *     \_/
    */
    String? token = await Pushwoosh.getInstance.getPushToken;
    if (!mounted) return;
    showAlert(context, "Push Token",
        (token == null || token.isEmpty) ? "NOT REGISTERED" : token);
  }

  void showHWID() async {
    /**
    * Pushwoosh HWID associated with current device
    * 
    * PUSHWOOSH CODE 
    *    |   |
    *   _|   |_
    *   \     /
    *    \   /
    *     \_/
    */
    String hwid = await Pushwoosh.getInstance.getHWID;
    showAlert(context, "HWID", hwid);
  }

  Widget buildButtonRow(
    String buttonText,
    void Function()? onPressed, {
    double? buttonWidth,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (buttonWidth != null)
          SizedBox(
            width: buttonWidth,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 25, 14, 184)),
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(
                  buttonText,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 25, 14, 184)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 101, 240, 154),
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: AssetImage('assets/images/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        buildButtonRow('SET USER ID', () async {
                          /**
                          * Set User indentifier. This could be Facebook ID, username or email, or any other user ID.
                          * This allows data and events to be matched across multiple user devices.
                          * 
                          * PUSHWOOSH CODE 
                          *    |   |
                          *   _|   |_
                          *   \     /
                          *    \   /
                          *     \_/
                          */
                          Pushwoosh.getInstance.setUserId(userId);
                        }, buttonWidth: 170),
                        SizedBox(width: 16),
                        Expanded(
                          child: CupertinoTextField(
                            placeholder: 'USER ID',
                            onChanged: (value) {
                              setState(() {
                                userId = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        buildButtonRow('POST EVENT', () async {
                          /**
                          * Post events for In-App Messages. This can trigger In-App message HTML as specified in Pushwoosh Control Panel.
                          * [event] is string name of the event
                          * [attributes] is map contains additional event attributes
                          * 
                          * PUSHWOOSH CODE 
                          *    |   |
                          *   _|   |_
                          *   \     /
                          *    \   /
                          *     \_/
                          */
                          Pushwoosh.getInstance.postEvent(
                              eventName, {"KEY1": "VALUE1", "KEY2": "VALUE2"});
                        }, buttonWidth: 170),
                        SizedBox(width: 16),
                        Expanded(
                          child: CupertinoTextField(
                            placeholder: 'EVENT NAME',
                            onChanged: (value) {
                              setState(() {
                                eventName = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        buildButtonRow('SET TAGS', () async {
                          /**
                          * Associates device with given [tags]. If setTags request fails tags will be resent on the next application launch.
                          * 
                          * PUSHWOOSH CODE 
                          *    |   |
                          *   _|   |_
                          *   \     /
                          *    \   /
                          *     \_/
                          */
                          Pushwoosh.getInstance.setTags({tagKey: tagValue});
                        }, buttonWidth: 170),
                        SizedBox(width: 16),
                        Expanded(
                          child: CupertinoTextField(
                            placeholder: 'KEY',
                            onChanged: (value) {
                              setState(() {
                                tagKey = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: CupertinoTextField(
                            placeholder: 'VALUE',
                            onChanged: (value) {
                              setState(() {
                                tagValue = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        buildButtonRow('SET LANGUAGE', () {
                          /**
                          * 'setLanguage(String language)' method
                          * 
                          * PUSHWOOSH CODE 
                          *    |   |
                          *   _|   |_
                          *   \     /
                          *    \   /
                          *     \_/
                          */
                          Pushwoosh.getInstance.setLanguage(language);
                        }, buttonWidth: 170),
                        SizedBox(width: 16),
                        Expanded(
                          child: CupertinoTextField(
                            placeholder: 'en',
                            onChanged: (value) {
                              setState(() {
                                language = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        buildButtonRow('SET EMAIL', () {
                          /**
                          * 'setEmail(String email)' method
                          * 
                          * PUSHWOOSH CODE 
                          *    |   |
                          *   _|   |_
                          *   \     /
                          *    \   /
                          *     \_/
                          */
                          Pushwoosh.getInstance.setEmail(email);
                        }, buttonWidth: 170),
                        SizedBox(width: 16),
                        Expanded(
                          child: CupertinoTextField(
                            placeholder: 'en',
                            onChanged: (value) {
                              setState(() {
                                email = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    buildButtonRow('GET HWID', () async {
                      showHWID();
                    }),
                    buildButtonRow('GET PUSH TOKEN', () async {
                      showToken();
                    }),
                    buildButtonRow('GET TAGS', () async {
                      /**
                      * Gets tags associated with current device

                      * PUSHWOOSH CODE 
                      *    |   |
                      *   _|   |_
                      *   \     /
                      *    \   /
                      *     \_/
                      */
                      Map<dynamic, dynamic> tags =
                          await Pushwoosh.getInstance.getTags();
                      String tagToString = tags.toString();
                      showAlert(context, 'TAGS', tagToString);
                    }),
                    buildButtonRow('RESET BADGES', () async {
                      /**
                      * PUSHWOOSH CODE 
                      *    |   |
                      *   _|   |_
                      *   \     /
                      *    \   /
                      *     \_/
                      */
                      Pushwoosh.getInstance.setApplicationIconBadgeNumber(0);
                    }),
                    buildButtonRow('GET APP CODE', () async {
                      /**
                      * PUSHWOOSH CODE
                      *    |   |
                      *   _|   |_
                      *   \     /
                      *    \   /
                      *     \_/
                      */
                      String? appCode = await Pushwoosh.getInstance.getAppCode;
                      showAlert(context, 'APP CODE', appCode ?? '(not set)');
                    }),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'REGION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    Text(
                      'Each button moves the application to another endpoint. The endpoint itself '
                      'shows up in the native SDK log ("Update base URL"), not here.',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    for (final (String label, String host) in _regions)
                      buildButtonRow(label, () async {
                        /**
                        * PUSHWOOSH CODE
                        *    |   |
                        *   _|   |_
                        *   \     /
                        *    \   /
                        *     \_/
                        */
                        try {
                          await Pushwoosh.getInstance
                              .setAppCode(_demoAppCode, baseUrl: host);
                        } on ArgumentError catch (error) {
                          if (!mounted) return;
                          showAlert(context, label, 'rejected: ${error.message}');
                          return;
                        } catch (error) {
                          if (!mounted) return;
                          showAlert(context, label, 'failed: $error');
                          return;
                        }
                        debugPrint('PW_REGION requested=$host appCode=$_demoAppCode');
                        if (!mounted) return;
                        showAlert(context, label, 'requested\n$_demoAppCode\n$host');
                      }),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'NATIVE IN-APP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    Text(
                      'Rendered locally via presentInApp() — no server needed.',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    for (final (String label, Map<String, dynamic> config)
                        in in_app_presets.all)
                      buildButtonRow(label, () {
                        /**
                        * PUSHWOOSH CODE
                        *    |   |
                        *   _|   |_
                        *   \     /
                        *    \   /
                        *     \_/
                        */
                        Pushwoosh.getInstance.presentInApp(config);
                      }),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'FOR HUAWEI DEVICES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    buildButtonRow('ENABLE HUAWEI NOTIFICATIONS', () async {
                      /**
                      * PUSHWOOSH CODE 
                      *    |   |
                      *   _|   |_
                      *   \     /
                      *    \   /
                      *     \_/
                      */
                      Pushwoosh.getInstance.enableHuaweiNotifications();
                    }),
                    buildButtonRow('START LOCATION TRACKING', () async {
                      /**
                      * PUSHWOOSH CODE 
                      *    |   |
                      *   _|   |_
                      *   \     /
                      *    \   /
                      *     \_/
                      */
                      PushwooshGeozones.startLocationTracking();
                    }),
                    buildButtonRow('STOP LOCATION TRACKING', () async {
                      /**
                      * PUSHWOOSH CODE 
                      *    |   |
                      *   _|   |_
                      *   \     /
                      *    \   /
                      *     \_/
                      */
                      PushwooshGeozones.stopLocationTracking();
                    }),
                    buildButtonRow('SHOW INBOX', () async {
                      /**
                      * PUSHWOOSH CODE 
                      *    |   |
                      *   _|   |_
                      *   \     /
                      *    \   /
                      *     \_/
                      */
                      _showInbox();
                    }),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notificationsEnabled
                          ? 'UNREGISTER FOR PUSH NOTIFICATIONS'
                          : 'REGISTER FOR PUSH NOTIFICATIONS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      onChanged:
                          _isRegistering ? null : registerForRemoteNotification,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SHOW FOREGROUND ALERT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: foregroundAlertEnabled,
                      onChanged: showForegroundAlert,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: buildButtonRow('GO TO LIVE ACTIVITIES (iOS)', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => StopwatchApp()),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: 'Live Activities',
          ),
        ],
        currentIndex: _tabController.index,
        selectedItemColor: Color.fromARGB(255, 25, 14, 184),
        onTap: (index) {
          setState(() {
            _tabController.index = index;
          });
        },
      ),
    );
  }
}

void _showInbox() {
  // Presented with the SDK's default appearance. To customize colors, images
  // and texts, pass a PWInboxStyle — see the pushwoosh_inbox README.
  PushwooshInbox.presentInboxUI();
}