import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const NovaRemoteApp());
}

class NovaRemoteApp extends StatelessWidget {
  const NovaRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOVA UNIVERSAL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
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
  static const platform = MethodChannel('com.nova.universal/ir');

  String selectedBrand = 'Minister';
  String selectedMode = 'IR Blaster';
  bool isScanning = false;
  List<String> discoveredDevices = [];

  final Map<String, Map<String, List<int>>> irCodes = {
    'POWER': {'freq': 38000, 'pattern': [9000, 4500, 560, 560, 560, 1690, 560, 1690]},
    'MUTE': {'freq': 38000, 'pattern': [9000, 4500, 560, 1690, 560, 560, 560, 1690]},
    'VOL_UP': {'freq': 38000, 'pattern': [9000, 4500, 560, 1690, 560, 1690, 560, 560]},
    'VOL_DOWN': {'freq': 38000, 'pattern': [9000, 4500, 560, 560, 560, 1690, 560, 560]},
    'CH_UP': {'freq': 38000, 'pattern': [9000, 4500, 560, 1690, 560, 560, 560, 560]},
    'CH_DOWN': {'freq': 38000, 'pattern': [9000, 4500, 560, 560, 560, 560, 560, 1690]},
    'OK': {'freq': 38000, 'pattern': [9000, 4500, 560, 1690, 560, 1690, 560, 1690]},
    'UP': {'freq': 38000, 'pattern': [9000, 4500, 560, 560, 560, 560, 560, 560]},
    'DOWN': {'freq': 38000, 'pattern': [9000, 4500, 560, 1690, 560, 1690, 560, 560]},
    'LEFT': {'freq': 38000, 'pattern': [9000, 4500, 560, 560, 560, 1690, 560, 1690]},
    'RIGHT': {'freq': 38000, 'pattern': [9000, 4500, 560, 1690, 560, 560, 560, 1690]},
    'HOME': {'freq': 38000, 'pattern': [9000, 4500, 560, 1690, 560, 1690, 560, 1690]},
    'MODE': {'freq': 38000, 'pattern': [9000, 4500, 560, 560, 560, 560, 560, 1690]},
  };

  Future<void> sendIrCommand(String key) async {
    HapticFeedback.lightImpact();
    if (selectedMode == 'IR Blaster') {
      try {
        final code = irCodes[key];
        if (code != null) {
          await platform.invokeMethod('transmit', {
            'frequency': code['freq'],
            'pattern': code['pattern'],
          });
        }
      } catch (_) {}
    }
  }

  Future<void> discoverSmartTvs() async {
    setState(() {
      isScanning = true;
      discoveredDevices.clear();
    });

    try {
      RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      String ssdpQuery =
          'M-SEARCH * HTTP/1.1\r\n' +
          'HOST: 239.255.255.250:1900\r\n' +
          'MAN: "ssdp:discover"\r\n' +
          'MX: 2\r\n' +
          'ST: ssdp:all\r\n\r\n';

      socket.send(utf8.encode(ssdpQuery), InternetAddress('239.255.255.250'), 1900);

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = socket.receive();
          if (dg != null) {
            String response = utf8.decode(dg.data);
            if (response.contains('LOCATION:') || response.contains('Server:')) {
              String ip = dg.address.address;
              if (!discoveredDevices.contains(ip)) {
                setState(() {
                  discoveredDevices.add(ip);
                });
              }
            }
          }
        }
      });

      await Future.delayed(const Duration(seconds: 3));
      socket.close();
    } catch (_) {}

    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA UNIVERSAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        toolbarHeight: 40,
        actions: [
          IconButton(
            icon: isScanning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.wifi_find, size: 20),
            onPressed: discoverSmartTvs,
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFF2A2A3D), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBrand,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2A2A3D),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: ['Minister', 'Walton', 'Sony', 'LG', 'Samsung', 'General IR']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => selectedBrand = val!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color(0xFF2A2A3D), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMode,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2A2A3D),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: ['IR Blaster', 'Wi-Fi Mode']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => selectedMode = val!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (discoveredDevices.isNotEmpty)
                Container(
                  height: 30,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: discoveredDevices.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(discoveredDevices[i], style: const TextStyle(fontSize: 10)),
                        backgroundColor: const Color(0xFF3F3F56),
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleBtn(Icons.power_settings_new, Colors.red, () => sendIrCommand('POWER')),
                  _buildTextBtn('HOME', () => sendIrCommand('HOME')),
                  _buildTextBtn('MODE', () => sendIrCommand('MODE')),
                  _buildCircleBtn(Icons.volume_off, Colors.blue, () => sendIrCommand('MUTE')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      _buildPillBtn('VOL +', () => sendIrCommand('VOL_UP')),
                      const SizedBox(height: 8),
                      _buildPillBtn('VOL -', () => sendIrCommand('VOL_DOWN')),
                    ],
                  ),
                  SizedBox(
                    width: 135,
                    height: 135,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2A2A3D),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 28),
                            onPressed: () => sendIrCommand('UP'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 28),
                            onPressed: () => sendIrCommand('DOWN'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_left, color: Colors.white, size: 28),
                            onPressed: () => sendIrCommand('LEFT'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_right, color: Colors.white, size: 28),
                            onPressed: () => sendIrCommand('RIGHT'),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => sendIrCommand('OK'),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1E2C),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildPillBtn('CH ▲', () => sendIrCommand('CH_UP')),
                      const SizedBox(height: 8),
                      _buildPillBtn('CH ▼', () => sendIrCommand('CH_DOWN')),
                    ],
                  ),
                ],
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 6,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final labels = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '0', '↩'];
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A3D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => sendIrCommand(labels[index]),
                    child: Text(
                      labels[index],
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(child: _buildAppBtn('YouTube', const Color(0xFFE53935), () => sendIrCommand('YOUTUBE'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildAppBtn('Hoichoi', const Color(0xFF393E46), () => sendIrCommand('HOICHOI'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildAppBtn('Amazon', const Color(0xFF00A8E8), () => sendIrCommand('AMAZON'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildAppBtn('NETFLIX', const Color(0xFFD32F2F), () => sendIrCommand('NETFLIX'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildTextBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: 62,
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A3D),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPillBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: 62,
      height: 34,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A3D),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAppBtn(String label, Color bg, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
