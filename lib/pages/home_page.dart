import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_food_assistant_ai/controllers/ai_controller.dart';
import 'package:flutter_food_assistant_ai/controllers/shared_preferences_controller.dart';
import 'package:flutter_food_assistant_ai/pages/food_gallery_page.dart';

enum Gender {
  male,
  female;
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.aiController,
    required this.sharedPreferencesController,
  });

  final AiController aiController;
  final SharedPreferencesController sharedPreferencesController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Gender gender = Gender.male;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  AiController get aiController => widget.aiController;
  SharedPreferencesController get sharedPrefsController =>
      widget.sharedPreferencesController;
  Map<int, int> weightToCaloriesConsumption = {};
  dynamic _error;
  bool _isLoading = false;
  int? weightTarget;
  int? caloriesTarget;

  @override
  void initState() {
    super.initState();

    _ageController.addListener(() {
      setState(() {});
    });
    _weightController.addListener(() {
      setState(() {});
    });
    _heightController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sharedPrefsController.hasEnteredTarget) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FoodGalleryPage(
              aiController: aiController,
              sharedPreferencesController: sharedPrefsController,
            ),
          ),
        );
      }
    });
  }

  bool get canSubmit =>
      !_isLoading &&
      _ageController.text.isNotEmpty &&
      _weightController.text.isNotEmpty &&
      _heightController.text.isNotEmpty;

  bool get canSaveTarget => weightTarget != null && caloriesTarget != null;

  Future<void> generateTargetCaloriesPerDay({
    required bool isMale,
    required int age,
    required int height,
    required int weight,
  }) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final answer = await aiController.runTextPrompt(
        prompt: 'I am a ${isMale ? 'male' : 'female'}, aged $age years old.'
            'My weight is $weight kilogram and I\'m $height cm tall.'
            'I want to reach an ideal BMI and wants to know the right calories '
            'per day needs for my body to reach that.'
            'Can you generate at most 3 options of ideal body weight for me and '
            'daily calories consumption I must consume every day to achieve that.'
            'The format should be a json consisting the ideal body weight and '
            'daily calories consumption. An example is '
            '{"result": [{"weight_in_kg": 60, "daily_calories_consumption": 3000}]}.'
            'Please only answer the json content and nothing else, I don\'t need '
            'any explanation from the answer as well.'
            'Thanks!',
      );
      if (answer == null) {
        throw Exception('no answer received!');
      }
      print('answer $answer');
      final jsonBody = answer.replaceAll('```json', '').replaceAll('```', '');
      final Map<String, dynamic> jsonDecoded = jsonDecode(jsonBody);
      final allResult = jsonDecoded['result'] as List;

      setState(() {
        weightToCaloriesConsumption = allResult.asMap().map(
              (k, v) => MapEntry(
                v['weight_in_kg'],
                v['daily_calories_consumption'],
              ),
            );
      });
    } catch (ex) {
      debugPrint(ex.toString());
      _error = ex;
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gemini AI Example Page',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (weightToCaloriesConsumption.isNotEmpty) ...[
              const Text(
                'Pick your weight and calories target',
              ),
              const SizedBox(
                height: 16,
              ),
              ...weightToCaloriesConsumption.keys.map(
                (weight) {
                  final isSelected = weightTarget == weight;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8.0,
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.black54,
                        ),
                      ),
                      title: Text(
                        'Weight: $weight kilogram',
                      ),
                      subtitle: Text(
                        'Calories target daily: ${weightToCaloriesConsumption[weight]} calories',
                      ),
                      onTap: () {
                        setState(() {
                          weightTarget = weight;
                          caloriesTarget = weightToCaloriesConsumption[weight];
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 16,
              ),
              SizedBox(
                width: double.infinity,
                child: MaterialButton(
                  onPressed: !canSaveTarget
                      ? null
                      : () async {
                          await sharedPrefsController.setHasEnteredTarget(true);
                          await sharedPrefsController.setWeight(weightTarget!);
                          await sharedPrefsController
                              .setTargetCaloriesPerDay(caloriesTarget!);

                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodGalleryPage(
                                  aiController: aiController,
                                  sharedPreferencesController:
                                      sharedPrefsController,
                                ),
                              ),
                            );
                          }
                        },
                  color: Colors.blue,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Save target',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ] else ...[
              const Text(
                'Gender',
              ),
              DropdownButton<Gender>(
                isExpanded: true,
                value: gender,
                items: Gender.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name),
                      ),
                    )
                    .toList(),
                onChanged: (newGender) {
                  if (newGender != null) {
                    setState(() {
                      gender = newGender;
                    });
                  }
                },
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Age (in years)',
                    hintText: 'Age (in years)'),
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Weight (in Kg)',
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Height (in cm)',
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              SizedBox(
                width: double.infinity,
                child: MaterialButton(
                  onPressed: !canSubmit
                      ? null
                      : () async {
                          await generateTargetCaloriesPerDay(
                            isMale: gender == Gender.male,
                            age: int.parse(_ageController.text),
                            height: int.parse(_heightController.text),
                            weight: int.parse(_weightController.text),
                          );
                        },
                  color: Colors.blue,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
