import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/bottom_navigation_provider.dart';
import 'package:studyvault/provider/search_provider.dart';
import 'package:studyvault/provider/subject_provider.dart';
import 'package:studyvault/provider/workspace_screen_provider.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/provider/onboarding_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/screens/splash_screen.dart';
import 'package:studyvault/services/share_handler_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await IsarService.instance.init();
  } catch (e, st) {
    AppLogger.error('main.IsarInit', e, st);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ShareHandlerService.instance.init(navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkspaceCounterProvider()),
        ChangeNotifierProvider(create: (context) => OnboardingProvider()),
        ChangeNotifierProvider(create: (context) => WorkspaceScreenProvider()),
        ChangeNotifierProvider(create: (context) => BottomNavigationProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => SubjectProvider()),
        ChangeNotifierProvider(create: (context) => SearchProvider()),
      ],
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
