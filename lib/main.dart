import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/io.dart';

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
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepOrange,
      ),
      home: const RemoteHomeScreen(),
    );
  }
}

class RemoteHomeScreen extends StatefulWidget {
  const RemoteHomeScreen({super.key});

  @override
  State<RemoteHomeScreen> createState() => _RemoteHomeScreenState();
}

class _RemoteHomeScreenState extends State<RemoteHomeScreen> {
  static const platform = MethodChannel('com.nova.universal/ir');
  
  String selectedBrand = 'Minister (মিনিস্টার)';
  String selectedMode = 'IR Blaster (ইনফ্রারেড)';
  bool hasIrSensor = false;
  bool isScanning = false;
  TextEditingController ipController = TextEditingController(text: '192.168.0.100');
  IOWebSocketChannel? _wsChannel;

  final List<String> brands = [
    'Minister (মিনিস্টার)',
    'Samsung Smart TV',
    'LG webOS TV',
    'Sony Android TV',
    'Walton',
    'Vision',
    'General TV'
  ];

  final List<String> modes = [
    'IR Blaster (ইনফ্রারেড)',
    'Smart TV (Wi-Fi WebSocket)'
  ];

  @override
  void initState() {
    super.initState();
    _checkIrSensor();
  }

  Future<void> _checkIrSensor() async {
    try {
      final bool result = await platform.invokeMethod('hasIrEmitter');
      setState(() => hasIrSensor = result);
    } catch (_) {
      setState(() => hasIrSensor = false);
    }
  }

  // NEC IR Signal Timing Generator
  List<int> _generateNecPattern(int address, int command) {
    List<int> pattern = [9000, 4500];
    int data = ((~command & 0xFF) << 24) | ((command & 0xFF) << 16) | ((~address & 0xFF) << 8) | (address & 0xFF);
    for (int i = 0; i < 32; i++) {
      pattern.add(562);
      pattern.add((data & (1 << i)) != 0 ? 1687 : 562);
    }
    pattern.add(562);
    return pattern;
  }

  // Auto Scan WiFi Smart TVs via UDP Multicast (SSDP)
  Future<void> _scanSmartTvs() async {
    setState(() => isScanning = true);
    try {
      RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
        socket.broadcastEnabled = true;
        String ssdpQuery = 
          'M-SEARCH * HTTP/1.1\r\n' +
          'HOST: 239.255.255.250:1900\r\n' +
          'MAN: "ssdp:discover"\r\n' +
          'MX: 2\r\n' +
          'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n';
        socket.send(utf8.encode(ssdpQuery), InternetAddress('239.255.255.250'), 1900);
        
        socket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            Datagram? dg = socket.receive();
            if (dg != null) {
              String response = utf8.decode(dg.data);
              if (response.contains('200 OK')) {
                setState(() => ipController.text = dg.address.address);
              }
            }
          }
        });
        Future.delayed(const Duration(seconds: 3), () => socket.close());
      });
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 3));
    setState(() => isScanning = false);
  }

  // Connect & Pair with Smart TV WebSocket
  void _connectSmartTvWebSocket(String ip, String command) {
    try {
      String wsUrl = selectedBrand.contains('Samsung') 
          ? 'ws://$ip:8001/api/v2/channels/samsung.remote.control'
          : 'ws://$ip:3000/'; // LG/Android TV WebSocket Port

      _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl), pingInterval: const Duration(seconds: 2));
      
      var payload = {
        "method": "ms.remote.control",
        "params": {
          "Cmd": "Click",
          "DataOfCmd": "KEY_$command",
          "TypeOfRemote": "SendRemoteKey"
        }
      };
      
      _wsChannel?.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> sendCommand(String keyName, int cmdCode) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (selectedMode.contains('IR')) {
      if (!hasIrSensor) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No IR Blaster hardware on this phone!'), backgroundColor: Colors.red),
        );
        return;
      }
      try {
        List<int> pattern = _generateNecPattern(0x00, cmdCode);
        await platform.invokeMethod('transmit', {'frequency': 38000, 'pattern': pattern});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('IR Signal Fired: $keyName'), duration: const Duration(milliseconds: 600)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IR Error: $e')));
      }
    } else {
      // Smart TV WiFi Mode
      String ip = ipController.text.trim();
      _connectSmartTvWebSocket(ip, keyName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wi-Fi Packet Sent to $ip: $keyName'), duration: const Duration(milliseconds: 600)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nova universal'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('টিভি ব্র্যান্ড নির্বাচন করুন:', style: TextStyle(color: Colors.grey)),
                  DropdownButton<String>(
                    value: selectedBrand,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E24),
                    items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) => setState(() => selectedBrand = val!),
                  ),
                  const SizedBox(height: 10),
                  const Text('সংযোগ মোড:', style: TextStyle(color: Colors.grey)),
                  DropdownButton<String>(
                    value: selectedMode,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E24),
                    items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => selectedMode = val!),
                  ),
                  if (selectedMode.contains('Wi-Fi')) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ipController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Smart TV IP',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isScanning ? null : _scanSmartTvs,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                          child: isScanning 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Text('SCAN'),
                        )
                      ],
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'READY (${selectedBrand.split(' ')[0].toUpperCase()} - ${selectedMode.contains('IR') ? (hasIrSensor ? 'IR ONLINE' : 'NO IR SENSOR') : 'WIFI READY'})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selectedMode.contains('IR') && !hasIrSensor ? Colors.redAccent : Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FloatingActionButton.small(
                        backgroundColor: Colors.red,
                        onPressed: () => sendCommand('POWER', 0x12),
                        child: const Icon(Icons.flash_on, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_off, color: Colors.blueAccent),
                        onPressed: () => sendCommand('MUTE', 0x0D),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (var i = 1; i <= 9; i++) _buildNumBtn(i.toString(), 0x10 + i),
                      _buildNumBtn('-', 0x0C),
                      _buildNumBtn('0', 0x10),
                      _buildNumBtn('↻', 0x1A),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildAppBtn('YouTube', Colors.red, Colors.white, () => sendCommand('YOUTUBE', 0x50))),
                      const SizedBox(width: 6),
                      Expanded(child: _buildAppBtn('Hoichoi', const Color(0xFF2C2C38), Colors.white, () => sendCommand('HOICHOI', 0x51))),
                      const SizedBox(width: 6),
                      Expanded(child: _buildAppBtn('Amazon', Colors.lightBlue, Colors.white, () => sendCommand('AMAZON', 0x52))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _buildAppBtn('NETFLIX', Colors.red[900]!, Colors.white, () => sendCommand('NETFLIX', 0x53)),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildAppBtn('HOME', const Color(0xFF2C2C38), Colors.white, () => sendCommand('HOME', 0x20))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildAppBtn('MODE', const Color(0xFF2C2C38), Colors.white, () => sendCommand('MODE', 0x21))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumBtn(String val, int cmdCode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C38),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => sendCommand(val, cmdCode),
      child: Text(val, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildAppBtn(String label, Color bg, Color text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: text,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
