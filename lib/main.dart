/*
//import 'package:controller_leds/controlador.dart';
//import 'dart:typed_data';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ControllerLeds());
  }
}

class ControllerLeds extends StatefulWidget {
  const ControllerLeds({super.key});

  @override
  State<ControllerLeds> createState() => _ControllerLedsState();
}

class _ControllerLedsState extends State<ControllerLeds> {
  List<ScanResult> resultadosEscaneo = [];
  List<int> lista = [];
  int estado = 0;
  bool encendido = true;
  BluetoothCharacteristic? txCharacteristic;

  void escanear() async {
    // Comprobamos si soporta bluetooh
    

    if (await FlutterBluePlus.isSupported == false) {
      //print("Bluetooth no soportado en el dispositivo");
      var snackBar = SnackBar(
        content: Text('Bluetooth no soportado en el dispositivo'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    // Eliminamos los resultados del escaneo
    setState(() {
      resultadosEscaneo.clear();
    });

    // Escaneamos los dispositivos con bluetooh a los que podemos conectarnos y los guardamos en una lista
    var subscription = FlutterBluePlus.onScanResults.listen((resultados) {
      setState(() {
        resultadosEscaneo = resultados;
      });
    }, onError: (e) => print("Error en el stream"));

    await FlutterBluePlus.startScan();

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    subscription.cancel();
  }

  Future<void> conectar(BluetoothDevice device) async {
    try {
      // 1. Detener escaneo antes de conectar
      await FlutterBluePlus.stopScan();

      // 2. Conectar
      await device.connect(license: License.free);

      obtenerCaracteristica(device);

      //print("Conectado a ${device.platformName}");
      var snackBar = SnackBar(
        content: Text('Conectado ${device.platformName}'),
        duration: Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      //eliminamos los resultados del escaneo
      setState(() {
        resultadosEscaneo.clear();
      });

      

      /*
      Navigator.push(
        context, MaterialPageRoute<void>(
                builder: (context) => const Controlador(),
        ),
      );
      */

      // 3. Navegar a pantalla de servicios o manejar la conexión
      // Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceScreen(device: device)));
    } catch (e) {
      var snackBar = SnackBar(content: Text('Error de conexión: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> obtenerCaracteristica(BluetoothDevice device) async {
    
    try {
      await FlutterBluePlus.stopScan();
      //await device.connect(license: License.free);

      // 1. Descubrir servicios
      List<BluetoothService> services = await device.discoverServices();

      // 2. Buscar la característica específica (ejemplo FFD9)
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains("FFD9")) {
            setState(() {
              txCharacteristic = characteristic;
            });
          }
        }
      }
      

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado y característica encontrada')),
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  void cambiarEncender(String state) {
    if (state == 'Off') {
      setState(() {
        encendido = false;
        estado = 0x24;
      });
    } else {
      setState(() {
        encendido = true;
        estado = 0x23;
      });
    }
    
    realizarAccion(Uint8List.fromList([0xCC, estado, 0x33]));
  }

  void formatear(Color color) {
    int formato = color.value32bit;
    int cociente = formato;
    List<int> resultado = [];
    for (int i = 0; i < 8; i++) {
      resultado.add(cociente % 16);
      cociente = cociente ~/ 16;
    }
    List<int> invertidos = resultado.reversed.toList();
    String comprobar = invertidos.toString();
    String definitivo = comprobar.replaceAll(',', '');
    definitivo = definitivo.replaceAll(' ', '');
    var intensidad = definitivo.substring(0, 2);
    String rojo = definitivo.substring(2,4);
    rojo = '0x' + rojo;
    String verde = definitivo.substring(4,6);
    verde = '0x' + verde;
    String azul = definitivo.substring(6,8);
    azul = '0x' + azul;


    List<int> rgb = Uint8List.fromList([int.parse(rojo), int.parse(verde), int.parse(azul)]);
    

    var snackBar = SnackBar(content: Text('$rgb', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    realizarAccion(Uint8List.fromList([0x56, rgb[0], rgb[1], rgb[2], 0x00, 0xF0, 0xAA]));
  }


  Future<void> realizarAccion(List<int> lista) async {
    // 1. Definir los bytes (Uint8List es List<int>, así que es compatible)

    try {
      // 2. Verificar si la característica está lista
      /*
      for(txCharacteristic in txtCharacteristic) {
        if (txCharacteristic == null) {
          throw Exception("La característica Bluetooth no está inicializada");
        }
      }*/

      

      // 3. Intentar la escritura
      // Nota: Intenta primero con withoutResponse: false si el true falla
      
      await txCharacteristic!.write(lista, withoutResponse: false);

      // 4. Feedback visual
      
    } catch (e) {
      //print("DEBUG ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al enviar: $e',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Escanear dispositivods",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: escanear,
                child: const Text("Buscar Dispositivos"),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: resultadosEscaneo.length,
                itemBuilder: (context, index) {
                  final data = resultadosEscaneo[index];
                  return ListTile(
                    title: Text(
                      data.device.platformName.isEmpty
                          ? "Dispositivo desconocido"
                          : data.device.platformName,
                    ),
                    subtitle: Text(data.device.remoteId.toString()),
                    trailing: Text("${data.rssi} dBm"),
                    onTap: () => conectar(data.device),
                  );
                },
              ),
              SizedBox(height: 16),
              IconButton(
                icon: Icon(Icons.power_settings_new),
                iconSize: 32,
                color: encendido == true ? Colors.red : Colors.green,
                onPressed: () => encendido == true
                    ? cambiarEncender('Off')
                    : cambiarEncender('On'),
              ),
              SizedBox(height: 16),
              ColorPicker(
                enableShadesSelection: true,
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.both: false,
                  ColorPickerType.primary: true,
                  ColorPickerType.accent: false,
                  ColorPickerType.bw: false,
                  ColorPickerType.custom: false,
                  ColorPickerType.wheel: true,
                },
                onColorChanged: (Color color) => formatear(color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

/*
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ControllerLeds(),
    );
  }
}

class ControllerLeds extends StatefulWidget {
  const ControllerLeds({super.key});

  @override
  State<ControllerLeds> createState() => _ControllerLedsState();
}

class _ControllerLedsState extends State<ControllerLeds> {
  List<ScanResult> resultadosEscaneo = [];
  BluetoothCharacteristic? txCharacteristic;
  bool encendido = true;

  /* ===================== SCAN ===================== */

  Future<void> escanear() async {
    if (!await FlutterBluePlus.isSupported) {
      _mostrarSnack("Bluetooth no soportado");
      return;
    }

    resultadosEscaneo.clear();
    setState(() {});

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) => setState(() => resultadosEscaneo = results),
      onError: (_) => _mostrarSnack("Error en escaneo"),
    );

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await FlutterBluePlus.isScanning.where((val) => !val).first;
    await subscription.cancel();
  }

  /* ===================== CONEXIÓN ===================== */

  Future<void> conectar(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(license: License.free);

      await _obtenerCaracteristica(device);

      resultadosEscaneo.clear();
      setState(() {});

      _mostrarSnack("Conectado a ${device.platformName}");
    } catch (e) {
      _mostrarSnack("Error de conexión: $e", error: true);
    }
  }

  Future<void> _obtenerCaracteristica(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toUpperCase().contains("FFD9")) {
          txCharacteristic = characteristic;
          _mostrarSnack("Característica encontrada");
          return;
        }
      }
    }

    _mostrarSnack("Característica no encontrada", error: true);
  }

  /* ===================== ACCIONES ===================== */

  void cambiarEncender() {
    encendido = !encendido;
    setState(() {});

    int estado = encendido ? 0x23 : 0x24;
    _enviarComando([0xCC, estado, 0x33]);
  }

  void formatear(Color color) {
    int rojo = (color.r * 255.0).round().clamp(0, 255);
    int verde = (color.g * 255.0).round().clamp(0, 255);
    int azul = (color.b * 255.0).round().clamp(0, 255);

   // _mostrarSnack("RGB: [$rojo, $verde, $azul]");

    _enviarComando([0x56, rojo, verde, azul, 0x00, 0xF0, 0xAA]);
  }

  Future<void> _enviarComando(List<int> datos) async {
    if (txCharacteristic == null) {
      _mostrarSnack("No conectado al dispositivo", error: true);
      return;
    }

    try {
      await txCharacteristic!.write(
        Uint8List.fromList(datos),
        withoutResponse: false,
      );
    } catch (e) {
      _mostrarSnack("Error al enviar: $e", error: true);
    }
  }

  /* ===================== UI ===================== */

  void _mostrarSnack(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: error ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Escanear dispositivos",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: escanear,
              child: const Text("Buscar dispositivos"),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resultadosEscaneo.length,
              itemBuilder: (context, index) {
                final data = resultadosEscaneo[index];
                return ListTile(
                  title: Text(
                    data.device.platformName.isEmpty
                        ? "Dispositivo desconocido"
                        : data.device.platformName,
                  ),
                  subtitle: Text(data.device.remoteId.toString()),
                  trailing: Text("${data.rssi} dBm"),
                  onTap: () => conectar(data.device),
                );
              },
            ),
            const SizedBox(height: 20),
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              iconSize: 40,
              color: encendido ? Colors.red : Colors.green,
              onPressed: cambiarEncender,
            ),
            const SizedBox(height: 20),
            ColorPicker(
              enableShadesSelection: true,
              pickersEnabled: const {
                ColorPickerType.wheel: true,
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.both: false,
              },
              onColorChanged: formatear,
            ),
          ],
        ),
      ),
    );
  }
}

