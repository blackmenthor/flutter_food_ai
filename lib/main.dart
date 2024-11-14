import 'package:flutter/material.dart';
import 'package:flutter_food_assistant_ai/app.dart';
import 'package:flutter_food_assistant_ai/controllers/shared_preferences_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefsController = SharedPreferencesController();
  await sharedPrefsController.init();
  runApp(
    MyApp(
      sharedPreferencesController: sharedPrefsController,
    ),
  );
}
