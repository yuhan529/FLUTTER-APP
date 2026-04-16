import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/invite_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureDeviceId();
  runApp(const TravelApp());
}

Future<void> _ensureDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('device_id') == null) {
    prefs.setString('device_id', InviteService.generateDeviceId());
  }
  if (prefs.getString('nickname') == null) {
    prefs.setString('nickname', '旅伴');
  }
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '旅遊筆記',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B8A72), // 旅遊感：森林綠
          brightness: Brightness.light,
        ),
        fontFamily: 'NotoSansTC', // 中文字體（需加入 pubspec）
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}