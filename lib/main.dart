import 'package:flutter/material.dart';

void main() {
  runApp(const NovaRemoteApp());
}

class NovaRemoteApp extends StatelessWidget {
  const NovaRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nova Universal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RemoteScreen(),
    );
  }
}

class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Universal Remote'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_remote, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Universal Remote Control',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transmitting Signal...')),
                );
              },
              icon: const Icon(Icons.power_settings_new, color: Colors.red),
              label: const Text('Power ON / OFF'),
            ),
          ],
        ),
      ),
    );
  }
}
