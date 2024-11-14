import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesController {
  late SharedPreferences prefs;

  final _hasEnteredTargetKey = 'HAS_ENTERED_TARGET';
  final _targetWeightPerDayKey = 'TARGET_WEIGHT_PER_DAY';
  final _targetCaloriesPerDayKey = 'TARGET_CALORIES_PER_DAY';

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  bool get hasEnteredTarget => prefs.getBool(_hasEnteredTargetKey) ?? false;

  Future<bool> setHasEnteredTarget(bool hasEnteredTarget) =>
      prefs.setBool(_hasEnteredTargetKey, hasEnteredTarget);

  int get targetCaloriesPerDay => prefs.getInt(_targetCaloriesPerDayKey) ?? 0;

  Future<bool> setTargetCaloriesPerDay(int targetCaloriesPerDay) =>
      prefs.setInt(_targetCaloriesPerDayKey, targetCaloriesPerDay);

  int get targetWeight => prefs.getInt(_targetWeightPerDayKey) ?? 0;

  Future<bool> setWeight(int targetWeight) =>
      prefs.setInt(_targetWeightPerDayKey, targetWeight);

  Future<bool> resetAll() async {
    return prefs.clear();
  }
}