*/

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true, // Usa Material Design 3 (más moderno) si es true
        // https://docs.flutter.dev/cookbook/design/themes

        // ===== COLORES PRINCIPALES =====
        primaryColor:
            Colors.blue, // Color primario principal (AppBar, botones, etc)
        primarySwatch: Colors
            .blue, // Paleta de colores derivada del color primario (DEPRECATED, usa ColorScheme)
        // ===== COLOR SCHEME (Moderna, Material Design 3) =====
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.light,
        ),

        // ===== COLORES SECUNDARIOS =====
        // secondaryHeaderColor: Colors.orange,  // Color secundario

        // ===== FONDOS =====
        scaffoldBackgroundColor: Colors.white, // Fondo del Scaffold
        // backgroundColor: Colors.grey[100],  // Fondo general (deprecated)

        // ===== BRILLO (Claro/Oscuro) =====
        brightness: Brightness.light, // Claro (light) u Oscuro (dark)
        // ===== TIPOGRAFÍA (TextTheme) =====
        // Define todos los estilos de texto predefinidos para la app
        textTheme: TextTheme(
          // === ESTILOS DISPLAY (Muy grandes, para títulos principales) ===
          displayLarge: TextStyle(
            fontSize: 32, // Tamaño muy grande
            fontWeight: FontWeight.bold, // Peso: bold (700)
            // Uso: Títulos principales, pantallas de inicio
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            // Uso: Títulos secundarios
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            // Uso: Subtítulos importantes
          ),

          // === ESTILOS HEADLINE (Encabezados medianos) ===
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700, // 700 = bold
            // Uso: Encabezados de secciones principales
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600, // 600 = semibold
            // Uso: Encabezados de subsecciones, títulos de tarjetas
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            // Uso: Títulos pequeños, items importantes
          ),

          // === ESTILOS TITLE (Títulos para etiquetas y labels) ===
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500, // 500 = medium
            // Uso: Títulos de listas, botones grandes
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            // Uso: Etiquetas, títulos de diálogos
          ),
          titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            // Uso: Labels pequeños, avisos
          ),

          // === ESTILOS BODY (Cuerpo del texto, el más usado) ===
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal, // 400 = normal/regular
            // Uso: Párrafos principales, texto descriptivo importante
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            // Uso: Texto general de la aplicación, párrafos normales
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            // Uso: Descripción pequeña, meta información, timestamps
          ),

          // === ESTILOS LABEL (Para etiquetas y botones pequeños) ===
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            // Uso: Botones, etiquetas grandes
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            // Uso: Chips, badges
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            // Uso: Labels muy pequeños, indicadores
          ),
        ),

        // ===== BARRA SUPERIOR (AppBar) =====
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
        ),
      ),
       darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: ThemeMode
          .system, 
      debugShowCheckedModeBanner: false,
      home: ControllerLeds(),
    );
  }
}

