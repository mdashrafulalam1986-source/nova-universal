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
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
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

  void _connectSmartTvWebSocket(String ip, String command) {
    try {
      String wsUrl = selectedBrand.contains('Samsung') 
          ? 'ws://$ip:8001/api/v2/channels/samsung.remote.control'
          : 'ws://$ip:3000/';

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
          const SnackBar(content: Text('Error: No IR Blaster hardware!'), backgroundColor: Colors.red, duration: Duration(milliseconds: 500)),
        );
        return;
      }
      try {
        List<int> pattern = _generateNecPattern(0x00, cmdCode);
        await platform.invokeMethod('transmit', {'frequency': 38000, 'pattern': pattern});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('IR: $keyName'), duration: const Duration(milliseconds: 400)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IR Error: $e')));
      }
    } else {
      String ip = ipController.text.trim();
      _connectSmartTvWebSocket(ip, keyName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wi-Fi Sent: $keyName'), duration: const Duration(milliseconds: 400)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA UNIVERSAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        toolbarHeight: 40,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            children: [
              // Header Selector Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBrand,
                          isDense: true,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          dropdownColor: const Color(0xFF1E1E24),
                          items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() => selectedBrand = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMode,
                          isDense: true,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          dropdownColor: const Color(0xFF1E1E24),
                          items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) => setState(() => selectedMode = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedMode.contains('Wi-Fi')) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: TextField(
                          controller: ipController,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: const InputDecoration(
                            labelText: 'Smart TV IP',
                            labelStyle: TextStyle(fontSize: 10),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: isScanning ? null : _scanSmartTvs,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.symmetric(horizontal: 12)),
                        child: isScanning 
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Text('SCAN', style: TextStyle(fontSize: 11)),
                      ),
                    )
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // Single Compact Control Surface
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Top Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRoundBtn(Icons.power_settings_new, Colors.red, () => sendCommand('POWER', 0x12)),
                          _buildCompactBtn('HOME', () => sendCommand('HOME', 0x20)),
                          _buildCompactBtn('MODE', () => sendCommand('MODE', 0x21)),
                          _buildRoundBtn(Icons.volume_off, Colors.blueAccent, () => sendCommand('MUTE', 0x0D)),
                        ],
                      ),

                      // D-Pad + Vol/Ch Middle Cluster
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Vol Column
                          Column(
                            children: [
                              _buildMiniBtn('VOL +', () => sendCommand('VOL_UP', 0x06)),
                              const SizedBox(height: 8),
                              _buildMiniBtn('VOL -', () => sendCommand('VOL_DOWN', 0x07)),
                            ],
                          ),

                          // D-Pad Circle
                          Container(
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2C2C38),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 28,
                                    icon: const Icon(Icons.arrow_drop_up, color: Colors.white),
                                    onPressed: () => sendCommand('UP', 0x01),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 28,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                    onPressed: () => sendCommand('DOWN', 0x02),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 28,
                                    icon: const Icon(Icons.arrow_left, color: Colors.white),
                                    onPressed: () => sendCommand('LEFT', 0x03),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 28,
                                    icon: const Icon(Icons.arrow_right, color: Colors.white),
                                    onPressed: () => sendCommand('RIGHT', 0x04),
                                  ),
                                ),
                                Center(
                                  child: GestureDetector(
                                    onTap: () => sendCommand('ENTER', 0x05),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Ch Column
                          Column(
                            children: [
                              _buildMiniBtn('CH ▲', () => sendCommand('CH_UP', 0x08)),
                              const SizedBox(height: 8),
                              _buildMiniBtn('CH ▼', () => sendCommand('CH_DOWN', 0x09)),
                            ],
                          ),
                        ],
                      ),

                      // Number Grid (Compact)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 2.8,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        children: [
                          for (var i = 1; i <= 9; i++) _buildNumBtn(i.toString(), 0x10 + i),
                          _buildNumBtn('-', 0x0C),
                          _buildNumBtn('0', 0x10),
                          _buildNumBtn('↻', 0x1A),
                        ],
                      ),

                      // App Shortcuts
                      Row(
                        children: [
                          Expanded(child: _buildAppBtn('YouTube', Colors.red, () => sendCommand('YOUTUBE', 0x50))),
                          const SizedBox(width: 4),
                          Expanded(child: _buildAppBtn('Hoichoi', const Color(0xFF2C2C38), () => sendCommand('HOICHOI', 0x51))),
                          const SizedBox(width: 4),
                          Expanded(child: _buildAppBtn('Amazon', Colors.lightBlue, () => sendCommand('AMAZON', 0x52))),
                          const SizedBox(width: 4),
                          Expanded(child: _buildAppBtn('NETFLIX', Colors.red[900]!, () => sendCommand('NETFLIX', 0x53))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundBtn(IconData icon, Color color, VoidCallback onTap) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: IconButton(padding: EdgeInsets.zero, icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap),
    );
  }

  Widget _buildCompactBtn(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMiniBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: 65,
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C38), padding: EdgeInsets.zero),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNumBtn(String val, int cmdCode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C38),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () => sendCommand(val, cmdCode),
      child: Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAppBtn(String label, Color bg, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
