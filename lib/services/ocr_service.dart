import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer();

  /// Opens camera (or gallery on simulator), runs OCR, returns recognized text.
  /// Returns null if the user cancels.
  Future<String?> scanText({bool useGallery = false}) async {
    final source = useGallery ? ImageSource.gallery : ImageSource.camera;
    final image = await _picker.pickImage(source: source);

    if (image == null) return null;

    final inputImage = InputImage.fromFile(File(image.path));
    final recognized = await _recognizer.processImage(inputImage);

    return recognized.text.isEmpty ? null : recognized.text;
  }

  void dispose() {
    _recognizer.close();
  }
}
