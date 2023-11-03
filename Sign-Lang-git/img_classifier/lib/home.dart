import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as IMG;
import 'dart:typed_data';
import 'dart:io' as IO;

import 'main.dart';

void loadDetectionModel() async {
  Tflite.close();
  try {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
    print("Loaded model successfully");
  } on Exception catch (e) {
    print("Failed to load model: " + e.toString());
  }
}

Uint8List imageToByteListFloat32(
    IMG.Image img, int inputSize, double mean, double std) {
  var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < inputSize; i++) {
    for (var j = 0; j < inputSize; j++) {
      var pixel = img.getPixel(j, i);
      buffer[pixelIndex++] = (IMG.getRed(pixel) - mean) / std;
      buffer[pixelIndex++] = (IMG.getGreen(pixel) - mean) / std;
      buffer[pixelIndex++] = (IMG.getBlue(pixel) - mean) / std;
    }
  }
  return convertedBytes.buffer.asUint8List();
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
  Image? img;
  String? pictureResult = "";

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
        setState(() {});
      }
    });
    // cameraController!.setFlashMode(FlashMode.off);
  }

  Future<String?> takePicture() async {
    try {
      XFile file = await cameraController!.takePicture();
      Uint8List bytes = await file.readAsBytes();
      IMG.Image? src = IMG.decodeImage(bytes);

      if (src != null) {
        IMG.Image destImage = IMG.copyCrop(
            src, src.width ~/ 2 - 64, src.height ~/ 2 - 64, 128, 128);
        IMG.Image resizedImage =
            IMG.copyResize(destImage, width: 64, height: 64);
        IO.File('/storage/emulated/0/Pictures/Sign Language/${DateTime.now().millisecondsSinceEpoch}.jpg')
            .writeAsBytesSync(IMG.encodeJpg(resizedImage));

        var res = await Tflite.runModelOnBinary(
            binary: imageToByteListFloat32(resizedImage, 64, 0.0, 255.0),
            numResults: 29);

        print("REEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEESULT:\n $res");
        return res![0]["label"];
      }
    } catch (e) {
      print("runModelError: $e");
    }
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
                      child: Stack(
                        children: <Widget>[
                          CameraPreview(cameraController!),
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, -28),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        Colors.red, // You can change the color
                                    width:
                                        2.0, // You can change the border width
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
          // Add text box to print the current value of pictureResult
          Text(
            pictureResult ?? "",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              takePicture().then((result) {
                // You can use the result here to update the UI.
                // In this example, we will use setState to update the UI.
                setState(() {
                  pictureResult = result;
                });
              });
            },
            child: const Text('Take Picture'),
          ),
        ],
      ),
    );
  }
}
