import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

class Controlador extends StatefulWidget {
  const Controlador({super.key});

  @override
  State<Controlador> createState() => _ControladorState();
}

class _ControladorState extends State<Controlador> {

  

  List<Color> currentColors = [
    Colors.orange,
    Colors.green,
    Color(0xFF0D47A1),
    Colors.purple,
    Colors.yellow,
    Colors.blue,
    Colors.deepPurple,
    Colors.purpleAccent,
  ];

  @override
  Widget build(BuildContext context) {

  var  UART_SERVICE_UUID = "";
  var UART_RX_CHAR_UUID = "";
  var  UART_TX_CHAR_UUID = "";
  var  UART_SAFE_SIZE = 20;

  

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "RGB CONTROLLER",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.power_settings_new),
            iconSize: 32,
            color: Colors.red,
            onPressed: () {},
          ),
          

          
        ],
      ),
    );
  }
}
