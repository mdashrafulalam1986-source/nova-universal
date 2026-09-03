import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/io.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0F0F17),
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
  IOWebSocketChannel? _webSocketChannel;

  String selectedBrand = 'Minister (মিনোস্টার)';
  String selectedMode = 'IR Blaster (ইনফ্রারেড)';
  TextEditingController ipController = TextEditingController(text: '192.168.0.100');

  final List<String> brands = [
    'Minister (মিনোস্টার)',
    'Walton',
    'Sony',
    'LG',
    'Samsung',
    'General IR / Chinese TV'
  ];

  final List<String> modes = [
    'IR Blaster (ইনফ্রারেড)',
    'Smart TV (Wi-Fi)'
  ];

  final Map<String, Map<String, int>> brandCommandHex = {
    'Minister (মিনোস্টার)': {
      'POWER': 0x12, 'MUTE': 0x10, 'NAV': 0x15,
      'UP': 0x01, 'DOWN': 0x02, 'LEFT': 0x03, 'RIGHT': 0x04, 'OK': 0x05,
      'VOL_UP': 0x1A, 'VOL_DOWN': 0x1B, 'CH_UP': 0x1E, 'CH_DOWN': 0x1F,
      'HOME': 0x08, 'MODE': 0x09, '1': 0x31, '2': 0x32, '3': 0x33,
      '4': 0x34, '5': 0x35, '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39,
      '0': 0x30, '-': 0x0C, '↩': 0x0B, 'YOUTUBE': 0x40, 'NETFLIX': 0x41,
      'HOICHOI': 0x42, 'AMAZON': 0x43, 'PLAY': 0x50, 'REWIND': 0x51, 'FFWD': 0x52,
      'RED': 0x60, 'GREEN': 0x61, 'YELLOW': 0x62, 'BLUE': 0x63,
      'N-CH.P': 0x70, 'CC': 0x71, 'MTR': 0x72,
      'F-MODE': 0x73, 'S.MCOB': 0x74, 'CRLUST': 0x75,
      'FMODE': 0x76, 'S.MODE': 0x77, 'DELETE': 0x78
    },
    'Walton': {
      'POWER': 0x40, 'MUTE': 0x41, 'NAV': 0x42,
      'UP': 0x10, 'DOWN': 0x11, 'LEFT': 0x12, 'RIGHT': 0x13, 'OK': 0x14,
      'VOL_UP': 0x02, 'VOL_DOWN': 0x03, 'CH_UP': 0x00, 'CH_DOWN': 0x01,
      'HOME': 0x0A, 'MODE': 0x0F, '1': 0x21, '2': 0x22, '3': 0x23,
      '4': 0x24, '5': 0x25, '6': 0x26, '7': 0x27, '8': 0x28, '9': 0x29,
      '0': 0x20, '-': 0x1A, '↩': 0x1B, 'YOUTUBE': 0x50, 'NETFLIX': 0x51,
      'HOICHOI': 0x52, 'AMAZON': 0x53, 'PLAY': 0x60, 'REWIND': 0x61, 'FFWD': 0x62,
      'RED': 0x70, 'GREEN': 0x71, 'YELLOW': 0x72, 'BLUE': 0x73,
      'N-CH.P': 0x80, 'CC': 0x81, 'MTR': 0x82,
      'F-MODE': 0x83, 'S.MCOB': 0x84, 'CRLUST': 0x85,
      'FMODE': 0x86, 'S.MODE': 0x87, 'DELETE': 0x88
    },
    'Sony': {
      'POWER': 0x0A, 'MUTE': 0x0D, 'NAV': 0x25,
      'UP': 0x2C, 'DOWN': 0x2D, 'LEFT': 0x33, 'RIGHT': 0x34, 'OK': 0x2E,
      'VOL_UP': 0x12, 'VOL_DOWN': 0x13, 'CH_UP': 0x10, 'CH_DOWN': 0x11,
      'HOME': 0x60, 'MODE': 0x25, '1': 0x00, '2': 0x01, '3': 0x02,
      '4': 0x03, '5': 0x04, '6': 0x05, '7': 0x06, '8': 0x07, '9': 0x08,
      '0': 0x09, '-': 0x0B, '↩': 0x23, 'YOUTUBE': 0x61, 'NETFLIX': 0x62,
      'HOICHOI': 0x63, 'AMAZON': 0x64, 'PLAY': 0x38, 'REWIND': 0x3A, 'FFWD': 0x3B,
      'RED': 0x68, 'GREEN': 0x69, 'YELLOW': 0x6A, 'BLUE': 0x6B,
      'N-CH.P': 0x70, 'CC': 0x71, 'MTR': 0x72,
      'F-MODE': 0x73, 'S.MCOB': 0x74, 'CRLUST': 0x75,
      'FMODE': 0x76, 'S.MODE': 0x77, 'DELETE': 0x78
    },
    'LG': {
      'POWER': 0x08, 'MUTE': 0x09, 'NAV': 0x0B,
      'UP': 0x40, 'DOWN': 0x41, 'LEFT': 0x07, 'RIGHT': 0x06, 'OK': 0x44,
      'VOL_UP': 0x02, 'VOL_DOWN': 0x03, 'CH_UP': 0x00, 'CH_DOWN': 0x01,
      'HOME': 0x21, 'MODE': 0x0B, '1': 0x10, '2': 0x11, '3': 0x12,
      '4': 0x13, '5': 0x14, '6': 0x15, '7': 0x16, '8': 0x17, '9': 0x18,
      '0': 0x19, '-': 0x4C, '↩': 0x28, 'YOUTUBE': 0xFB, 'NETFLIX': 0x5B,
      'HOICHOI': 0x5C, 'AMAZON': 0x5D, 'PLAY': 0xB0, 'REWIND': 0x8F, 'FFWD': 0x8E,
      'RED': 0x6E, 'GREEN': 0x6F, 'YELLOW': 0x70, 'BLUE': 0x71,
      'N-CH.P': 0x80, 'CC': 0x81, 'MTR': 0x82,
      'F-MODE': 0x83, 'S.MCOB': 0x84, 'CRLUST': 0x85,
      'FMODE': 0x86, 'S.MODE': 0x87, 'DELETE': 0x88
    },
    'Samsung': {
      'POWER': 0x02, 'MUTE': 0x0F, 'NAV': 0x01,
      'UP': 0x60, 'DOWN': 0x61, 'LEFT': 0x65, 'RIGHT': 0x62, 'OK': 0x68,
      'VOL_UP': 0x07, 'VOL_DOWN': 0x0B, 'CH_UP': 0x12, 'CH_DOWN': 0x10,
      'HOME': 0x79, 'MODE': 0x01, '1': 0x04, '2': 0x05, '3': 0x06,
      '4': 0x08, '5': 0x09, '6': 0x0A, '7': 0x0C, '8': 0x0D, '9': 0x0E,
      '0': 0x11, '-': 0x1A, '↩': 0x58, 'YOUTUBE': 0x98, 'NETFLIX': 0x99,
      'HOICHOI': 0x9A, 'AMAZON': 0x9B, 'PLAY': 0x47, 'REWIND': 0x45, 'FFWD': 0x48,
      'RED': 0x6C, 'GREEN': 0x6D, 'YELLOW': 0x6E, 'BLUE': 0x6F,
      'N-CH.P': 0x80, 'CC': 0x81, 'MTR': 0x82,
      'F-MODE': 0x83, 'S.MCOB': 0x84, 'CRLUST': 0x85,
      'FMODE': 0x86, 'S.MODE': 0x87, 'DELETE': 0x88
    },
    'General IR / Chinese TV': {
      'POWER': 0x12, 'MUTE': 0x10, 'NAV': 0x15,
      'UP': 0x01, 'DOWN': 0x02, 'LEFT': 0x03, 'RIGHT': 0x04, 'OK': 0x05,
      'VOL_UP': 0x1A, 'VOL_DOWN': 0x1B, 'CH_UP': 0x1E, 'CH_DOWN': 0x1F,
      'HOME': 0x08, 'MODE': 0x09, '1': 0x31, '2': 0x32, '3': 0x33,
      '4': 0x34, '5': 0x35, '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39,
      '0': 0x30, '-': 0x0C, '↩': 0x0B, 'YOUTUBE': 0x40, 'NETFLIX': 0x41,
      'HOICHOI': 0x42, 'AMAZON': 0x43, 'PLAY': 0x50, 'REWIND': 0x51, 'FFWD': 0x52,
      'RED': 0x60, 'GREEN': 0x61, 'YELLOW': 0x62, 'BLUE': 0x63,
      'N-CH.P': 0x70, 'CC': 0x71, 'MTR': 0x72,
      'F-MODE': 0x73, 'S.MCOB': 0x74, 'CRLUST': 0x75,
      'FMODE': 0x76, 'S.MODE': 0x77, 'DELETE': 0x78
    }
  };

  List<int> buildNecPattern(int cmd) {
    int address = 0x00;
    int addressInv = 0xFF;
    int cmdInv = (~cmd) & 0xFF;

    List<int> pattern = [];
    pattern.add(9000);
    pattern.add(4500);

    int fullData = (address << 24) | (addressInv << 16) | (cmd << 8) | cmdInv;

    for (int i = 31; i >= 0; i--) {
      pattern.add(560);
      if ((fullData & (1 << i)) != 0) {
        pattern.add(1690);
      } else {
        pattern.add(560);
      }
    }
    pattern.add(560);
    return pattern;
  }

  void sendWebSocketCommand(String key) {
    String ip = ipController.text.trim();
    if (ip.isEmpty) return;

    try {
      String wsUrl = 'ws://$ip:8001/api/v2/channels/samsung.remote.remote?name=NovaRemote';
      _webSocketChannel ??= IOWebSocketChannel.connect(Uri.parse(wsUrl));

      var payload = {
        "method": "ms.remote.control",
        "params": {
          "Cmd": "Click",
          "DataOfCmd": "KEY_$key",
          "Option": "false",
          "TypeOfRemote": "SendRemoteKey"
        }
      };

      _webSocketChannel?.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> sendCommand(String key) async {
    HapticFeedback.lightImpact();
    
    if (selectedMode.contains('IR')) {
      try {
        int cmdHex = brandCommandHex[selectedBrand]?[key] ?? 0x00;
        List<int> pattern = buildNecPattern(cmdHex);

        await platform.invokeMethod('transmit', {
          'frequency': 38000,
          'pattern': pattern,
        });
      } catch (_) {}
    } else {
      sendWebSocketCommand(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'nova universal',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        toolbarHeight: 36,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'টিভি ব্র্যান্ড নির্বাচন করুন:',
                      selectedBrand,
                      brands,
                      (val) => setState(() => selectedBrand = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      'সংযোগ মোড:',
                      selectedMode,
                      modes,
                      (val) => setState(() => selectedMode = val!),
                    ),
                  ),
                ],
              ),

              if (selectedMode.contains('Wi-Fi'))
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'স্মার্ট টিভি IP Address:',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: ipController,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                height: 28,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    'READY (${selectedBrand.split(" ")[0].toUpperCase()} - ${selectedMode.contains("IR") ? "IR" : "SMART"})',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleBtn(Icons.power_settings_new, Colors.red, () => sendCommand('POWER')),
                  _buildCircleBtn(Icons.near_me, Colors.indigoAccent, () => sendCommand('NAV')),
                ],
              ),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 4,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '0', '↩'];
                  return _buildSmallBtn(keys[index], () => sendCommand(keys[index]));
                },
              ),

              Row(
                children: [
                  Expanded(child: _buildAppBtn('YouTube', const Color(0xFFE53935), () => sendCommand('YOUTUBE'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildAppBtn('Hoichoi', const Color(0xFF2A2A3D), () => sendCommand('HOICHOI'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildAppBtn('Amazon', const Color(0xFF00A8E8), () => sendCommand('AMAZON'))),
                ],
              ),
              _buildAppBtn('NETFLIX', const Color(0xFFD32F2F), () => sendCommand('NETFLIX')),

              Row(
                children: [
                  Expanded(child: _buildSmallBtn('HOME', () => sendCommand('HOME'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildSmallBtn('MODE', () => sendCommand('MODE'))),
                ],
              ),

              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E2C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: IconButton(
                        iconSize: 22,
                        icon: const Icon(Icons.arrow_drop_up, color: Colors.white),
                        onPressed: () => sendCommand('UP'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: IconButton(
                        iconSize: 22,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onPressed: () => sendCommand('DOWN'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        iconSize: 22,
                        icon: const Icon(Icons.arrow_left, color: Colors.white),
                        onPressed: () => sendCommand('LEFT'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        iconSize: 22,
                        icon: const Icon(Icons.arrow_right, color: Colors.white),
                        onPressed: () => sendCommand('RIGHT'),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => sendCommand('OK'),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2A2A3D),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSmallBtn('HOME', () => sendCommand('HOME')),
                  _buildSmallBtn('EXT', () => sendCommand('MODE')),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPillBtn('VOL +', () => sendCommand('VOL_UP')),
                  _buildPillBtn('RESPECT', () => sendCommand('NAV')),
                  _buildPillBtn('CH ▲', () => sendCommand('CH_UP')),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPillBtn('VOL -', () => sendCommand('VOL_DOWN')),
                  _buildPillBtn('TV', () => sendCommand('MODE')),
                  _buildPillBtn('CH ▼', () => sendCommand('CH_DOWN')),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconBtn(Icons.fast_rewind, () => sendCommand('REWIND')),
                  _buildIconBtn(Icons.play_arrow, () => sendCommand('PLAY')),
                  _buildIconBtn(Icons.fast_forward, () => sendCommand('FFWD')),
                ],
              ),

              Row(
                children: [
                  Expanded(child: _buildColorBtn('HPC', Colors.red, () => sendCommand('RED'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildColorBtn('MASE', Colors.green, () => sendCommand('GREEN'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildColorBtn('CC', Colors.yellow, () => sendCommand('YELLOW'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildColorBtn('🔒', Colors.blue, () => sendCommand('BLUE'))),
                ],
              ),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 3.2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: [
                  _buildSmallBtn('N-CH.P', () => sendCommand('N-CH.P')),
                  _buildSmallBtn('CC', () => sendCommand('CC')),
                  _buildSmallBtn('MTR', () => sendCommand('MTR')),
                  _buildSmallBtn('F-MODE', () => sendCommand('F-MODE')),
                  _buildSmallBtn('S.MCOB', () => sendCommand('S.MCOB')),
                  _buildSmallBtn('CRLUST', () => sendCommand('CRLUST')),
                  _buildSmallBtn('FMODE', () => sendCommand('FMODE')),
                  _buildSmallBtn('S.MODE', () => sendCommand('S.MODE')),
                  _buildSmallBtn('DELETE', () => sendCommand('DELETE')),
                ],
              ),

              const Text(
                'NOVA UNIVERSAL',
                style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E2C),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSmallBtn(String label, VoidCallback onTap) {
    return SizedBox(
      height: 26,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A3D),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPillBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: 70,
      height: 24,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E2C),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAppBtn(String label, Color bg, VoidCallback onTap) {
    return SizedBox(
      height: 24,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return Container(
      width: 50,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 14),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildColorBtn(String text, Color bg, VoidCallback onTap) {
    return SizedBox(
      height: 22,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
