import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_food_assistant_ai/controllers/ai_controller.dart';
import 'package:flutter_food_assistant_ai/controllers/shared_preferences_controller.dart';
import 'package:flutter_food_assistant_ai/pages/home_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class FoodGalleryPage extends StatefulWidget {
  const FoodGalleryPage({
    super.key,
    required this.aiController,
    required this.sharedPreferencesController,
  });

  final AiController aiController;
  final SharedPreferencesController sharedPreferencesController;

  @override
  State<FoodGalleryPage> createState() => _FoodGalleryPageState();
}

class _FoodGalleryPageState extends State<FoodGalleryPage> {
  AiController get aiController => widget.aiController;
  SharedPreferencesController get sharedPreferencesController =>
      widget.sharedPreferencesController;

  bool _isLoading = false;
  Map<String, int> imagesToCalories = {};
  int get totalCaloriesToGo {
    final allCaloriesToday = imagesToCalories.values.fold(0, (a, b) => a + b);
    return sharedPreferencesController.targetCaloriesPerDay - allCaloriesToday;
  }

  final now = DateTime.now();
  String get formattedToday {
    final format = DateFormat.yMMMd();
    return format.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Food Gallery page',
        ),
        actions: [
          InkWell(
            onTap: () async {
              await sharedPreferencesController.resetAll();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      aiController: aiController,
                      sharedPreferencesController: sharedPreferencesController,
                    ),
                  ),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
              ),
              child: Text(
                'Reset',
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today is $formattedToday',
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(
              'Your target weight is ${sharedPreferencesController.targetWeight} Kg',
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(
              'Your target calories per day is ${sharedPreferencesController.targetCaloriesPerDay} calories',
            ),
            const SizedBox(
              height: 8.0,
            ),
            if (totalCaloriesToGo > 0) ...[
              Text(
                'You need $totalCaloriesToGo calories left for today!',
              ),
            ] else if (totalCaloriesToGo == 0) ...[
              const Text(
                'Well done!',
              ),
            ] else if (totalCaloriesToGo < 0) ...[
              const Text(
                'You are already over your calories consumption for the day!',
              ),
            ],
            const SizedBox(
              height: 16.0,
            ),
            if (imagesToCalories.isNotEmpty) ...[
              const Text(
                'Foods you ate today:',
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: ListView(
                  children: imagesToCalories.keys
                      .map(
                        (imagePath) => ListTile(
                          title: Align(
                            alignment: Alignment.centerLeft,
                            child: Image.file(
                              File(imagePath),
                            ),
                          ),
                          subtitle: Text(
                            'Total calories: ${imagesToCalories[imagePath]} calories.',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ] else ...[
              const Spacer(),
            ],
            const SizedBox(
              height: 16.0,
            ),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                color: Colors.blue,
                onPressed: _isLoading
                    ? null
                    : () async {
                        try {
                          setState(() {
                            _isLoading = true;
                          });
                          final result = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (result != null) {
                            print(result.path);
                            const prompt =
                                'Hi, can you get from this image roughly '
                                'how many calories will I get if I eat this. '
                                'Can you send the result in a form of json for '
                                'each item in this plate such as '
                                '{"items": [{"name": "rice", "calories":100}], "total_calories": 2000}. '
                                'Please answer only the json and without any other explanation. '
                                'Thanks!';

                            final answer =
                                await aiController.runTextAndImagePrompt(
                              prompt: prompt,
                              imagePath: result.path,
                            );
                            if (answer == null) {
                              throw Exception('no answer received!');
                            }
                            print('answer $answer');
                            final jsonBody = answer
                                .replaceAll('```json', '')
                                .replaceAll('```', '');
                            final Map<String, dynamic> jsonDecoded =
                                jsonDecode(jsonBody);

                            print(jsonDecoded);
                            final totalCalories = jsonDecoded['total_calories'];

                            imagesToCalories[result.path] = totalCalories;
                          }
                        } catch (ex) {
                          print(ex.toString());
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Upload image',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
