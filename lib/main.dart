import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      theme: ThemeData.dark(),
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
  static const platform = MethodChannel('com.nova.universal/ir');
  String selectedBrand = 'Minister';
  String connectionMode = 'IR Blaster';

  Future<void> sendIrCommand(String commandName) async {
    try {
      final String result = await platform.invokeMethod('transmitIR', {
        'brand': selectedBrand,
        'command': commandName,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signal Sent: $commandName ($result)'),
          duration: const Duration(milliseconds: 700),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA UNIVERSAL'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<String>(
                    value: selectedBrand,
                    items: ['Minister', 'Samsung', 'LG', 'Sony', 'Walton']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedBrand = v!),
                  ),
                  DropdownButton<String>(
                    value: connectionMode,
                    items: ['IR Blaster', 'Wi-Fi / Smart TV']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => connectionMode = v!),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(28),
                ),
                onPressed: () => sendIrCommand('POWER'),
                child: const Icon(Icons.power_settings_new, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Mode: $connectionMode | Brand: $selectedBrand',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
