import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/setup_screen.dart';
import 'state/match_controller.dart';
import 'theme/usa94_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = MatchController();
  await controller.init();
  runApp(KalmaApp(controller: controller));
}

class KalmaApp extends StatelessWidget {
  const KalmaApp({super.key, required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        title: 'كلمة وبس',
        debugShowCheckedModeBanner: false,
        theme: buildUsa94Theme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const ShellScreen(),
      ),
    );
  }
}

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/app-icon-192.png',
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'كلمة '),
                      TextSpan(
                        text: 'وبس',
                        style: TextStyle(color: Usa94Colors.red),
                      ),
                    ],
                  ),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                Text(
                  'THE ONE-WORD CUP',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.2,
                    color: Usa94Colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                'USA • 1994',
                style: TextStyle(
                  color: Usa94Colors.royal,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(7),
          child: Container(
            height: 7,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Usa94Colors.royal,
                  Usa94Colors.royal,
                  Usa94Colors.paper,
                  Usa94Colors.red,
                  Usa94Colors.red,
                ],
                stops: [0, 0.45, 0.48, 0.52, 1],
              ),
            ),
          ),
        ),
      ),
      body: switch (ctrl.view) {
        AppView.home => const HomeScreen(),
        AppView.setup => const SetupScreen(),
        AppView.match => const MatchScreen(),
      },
    );
  }
}
