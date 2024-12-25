import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tray Calorie Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final picker = ImagePicker();
  final random = Random();
  List<Uint8List> images = [];
  List<Map<String, dynamic>> predictions = [];
  int totalCalories = 0;
  int totalPrice = 0;

  void _imgFromGallery() async {
    List<XFile>? files = await picker.pickMultiImage(imageQuality: 50);
    if (files != null) {
      for (var element in files) {
        images.add(await element.readAsBytes());
      }
      setState(() {});
    }
  }

  void _sendImageToServer() async {
    if (images.isNotEmpty) {
      try {
        var uri = Uri.parse("http://127.0.0.1:5000/predict");
        var request = http.MultipartRequest('POST', uri);

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            images[0],
            filename: 'image.jpg',
            contentType: MediaType('image', 'jpg'),
          ),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseString = await response.stream.bytesToString();
          Map<String, dynamic> valueMap = json.decode(responseString);

          predictions = ((valueMap['predictions'] as List<dynamic>)
              .map((e) => {
                    'name': e['name'] as String,
                    'price': e['name'] == "corba"
                        ? 26
                        : e['name'] == "ana_yemek"
                            ? 53
                            : 35,
                    'calories': random.nextInt(150) + 100,
                  })
              .toList());

          totalCalories =
              predictions.fold(0, (sum, item) => sum + item['calories'] as int);
          totalPrice =
              predictions.fold(0, (sum, item) => sum + item['price'] as int);

          setState(() {});
        } else {
          print('Failed to send image');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  Widget getUi() {
    return predictions.isNotEmpty ? getTable() : pickImgUi();
  }

  

  Widget pickImgUi() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          onPressed: _imgFromGallery,
          child: const Text("Pick Image"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        if (images.isNotEmpty)
          Column(
            children: List.generate(
              images.length,
              (index) => Container(
                margin: const EdgeInsets.all(8),
                child: Image.memory(
                  images[index],
                  height: 120,
                  width: 120,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _sendImageToServer,
          child: const Text("Analyze Image"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16),
            backgroundColor: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget getTable() {
    return Column(
      children: [
        if (images.isNotEmpty)
          Column(
            children: images.map((img) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Image.memory(
                  img,
                  height: 150,
                  width: 150,
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        Card(
          elevation: 5,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.teal.shade50),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Food Type",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Price",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Calories",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                ...predictions.map(
                  (item) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(item['name'], textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("${item['price']}",
                            textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("${item['calories']}",
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
                TableRow(
                  decoration: BoxDecoration(color: Colors.teal.shade100),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Total",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "$totalPrice",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "$totalCalories",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Food Calorie Tracker")),
      body: SingleChildScrollView(
        child: Center(
          child: getUi(),
        ),
      ),
    );
  }
}
