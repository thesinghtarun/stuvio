import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/bottom_navigation_provider.dart';
import 'package:studyvault/provider/inner_banner_provider.dart';
import 'package:studyvault/provider/profile_provider.dart';
import 'package:studyvault/provider/search_provider.dart';
import 'package:studyvault/provider/share_overlay_provider.dart';
import 'package:studyvault/provider/subject_provider.dart';
import 'package:studyvault/provider/workspace_screen_provider.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/provider/onboarding_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/screens/splash_screen.dart';
import 'package:studyvault/services/share_handler_service.dart';
import 'package:studyvault/provider/inbox_provider.dart';

///Unit ID
///ca-app-pub-1345393972469011/3049217586
///App ID
///ca-app-pub-1345393972469011~7339248168
///
///NATIVE AD-------------------------------------------------------------------
///APP ID:-ca-app-pub-1345393972469011~7339248168
///UNIT ID:-ca-app-pub-1345393972469011/4027558652
///
///Deadline Native Ad: ca-app-pub-1345393972469011/3897736148
///Upcoming Native Ad: ca-app-pub-1345393972469011/6934963021
///Search Tab Banner Ad: ca-app-pub-1345393972469011/7836412936
///
///Search Tab Filters Native Ad: ca-app-pub-1345393972469011/6950706676

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await IsarService.instance.init();
  } catch (e, st) {
    AppLogger.error('main.IsarInit', e, st);
  }

  MobileAds.instance.initialize();

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
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider(create: (context) => InboxProvider()),
        ChangeNotifierProvider(create: (context) => InlineBannerProvider()),
        ChangeNotifierProvider(create: (context) => ShareOverlayProvider()),
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
