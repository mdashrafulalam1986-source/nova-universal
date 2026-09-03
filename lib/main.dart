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

  String selectedBrand = 'Minister (মিনোস্টার)';
  String selectedMode = 'Smart TV (Wi-Fi)';
  TextEditingController ipController = TextEditingController(text: '192.168.0.100');

  final List<String> brands = [
    'Minister (মিনোস্টার)',
    'Walton',
    'Sony',
    'LG',
    'Samsung',
    'General IR'
  ];

  final List<String> modes = [
    'Smart TV (Wi-Fi)',
    'IR Blaster (ইনফ্রারেড)'
  ];

  Future<void> sendCommand(String key) async {
    HapticFeedback.lightImpact();
    if (selectedMode.contains('IR')) {
      try {
        await platform.invokeMethod('transmit', {
          'frequency': 38000,
          'pattern': [9000, 4500, 560, 560, 560, 1690],
        });
      } catch (_) {}
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
              // Dropdowns Row
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

              // IP Field
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

              // Status Bar
              Container(
                height: 28,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'READY (MINISTER - SMART)',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              // Power & Mute Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleBtn(Icons.power_settings_new, Colors.red, () => sendCommand('POWER')),
                  _buildCircleBtn(Icons.near_me, Colors.indigoAccent, () => sendCommand('NAV')),
                ],
              ),

              // Keypad Grid
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

              // App Buttons
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

              // Mode & Home Row
              Row(
                children: [
                  Expanded(child: _buildSmallBtn('HOME', () => sendCommand('HOME'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildSmallBtn('MODE', () => sendCommand('MODE'))),
                ],
              ),

              // D-Pad Directional Pad
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

              // Vol & Channel Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSmallBtn('HOME', () => sendCommand('HOME2')),
                  _buildSmallBtn('EXT', () => sendCommand('EXT')),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPillBtn('VOL +', () => sendCommand('VOL_UP')),
                  _buildPillBtn('RESPECT', () => sendCommand('RESPECT')),
                  _buildPillBtn('CH ▲', () => sendCommand('CH_UP')),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPillBtn('VOL -', () => sendCommand('VOL_DOWN')),
                  _buildPillBtn('TV', () => sendCommand('TV')),
                  _buildPillBtn('CH ▼', () => sendCommand('CH_DOWN')),
                ],
              ),

              // Media Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconBtn(Icons.fast_rewind, () => sendCommand('REWIND')),
                  _buildIconBtn(Icons.play_arrow, () => sendCommand('PLAY')),
                  _buildIconBtn(Icons.fast_forward, () => sendCommand('FFWD')),
                ],
              ),

              // Color Buttons
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

              // Footer Functions
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 3.5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                children: [
                  _buildSmallText('N-CH.P', () => sendCommand('FN1')),
                  _buildSmallText('CC', () => sendCommand('FN2')),
                  _buildSmallText('MTR', () => sendCommand('FN3')),
                  _buildSmallText('F-MODE', () => sendCommand('FN4')),
                  _buildSmallText('S.MCOB', () => sendCommand('FN5')),
                  _buildSmallText('CRLUST', () => sendCommand('FN6')),
                  _buildSmallText('FMODE', () => sendCommand('FN7')),
                  _buildSmallText('S.MODE', () => sendCommand('FN8')),
                  _buildSmallText('DELETE', () => sendCommand('FN9')),
                ],
              ),

              // Brand Title Footer
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
          backgroundColor: const Color(0xFF1E1E2C),
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

  Widget _buildSmallText(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
