// lib/screens/trip_screen.dart
// 行程主畫面：底部 Tab 切換各功能區塊

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/trip_model.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import 'tabs/days_tab.dart';
import 'tabs/flights_tab.dart';
import 'tabs/hotels_tab.dart';
import 'tabs/souvenirs_tab.dart';
import 'sync_screen.dart';

class TripScreen extends StatefulWidget {
  final Trip trip;
  const TripScreen({super.key, required this.trip});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  late Trip _trip;
  int _currentTab = 0;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isOnline = result == ConnectivityResult.wifi);
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    setState(() => _isOnline = result == ConnectivityResult.wifi);
  }

  Future<void> _reloadTrip() async {
    final updated = await StorageService.instance.loadTrip(_trip.inviteCode);
    if (updated != null && mounted) setState(() => _trip = updated);
  }

  Future<void> _saveTrip(Trip updated) async {
    await StorageService.instance.saveTrip(updated);
    setState(() => _trip = updated);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DaysTab(trip: _trip, onSave: _saveTrip, canEdit: _canEdit),
      FlightsTab(trip: _trip, onSave: _saveTrip, canEdit: _canEdit),
      HotelsTab(trip: _trip, onSave: _saveTrip, canEdit: _canEdit),
      SouvenirsTab(trip: _trip, onSave: _saveTrip, canEdit: _canEdit),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        title: Column(
          children: [
            Text(_trip.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? '已連線' : '離線模式',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 邀請碼按鈕
          IconButton(
            onPressed: _showInviteCode,
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享邀請碼',
          ),
          // 同步按鈕（只有 WiFi 時顯示）
          if (_isOnline)
            IconButton(
              onPressed: _goSync,
              icon: const Icon(Icons.sync),
              tooltip: '同步行程',
            ),
        ],
      ),
      body: tabs[_currentTab],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '行程',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_outlined),
            selectedIcon: Icon(Icons.flight),
            label: '機票',
          ),
          NavigationDestination(
            icon: Icon(Icons.hotel_outlined),
            selectedIcon: Icon(Icons.hotel),
            label: '住宿',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: '伴手禮',
          ),
        ],
      ),
    );
  }

  bool get _canEdit {
    // 暫以本地 invite_codes.json 判斷角色
    // 完整版需從 trip.members 查詢 deviceId
    return true; // TODO: 依 role 回傳
  }

  void _showInviteCode() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('分享邀請碼',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('把邀請碼分享給旅伴，讓他們加入行程',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8A72).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _trip.inviteCode,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: Color(0xFF5B8A72),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '請確保雙方都在相同 WiFi 或開啟藍牙',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _goSync() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SyncScreen(trip: _trip)),
    );
    _reloadTrip();
  }
}