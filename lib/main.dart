import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ir/flutter_ir.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const NovaUniversalApp());
}

class NovaUniversalApp extends StatelessWidget {
  const NovaUniversalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nova Universal',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
      ),
      home: const RemoteScreen(),
    );
  }
}

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  String selectedBrand = 'Samsung';
  String selectedMode = 'IR Remote';
  String ipAddress = '192.168.0.100';
  String statusMessage = 'INITIALIZING...';
  bool hasIrEmitter = false;
  Map<String, dynamic> irDb = {};

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    bool hasIr = await FlutterIr.hasIrEmitter;
    String jsonString = await rootBundle.loadString('assets/database/tv_codes.json');
    Map<String, dynamic> decoded = jsonDecode(jsonString);

    setState(() {
      hasIrEmitter = hasIr;
      irDb = decoded;
      statusMessage = hasIr ? 'READY ($selectedBrand - IR)' : 'NO IR HARDWARE DETECTED';
    });
  }

  void sendCommand(String key) async {
    if (selectedMode == 'IR Remote') {
      if (!hasIrEmitter) {
        _showMessage('এই ফোনে IR Blaster সেন্সর নেই!');
        return;
      }
      String? hex = irDb[selectedBrand]?[key];
      if (hex != null) {
        await FlutterIr.transmitHex(hex);
        setState(() => statusMessage = 'SENT IR: $key ($selectedBrand)');
      } else {
        setState(() => statusMessage = 'NO HEX CODE FOR $key');
      }
    } else {
      try {
        final res = await http.get(Uri.parse('http://$ipAddress:8080/api/$key')).timeout(const Duration(seconds: 1));
        setState(() => statusMessage = 'WIFI CMD SENT: $key');
      } catch (_) {
        setState(() => statusMessage = 'WIFI CONNECTION ERROR');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA UNIVERSAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1C1C22),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D2D38)),
                ),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      value: selectedBrand,
                      isExpanded: true,
                      items: irDb.keys.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() { selectedBrand = val; statusMessage = 'READY ($selectedBrand)'; });
                      },
                    ),
                    DropdownButton<String>(
                      value: selectedMode,
                      isExpanded: true,
                      items: ['IR Remote', 'Smart TV (Wi-Fi)'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() { selectedMode = val; statusMessage = 'MODE: $selectedMode'; });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF00FF66), fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                    onPressed: () => sendCommand('POWER'),
                    child: const Icon(Icons.power_settings_new, color: Colors.white, size: 28),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2D38), shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                    onPressed: () => sendCommand('VOL_UP'),
                    child: const Icon(Icons.volume_up, color: Colors.white, size: 28),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2D38), shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                    onPressed: () => sendCommand('VOL_DOWN'),
                    child: const Icon(Icons.volume_down, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
