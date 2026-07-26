import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
    return LocaleProvider(
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
    );
  }
}
