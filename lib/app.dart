import 'package:flutter/material.dart';
import 'package:flutter_food_assistant_ai/controllers/ai_controller.dart';
import 'package:flutter_food_assistant_ai/controllers/shared_preferences_controller.dart';
import 'package:flutter_food_assistant_ai/pages/home_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.sharedPreferencesController,
  });

  final SharedPreferencesController sharedPreferencesController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final aiController = AiController(const String.fromEnvironment('apiKey'));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Manrope',
      ),
      home: HomePage(
        aiController: aiController,
        sharedPreferencesController: widget.sharedPreferencesController,
      ),
    );
  }
}
