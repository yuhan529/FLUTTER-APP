// lib/screens/home_screen.dart
// 首頁：顯示所有行程，可建立新行程 or 加入行程

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../services/storage_service.dart';
import '../services/invite_service.dart';
import 'trip_screen.dart';
import 'create_trip_screen.dart';
import 'join_trip_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trip> _trips = [];
  bool _loading = true;
  String _nickname = '旅伴';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final trips = await StorageService.instance.loadAllTrips();
    setState(() {
      _nickname = prefs.getString('nickname') ?? '旅伴';
      _trips = trips..sort((a, b) => b.lastModified.compareTo(a.lastModified));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: CustomScrollView(
        slivers: [
          // ── 頂部標題列 ──
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFF7F5F0),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '你好，$_nickname 👋',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const Text(
                        '我的旅程',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _showSettingsDialog,
                    icon: const Icon(Icons.person_outline, color: Color(0xFF5B8A72)),
                  ),
                ],
              ),
            ),
          ),

          // ── 行程列表 ──
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_trips.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                onCreateTrip: _goCreateTrip,
                onJoinTrip: _goJoinTrip,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _TripCard(
                    trip: _trips[i],
                    onTap: () => _openTrip(_trips[i]),
                    onDelete: () => _deleteTrip(_trips[i]),
                  ),
                  childCount: _trips.length,
                ),
              ),
            ),
        ],
      ),

      // ── 底部按鈕 ──
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: _goJoinTrip,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF5B8A72),
            elevation: 2,
            icon: const Icon(Icons.qr_code_scanner_outlined),
            label: const Text('加入行程'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _goCreateTrip,
            backgroundColor: const Color(0xFF5B8A72),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('建立行程'),
          ),
        ],
      ),
    );
  }

  void _openTrip(Trip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TripScreen(trip: trip)),
    );
    _loadData(); // 返回後重新載入
  }

  void _goCreateTrip() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
    _loadData();
  }

  void _goJoinTrip() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinTripScreen()),
    );
    _loadData();
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除行程'),
        content: Text('確定要刪除「${trip.title}」？\n此動作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.instance.deleteTrip(trip.inviteCode);
      await StorageService.instance.removeInviteCode(trip.inviteCode);
      _loadData();
    }
  }

  void _showSettingsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController(text: prefs.getString('nickname'));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('暱稱設定'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '你的名字'),
          maxLength: 12,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await prefs.setString('nickname', name);
                setState(() => _nickname = name);
              }
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}

// ── 行程卡片 ─────────────────────────────────
class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _TripCard({required this.trip, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面圖
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: const Color(0xFF5B8A72).withOpacity(0.15),
                  child: trip.coverImagePath.isEmpty
                      ? const Icon(Icons.flight_takeoff, size: 48, color: Color(0xFF5B8A72))
                      : Image.file(
                          // 實際使用時要搭配 StorageService 解析路徑
                          height: 120, fit: BoxFit.cover,
                          // placeholder
                          width: double.infinity,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                '${trip.days.length} 天',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.people_outline, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                '${trip.members.length} 人',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B8A72).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '邀請碼：${trip.inviteCode}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5B8A72),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 空狀態 ────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTrip;
  final VoidCallback onJoinTrip;
  const _EmptyState({required this.onCreateTrip, required this.onJoinTrip});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.luggage_outlined, size: 72, color: Color(0xFF5B8A72)),
          const SizedBox(height: 16),
          const Text(
            '還沒有行程',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 8),
          Text(
            '建立新行程，或輸入邀請碼加入朋友的旅程',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(Icons.add),
            label: const Text('建立行程'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8A72),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onJoinTrip,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('加入行程'),
          ),
        ],
      ),
    );
  }
}