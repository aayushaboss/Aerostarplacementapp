import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/repositories.dart';
import 'mockData/catalog_loader.dart';
import 'router.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The job and course catalogue (spreadsheet data) must be ready before any screen reads it.
  await loadCatalog();
  // Portrait only — this is a phone-shaped experience and landscape adds
  // nothing. Covers native Android/iOS; on web it's a no-op (web/index.html
  // and web/manifest.json handle the browser + installed-PWA cases).
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  // Every page is white or solid blue, so status-bar icons are dark by
  // default; screens may still override with their own AnnotatedRegion.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const AerostarEdgeApp());
}

class AerostarEdgeApp extends StatefulWidget {
  const AerostarEdgeApp({super.key});

  @override
  State<AerostarEdgeApp> createState() => _AerostarEdgeAppState();
}

class _AerostarEdgeAppState extends State<AerostarEdgeApp> {
  late final Repositories _repositories;
  late final AppState _appState;
  late final GoRouter _router;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _repositories = buildRepositories();
    _appState = AppState(authRepository: _repositories.auth)..bootstrap();
    _router = buildRouter(_appState, _scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appState),
        Provider<Repositories>.value(value: _repositories),
      ],
      child: MaterialApp.router(
        title: 'Aerostar Edge',
        // On web this becomes the page's <meta name="theme-color"> (the mobile
        // browser toolbar / task-switcher colour). Without it Flutter falls back
        // to the theme's primary colour, which is the Aerostar blue.
        color: AppColors.white,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        routerConfig: _router,
        // GlobalCupertinoLocalizations isn't included by MaterialApp's own
        // defaults — needed for CupertinoDatePicker (the wheel-style date
        // picker), which throws on build without it.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