class ControllerLeds extends StatefulWidget {
  const ControllerLeds({super.key});

  @override
  State<ControllerLeds> createState() => _ControllerLedsState();
}

class _ControllerLedsState extends State<ControllerLeds> {
  final List<bool> _seleccionados = [false, false, false, false];
  List<ScanResult> resultadosEscaneo = [];
  BluetoothDevice? dispositivoSeleccionado;
  BluetoothCharacteristic? txCharacteristic;
  bool encendido = true;
  double _valorActual = 0xCC;
  int rojo = 0x00;
  int verde = 0x00;
  int azul = 0xFF;

  /* ===================== SCAN ===================== */

  Future<void> escanear() async {
    if (!await FlutterBluePlus.isSupported) {
      _mostrarSnack("Bluetooth not supported", error: true);
      return;
    }

    resultadosEscaneo.clear();
    dispositivoSeleccionado = null;
    setState(() {});

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) => setState(() => resultadosEscaneo = results),
      onError: (_) => _mostrarSnack("Scan error", error: true),
    );

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await FlutterBluePlus.isScanning.where((val) => !val).first;
    await subscription.cancel();
  }

  /* ===================== CONEXIÓN ===================== */

  Future<void> conectar() async {
    if (dispositivoSeleccionado == null) {
      _mostrarSnack("Select a device", error: true);
      return;
    }

    try {
      await FlutterBluePlus.stopScan();
      await dispositivoSeleccionado!.connect(license: License.free);
      await _obtenerCaracteristica(dispositivoSeleccionado!);

      _mostrarSnack("Connected to ${dispositivoSeleccionado!.platformName}");
    } catch (e) {
      _mostrarSnack("Connection error: $e", error: true);
    }
  }

  Future<void> _obtenerCaracteristica(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toUpperCase().contains("FFD9")) {
          txCharacteristic = characteristic;
          //_mostrarSnack("Característica encontrada");
          return;
        }
      }
    }

    _mostrarSnack("Feature not found", error: true);
  }

  /* ===================== ACCIONES ===================== */

  void cambiarEncender() {
    encendido = !encendido;
    setState(() {});

    int estado = encendido ? 0x23 : 0x24;
    _enviarComando([0xCC, estado, 0x33]);
  }

  void formatear(Color color) {
    rojo = (color.r * 255.0).round().clamp(0, 255);
    verde = (color.g * 255.0).round().clamp(0, 255);
    azul = (color.b * 255.0).round().clamp(0, 255);

    _enviarComando([0x56, rojo, verde, azul, 0x00, 0xF0, 0xAA]);
  }

  Future<void> _enviarComando(List<int> datos) async {
    if (txCharacteristic == null) {
      _mostrarSnack("Not connected to device", error: true);
      return;
    }

    try {
      await txCharacteristic!.write(
        Uint8List.fromList(datos),
        withoutResponse: false,
      );
    } catch (e) {
      _mostrarSnack("Error sending: $e", error: true);
    }
  }

  /* ===================== UI ===================== */

  void _mostrarSnack(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: error ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bluetooth LED controller",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    50,
                  ), // Ancho infinito, altura de 50
                ),
                onPressed: escanear,
                child: const Text("Search device"),
              ),
              const SizedBox(height: 16),
        
              /// ===== SELECT (DROPDOWN) =====
              DropdownButtonFormField<BluetoothDevice>(
                initialValue: dispositivoSeleccionado,
                decoration: const InputDecoration(
                  labelText: "Select a device",
                  border: OutlineInputBorder(),
                ),
                items: resultadosEscaneo.map((scanResult) {
                  final device = scanResult.device;
        
                  return DropdownMenuItem(
                    value: device,
                    child: Text(
                      device.platformName.isEmpty
                          ? "Unknown device"
                          : device.platformName,
                    ),
                  );
                }).toList(),
                onChanged: (device) {
                  setState(() {
                    dispositivoSeleccionado = device;
                  });
                },
              ),
              const SizedBox(height: 16),
        
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    50,
                  ), // Ancho infinito, altura de 50
                ),
                onPressed: conectar,
                child: const Text("Connect"),
              ),
        
              const SizedBox(height: 16),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                IconButton(
                  icon: const Icon(Icons.power_settings_new),
                  iconSize: 40,
                  color: encendido ? Colors.red : Colors.green,
                  onPressed: cambiarEncender,
                ),
                _crearBoton(0, Colors.red, Colors.white),
                _crearBoton(1, Colors.green, Colors.white),
                _crearBoton(2, Colors.blue, Colors.white),
                _crearBoton(3, Colors.white, Colors.black),
                ]
              ),
        
              const SizedBox(height: 16),
        
              ColorPicker(
                enableShadesSelection: true,
                pickersEnabled: const {
                  ColorPickerType.wheel: true,
                  ColorPickerType.primary: true,
                  ColorPickerType.accent: false,
                  ColorPickerType.bw: false,
                  ColorPickerType.custom: false,
                  ColorPickerType.both: false,
                },
                onColorChanged: formatear,
              ),
        
              SizedBox(height: 16),
        
              Center(
                child: Text("Intensity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 6, 73, 120)),),
              ),
        
              Slider(
                value: _valorActual,
                min: 0x01, // 1 decimal
                max: 0xFF, // 255 decimal
                divisions: 254, // Opcional: para que se mueva de 1 en 1
                label: _valorActual
                    .round()
                    .toRadixString(16)
                    .toUpperCase(), // Muestra el hex en el tooltip
                onChanged: (double nuevoValor) {
                  setState(() {
                    _valorActual = nuevoValor;
                  });
        
                  // Llamamos a tu función convirtiendo el double a int
                  _enviarComando([
                    0x56,
                    rojo,
                    verde,
                    azul,
                    _valorActual.round(),
                    0x0F,
                    0xAA,
                  ]);
                },
              ),
        
              SizedBox(height: 16),
        
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio:
                    3, // Ajusta la proporción (ancho/alto) de los botones
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _enviarComando([0xBB, 0x25, 0x1F, 0x44]),
                    label: Text('MODE 1'),
                    icon: Icon(Icons.settings), // Añadido icon ya que usas .icon
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _enviarComando([0xBB, 0x34, 0x10, 0x44]),
                    label: Text('MODE 2'),
                    icon: Icon(Icons.settings),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _enviarComando([0xBB, 0x30, 0xCC, 0x44]),
                    label: Text('MODE 3'),
                    icon: Icon(Icons.settings),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _enviarComando([0xBB, 0x38, 0xCC, 0x44]),
                    label: Text('MODE 4'),
                    icon: Icon(Icons.settings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearBoton(int index, Color colorFondo, Color colorIcono) {
  return ElevatedButton(
    onPressed: () {
      
      
      setState(() {
        formatear(colorFondo);
        
        for (int i = 0; i < _seleccionados.length; i++) {
          _seleccionados[i] = false;
        }
        
        _seleccionados[index] = true;
      });
    },
    style: ElevatedButton.styleFrom(
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(8),
      backgroundColor: colorFondo,
      // Opcional: una pequeña elevación para que se note cuál está activo
      elevation: _seleccionados[index] ? 4 : 2,
    ),
    child: _seleccionados[index] 
        ? Icon(Icons.check, color: colorIcono) 
        : const SizedBox(width: 3, height: 3), // Tamaño similar al icono para evitar saltos visuales
  );
}
}
