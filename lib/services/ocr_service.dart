import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {

  Future<String> extractText(String imagePath) async {

    final inputImage = InputImage.fromFilePath(imagePath);

    final recognizer =
    TextRecognizer(script: TextRecognitionScript.latin);

    final result =
    await recognizer.processImage(inputImage);

    recognizer.close();

    return result.text;
  }
}