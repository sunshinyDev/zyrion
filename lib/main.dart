import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/models/iptv_provider.dart';
import 'core/models/profile.dart';
import 'core/providers/iptv_provider.dart' as iptv;
import 'core/providers/profile_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/profile_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase already initialized: $e');
  }

  // Init auth notifier BEFORE container
  authNotifier = AuthNotifier();
  await authNotifier.init();

  // Load saved IPTV provider
  final savedProvider = await IptvProvider.load();

  // Restore active profile
  AppProfile? savedProfile;
  if (savedProvider != null) {
    final savedProfileId = await loadActiveProfileId();
    if (savedProfileId != null) {
      try {
        final svc = ProfileService(savedProvider.providerCode);
        final profiles = await svc.getProfiles();
        savedProfile =
            profiles.where((p) => p.id == savedProfileId).firstOrNull;
      } catch (e) {
        debugPrint('Could not restore profile: $e');
      }
    }
  }

  // Seed Riverpod container with all saved state before first frame
  final container = ProviderContainer();

  if (savedProvider != null) {
    container.read(iptv.iptvProviderDataProvider.notifier).state =
        savedProvider;
  }

  if (savedProfile != null) {
    container.read(activeProfileProvider.notifier).state = savedProfile;
    // Also sync global notifier so router redirect works
    profileNotifier.setProfile(savedProfile);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ZyrionApp(),
    ),
  );
}

class ZyrionApp extends ConsumerStatefulWidget {
  const ZyrionApp({super.key});

  @override
  ConsumerState<ZyrionApp> createState() => _ZyrionAppState();
}

class _ZyrionAppState extends ConsumerState<ZyrionApp> {
  @override
  void initState() {
    super.initState();
    // Keep Riverpod activeProfileProvider in sync with global profileNotifier
    profileNotifier.addListener(_syncProfile);
  }

  @override
  void dispose() {
    profileNotifier.removeListener(_syncProfile);
    super.dispose();
  }

  void _syncProfile() {
    final p = profileNotifier.profile;
    if (ref.read(activeProfileProvider) != p) {
      ref.read(activeProfileProvider.notifier).state = p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Zyrion Play',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
