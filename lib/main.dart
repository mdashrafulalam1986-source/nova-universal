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
      title: 'nova universal',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF12131A),
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
  String connectionMode = 'IR Blaster (ইনফ্রারেড)';

  Future<void> sendIrCommand(String commandName) async {
    try {
      final String result = await platform.invokeMethod('transmitIR', {
        'brand': selectedBrand,
        'command': commandName,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$commandName Signal Sent ($result)'),
          duration: const Duration(milliseconds: 500),
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

  Widget _buildBtn(String label, {Color? color, Color textColor = Colors.white, double height = 45}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? const Color(0xFF262837),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: EdgeInsets.zero,
          ),
          onPressed: () => sendIrCommand(label),
          child: Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nova universal', style: TextStyle(fontSize: 18, color: Colors.white70)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBrand,
                    decoration: const InputDecoration(labelText: 'টিভি ব্র্যান্ড নির্বাচন করুন:', labelStyle: TextStyle(fontSize: 10, color: Colors.grey)),
                    items: ['Minister (মিনোস্টার)', 'Samsung', 'LG', 'Sony', 'Walton']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => selectedBrand = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: connectionMode,
                    decoration: const InputDecoration(labelText: 'সংযোগ মোড:', labelStyle: TextStyle(fontSize: 10, color: Colors.grey)),
                    items: ['IR Blaster (ইনফ্রারেড)', 'Wi-Fi / Smart TV']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => connectionMode = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('READY (${selectedBrand.toUpperCase()} - IR)', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.power_settings_new, color: Colors.red, size: 36),
                  onPressed: () => sendIrCommand('POWER'),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent, size: 32),
                  onPressed: () => sendIrCommand('CAST'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Keypad 1-9
            Row(children: [_buildBtn('1'), _buildBtn('2'), _buildBtn('3')]),
            Row(children: [_buildBtn('4'), _buildBtn('5'), _buildBtn('6')]),
            Row(children: [_buildBtn('7'), _buildBtn('8'), _buildBtn('9')]),
            Row(children: [_buildBtn('-'), _buildBtn('0'), _buildBtn('P')]),
            const SizedBox(height: 8),
            // Streaming Services
            Row(
              children: [
                _buildBtn('YouTube', color: Colors.red[700]),
                _buildBtn('Hoichoi', color: Colors.blue[800]),
                _buildBtn('Amazon', color: Colors.lightBlue[600]),
              ],
            ),
            Row(children: [_buildBtn('NETFLIX', color: Colors.red[800])]),
            Row(children: [_buildBtn('HOME'), _buildBtn('MODE')]),
            const SizedBox(height: 15),
            // D-Pad Controller
            Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(color: Color(0xFF1E202C), shape: BoxShape.circle),
              child: Stack(
                children: [
                  Align(alignment: Alignment.topCenter, child: IconButton(icon: const Icon(Icons.arrow_drop_up), onPressed: () => sendIrCommand('UP'))),
                  Align(alignment: Alignment.bottomCenter, child: IconButton(icon: const Icon(Icons.arrow_drop_down), onPressed: () => sendIrCommand('DOWN'))),
                  Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_left), onPressed: () => sendIrCommand('LEFT'))),
                  Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.arrow_right), onPressed: () => sendIrCommand('RIGHT'))),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: const Color(0xFF2C2D3C)),
                      onPressed: () => sendIrCommand('OK'),
                      child: const Text('OK', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(children: [_buildBtn('HOME'), _buildBtn('EXT')]),
            Row(
              children: [
                Expanded(child: Column(children: [_buildBtn('VOL +'), _buildBtn('VOL -')])),
                Expanded(child: Column(children: [_buildBtn('RESPECT'), _buildBtn('TV')])),
                Expanded(child: Column(children: [_buildBtn('CH ▲'), _buildBtn('CH ▼')])),
              ],
            ),
            Row(children: [_buildBtn('⏮'), _buildBtn('⏯'), _buildBtn('⏭')]),
            Row(
              children: [
                _buildBtn('HPC', color: Colors.red),
                _buildBtn('MASE', color: Colors.green),
                _buildBtn('CC', color: Colors.amber, textColor: Colors.black),
                _buildBtn('🔒', color: Colors.blue),
              ],
            ),
            Row(children: [_buildBtn('N-CH.P'), _buildBtn('CC'), _buildBtn('MTR')]),
            Row(children: [_buildBtn('F-MODE'), _buildBtn('S.MCOB'), _buildBtn('CRLUST')]),
            Row(children: [_buildBtn('FMODE'), _buildBtn('S.MODE'), _buildBtn('DELETE')]),
            const SizedBox(height: 15),
            const Text('NOVA UNIVERSAL', style: TextStyle(color: Colors.green, fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
