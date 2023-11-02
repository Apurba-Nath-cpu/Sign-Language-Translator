import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as image;
import 'dart:typed_data';

import 'main.dart';

void loadDetectionModel() async {
  Tflite.close();
  try {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
    print("Loaded model successfully");
    TestModel();
  } on Exception catch (e) {
    print("Failed to load model: " + e.toString());
  }
}

Future<image.Image> addAndResize(String s) async {
  var img = Image.asset(
    s,
    width: 64,
    height: 64,
  );
  ByteData testImg = (await rootBundle.load(s));
  image.Image? baseSizeImage = image.decodeImage(testImg.buffer.asUint8List());
  return image.copyResize(baseSizeImage!, height: 64, width: 64);
}

Uint8List imageToByteListFloat32(
    image.Image img, int inputSize, double mean, double std) {
  var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < inputSize; i++) {
    for (var j = 0; j < inputSize; j++) {
      var pixel = img.getPixel(j, i);
      buffer[pixelIndex++] = (image.getRed(pixel) - mean) / std;
      buffer[pixelIndex++] = (image.getGreen(pixel) - mean) / std;
      buffer[pixelIndex++] = (image.getBlue(pixel) - mean) / std;
    }
  }
  return convertedBytes.buffer.asUint8List();
}

void TestModel() async {
  image.Image resizeImage;
  // image.copyResize(img, width: 64, height: 64);
  // var out = await Tflite.runModelOnBinary(binary: binary)
  try {
    var res;
    String ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    int score = 0;
    for (int i = 0; i < 26; i++) {
      String imgSrc = "assets/images/" + ALPHA[i] + "_test.jpg";
      // To run model, first use the addAndResize to
      resizeImage = await addAndResize(imgSrc);
      res = await Tflite.runModelOnBinary(
          binary: imageToByteListFloat32(resizeImage, 64, 0.0, 255.0),
          numResults: 29);
      if (res[0]['label'] == ALPHA[i]) {
        score++;
      }
    }
    print("Model Score: " + ((score / 26) * 100).toString() + "%");
  } catch (e) {
    print("runModelError: " + e.toString());
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  Image? image;

  @override
  initState() {
    super.initState();
    loadCamera();
    loadDetectionModel();
  }

  loadCamera() {
    cameraController = CameraController(
      cameras![0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage = imageStream;
            // runModel();
          });
        });
      }
    });
  }

  Future<void> takePicture() async {
    XFile file = await cameraController!.takePicture();
    image = Image.memory(await file.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Live Sign Language Translation')),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            output,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          ElevatedButton(
            onPressed: takePicture,
            child: const Text('Take Picture'),
          ),
        ],
      ),
    );
  }
}
