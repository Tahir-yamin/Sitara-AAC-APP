import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/antigravity_service.dart';
import 'services/session_tracker.dart';
import 'services/local_db_service.dart';
import 'services/analytics_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionTracker()),
        ChangeNotifierProvider(create: (_) => AntigravityService()),
        Provider(create: (_) => LocalDbService.instance),
        ProxyProvider<SessionTracker, AnalyticsService>(
          update: (context, tracker, previous) => AnalyticsService(childId: tracker.childId),
        ),
      ],
      child: const SitaraApp(),
    ),
  );
}
