import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/l10n/app_localizations.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const NenoSmartLifeApp());
}

class NenoSmartLifeApp extends StatelessWidget {
  const NenoSmartLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      child: LocaleProvider(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              title: 'Neno SmartLife',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const SplashScreen(),
              onGenerateRoute: AppRouter.generateRoute,
            );
          },
        ),
      ),
    );
  }
}
