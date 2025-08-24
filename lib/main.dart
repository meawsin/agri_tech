import 'package:agritech/auth_wrapper.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const AgriTechApp());
}

class AppState extends InheritedWidget {
  final Function(Locale) setLocale;
  const AppState({super.key, required this.setLocale, required super.child});
  static AppState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppState>();
  }
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class AgriTechApp extends StatefulWidget {
  const AgriTechApp({super.key});
  @override
  State<AgriTechApp> createState() => _AgriTechAppState();
}

class _AgriTechAppState extends State<AgriTechApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  void setLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppState(
      setLocale: setLocale,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AgriTech MVP',
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(primarySwatch: Colors.green, visualDensity: VisualDensity.adaptivePlatformDensity),
        home: const AuthWrapper(),
      ),
    );
  }
}