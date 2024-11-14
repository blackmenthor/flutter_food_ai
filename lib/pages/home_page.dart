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

  List<Widget> _firstFlow(BuildContext context) {
    return [
      const SizedBox(
        height: 52,
      ),
      const Center(
        child: Text(
          'Calculate Ideal Weight',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(
        height: 12.0,
      ),
      const Center(
        child: Text(
          'We use AI to help you find the best weight for your body.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ),
      const SizedBox(
        height: 12.0,
      ),
      const Text(
        'Gender',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      const SizedBox(
        height: 8.0,
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<Gender>(
          isExpanded: true,
          value: gender,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          underline: const SizedBox.shrink(),
          items: Gender.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.name,
                  ),
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
      ),
      const SizedBox(
        height: 12.0,
      ),
      const Text(
        'Age',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      const SizedBox(
        height: 8.0,
      ),
      TextField(
        controller: _ageController,
        decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.black12,
            filled: true,
            labelText: 'Age (in years)',
            hintText: 'Age (in years)'),
      ),
      const SizedBox(
        height: 12,
      ),
      const Text(
        'Weight',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      const SizedBox(
        height: 8.0,
      ),
      TextField(
        controller: _weightController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.black12,
          filled: true,
          labelText: 'Weight (in Kg)',
        ),
      ),
      const SizedBox(
        height: 12,
      ),
      const Text(
        'Height',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      const SizedBox(
        height: 8.0,
      ),
      TextField(
        controller: _heightController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.black12,
          filled: true,
          labelText: 'Height (in cm)',
        ),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: MaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
          padding: const EdgeInsets.all(8),
          color: Colors.blue,
          disabledColor: Colors.blue.withOpacity(0.25),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : const Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      const SizedBox(
        height: 8,
      ),
    ];
  }

  List<Widget> _secondFlow(BuildContext context) {
    return [
      const SizedBox(
        height: 52.0,
      ),
      const Center(
        child: Text(
          'Set Your Goals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(
        height: 32.0,
      ),
      const Center(
        child: Text(
          'What\'s your goal?',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(
        height: 12,
      ),
      const Center(
        child: Text(
          'Choose a weight loss or gain plan. You can adjust it later.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.0,
          ),
        ),
      ),
      const SizedBox(
        height: 16,
      ),
      ...weightToCaloriesConsumption.keys.map(
        (weight) {
          final isSelected = weightTarget == weight;

          return Container(
            margin: const EdgeInsets.only(
              bottom: 16,
            ),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.25) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  weightTarget = weight;
                  caloriesTarget = weightToCaloriesConsumption[weight];
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$weight kilogram',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Suggested daily calories: ${weightToCaloriesConsumption[weight]} calories',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Image.asset(
                      'assets/images/weight_2.png',
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
      const Spacer(),
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
                          sharedPreferencesController: sharedPrefsController,
                        ),
                      ),
                    );
                  }
                },
          color: Colors.blue,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      const SizedBox(
        height: 8,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (weightToCaloriesConsumption.isNotEmpty) ...[
                ..._secondFlow(context),
              ] else ...[
                ..._firstFlow(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
