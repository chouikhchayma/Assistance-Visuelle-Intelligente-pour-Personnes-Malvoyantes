import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  static Uint8List resizeImage(Uint8List imageData, {int width = 640, int height = 480}) {
    img.Image? image = img.decodeImage(imageData);
    if (image == null) return imageData;

    img.Image resized = img.copyResize(image, width: width, height: height);
    return Uint8List.fromList(img.encodeJpg(resized));
  }
}
