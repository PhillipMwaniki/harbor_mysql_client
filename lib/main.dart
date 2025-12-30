import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/main_screen.dart';
import 'providers/database_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: HarborApp(),
    ),
  );
}

class HarborApp extends ConsumerStatefulWidget {
  const HarborApp({super.key});

  @override
  ConsumerState<HarborApp> createState() => _HarborAppState();
}

class _HarborAppState extends ConsumerState<HarborApp> {
  @override
  void initState() {
    super.initState();
    // Load saved connections on startup
    Future.microtask(() {
      ref.read(savedConnectionsProvider.notifier).loadConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harbor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
