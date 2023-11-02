import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'main.dart';
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';

  @override
  initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  late Interpreter interpreter;
  loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/model.tflite');
  }


  // runModel() async {
  //   if(cameraImage != null) {
  //     var predictions = await Tflite.runModelOnFrame(bytesList: cameraImage!.planes.map((plane) {
  //       return plane.bytes;
  //     }).toList(),
  //       imageHeight: cameraImage!.height,
  //       imageWidth: cameraImage!.width,
  //       imageMean: 127.5,
  //       imageStd: 127.5,
  //       rotation: 90,
  //       numResults: 2,
  //       threshold:0.1,
  //       asynch: true,
  //     );
  //
  //     predictions!.forEach((element) {
  //       setState(() {
  //         output = element['label'];
  //       });
  //     });
  //   }
  // }

  loadCamera(){
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if(!mounted){
        return;
      }
      else{
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage = imageStream;
            // runModel();
          });
        });
      }
    });
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
              
              child: !cameraController!.value.isInitialized ?
              Container() :
              AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Text(
            output,
            style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
