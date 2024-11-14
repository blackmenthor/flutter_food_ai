import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

class AiController {
  AiController(
    String apiKey,
  ) {
    model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
  }

  late GenerativeModel model;

  Future<String?> runTextPrompt({
    required String prompt,
  }) async {
    final content = [
      Content.text(prompt),
    ];

    print('running prompt for $prompt');
    final response = await model.generateContent(content);
    print('response is ${response.text}');
    return response.text;
  }

  Future<String?> runTextAndImagePrompt({
    required String prompt,
    required String imagePath,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/png', imageBytes),
      ])
    ];

    print('running prompt for $prompt and image $imagePath');
    final response = await model.generateContent(content);
    print('response is ${response.text}');
    return response.text;
  }
}
