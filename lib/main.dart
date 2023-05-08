import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../AppTheme.dart';
import '../Store/AppStore.dart';
import '../app_localizations.dart';
import '../model/LanguageModel.dart';
import '../screen/DataScreen.dart';
import '../utils/common.dart';
import '../utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'component/NoInternetConnection.dart';
import 'package:rate_my_app/rate_my_app.dart';

AppStore appStore = AppStore();

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF8B47b3)
  ));
  WidgetsFlutterBinding.ensureInitialized();
  // await FlutterDownloader.initialize(debug: true);
  HttpOverrides.global = HttpOverridesSkipCertificate();
  await initialize();
  appStore.setDarkMode(aIsDarkMode: getBoolAsync(isDarkModeOnPref));
  appStore.setLanguage(getStringAsync(APP_LANGUAGE, defaultValue: 'en'));

  if (isMobile) {
    MobileAds.instance.initialize();
    await OneSignal.shared.setAppId(getStringAsync(ONESINGLE, defaultValue: mOneSignalID));
    OneSignal.shared.consentGranted(true);
    OneSignal.shared.promptUserForPushNotificationPermission();
  }
  runApp(MyApp());

  WidgetsFlutterBinding
      .ensureInitialized(); // This allows to use async methods in the main method without any problem.
  runApp(const _RateMyAppTestApp());
}
/// The body of the main Rate my app test widget.
class _RateMyAppTestApp extends StatefulWidget {
  /// Creates a new Rate my app test app instance.
  const _RateMyAppTestApp();

  @override
  State<StatefulWidget> createState() => _RateMyAppTestAppState();
}

/// The body state of the main Rate my app test widget.
class _RateMyAppTestAppState extends State<_RateMyAppTestApp> {
  /// The widget builder.
  WidgetBuilder builder = buildProgressIndicator;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Rate my app !'),
      ),
      body: RateMyAppBuilder(
        builder: builder,
        onInitialized: (context, rateMyApp) {
          setState(() =>
          builder = (context) => ContentWidget(rateMyApp: rateMyApp));
          rateMyApp.conditions.forEach((condition) {
            if (condition is DebuggableCondition) {
              print(condition
                  .valuesAsString); // We iterate through our list of conditions and we print all debuggable ones.
            }
          });

          print('Are all conditions met ? ' +
              (rateMyApp.shouldOpenDialog ? 'Yes' : 'No'));

          if (rateMyApp.shouldOpenDialog) {
            rateMyApp.showRateDialog(context);
          }
        },
      ),
    ),
  );

  /// Builds the progress indicator, allowing to wait for Rate my app to initialize.
  static Widget buildProgressIndicator(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class MyApp extends StatefulWidget {
  MyApp();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    setStatusBarColor(appStore.primaryColors, statusBarBrightness: Brightness.light);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((e) async {
      appStore.setConnectionState(e);
      if (e == ConnectivityResult.none) {
        log('not connected');
        push(NoInternetConnection());
      } else {
        pop();
        log('connected');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: appStore.isNetworkAvailable ? DataScreen() : NoInternetConnection(),
        supportedLocales: Language.languagesLocale(),
        navigatorKey: navigatorKey,
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        localeResolutionCallback: (locale, supportedLocales) => locale,
        locale: Locale(getStringAsync(APP_LANGUAGE, defaultValue: 'en')),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appStore.isDarkModeOn! ? ThemeMode.dark : ThemeMode.light,
        scrollBehavior: SBehavior(),
      );
    });
  }
}
