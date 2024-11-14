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
          'Calorie Intake',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
            Center(
              child: Image.asset(
                'assets/images/user.png',
                height: 128,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const Center(
              child: Text(
                'Angga, 29',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'Your ideal weight is ${sharedPreferencesController.targetWeight} kg. ',
                    ),
                    if (totalCaloriesToGo > 0) ...[
                      TextSpan(
                        text:
                            'You have $totalCaloriesToGo calories left today.',
                      ),
                    ] else if (totalCaloriesToGo == 0) ...[
                      const TextSpan(
                        text: 'You have all your calories for today!',
                      ),
                    ] else ...[
                      TextSpan(
                        text:
                            'You have ${totalCaloriesToGo.abs()} calories over for today!',
                      ),
                    ],
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                            final jsonBody = answer
                                .replaceAll('```json', '')
                                .replaceAll('```', '');
                            final Map<String, dynamic> jsonDecoded =
                                jsonDecode(jsonBody);

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
                        'Add food image',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                children: imagesToCalories.keys
                    .map(
                      (imagePath) => Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(imagePath),
                            ),
                          ),
                          Text(
                            '${imagesToCalories[imagePath]} calories.',
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
          ],
        ),
      ),
    );
  }
}
