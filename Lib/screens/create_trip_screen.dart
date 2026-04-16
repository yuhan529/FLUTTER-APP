// lib/screens/create_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/invite_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});
  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _titleCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        title: const Text('建立行程'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('行程名稱', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: '例如：2025 東京五天四夜',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text('建立後系統會自動產生 8 碼邀請碼，分享給旅伴即可加入',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8A72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('建立行程', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    final nickname = prefs.getString('nickname') ?? '旅伴';

    final trip = await InviteService.instance.createTrip(
      title: title,
      ownerNickname: nickname,
      ownerDeviceId: deviceId,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('行程已建立！邀請碼：${trip.inviteCode}')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════
// lib/screens/join_trip_screen.dart
// ═══════════════════════════════════════════════════════

class JoinTripScreen extends StatefulWidget {
  const JoinTripScreen({super.key});
  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  final _codeCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(backgroundColor: const Color(0xFFF7F5F0), title: const Text('加入行程')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('輸入邀請碼', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              style: const TextStyle(letterSpacing: 6, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'XXXXXXXX',
                hintStyle: const TextStyle(letterSpacing: 6, fontSize: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                errorText: _error.isEmpty ? null : _error,
              ),
              onChanged: (v) {
                _codeCtrl.value = _codeCtrl.value.copyWith(text: v.toUpperCase());
              },
            ),
            const SizedBox(height: 8),
            Text('請確保你與邀請人在同一 WiFi 或藍牙範圍內，輸入邀請碼後系統會自動同步行程資料',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8A72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('加入行程', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (!InviteService.instance.validateInviteCodeFormat(code)) {
      setState(() => _error = '邀請碼格式不正確（8碼英數字）');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    // 儲存邀請碼，之後到 SyncScreen 實際拉取資料
    await InviteService.instance;
    // TODO: 導向同步畫面搜尋裝置
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('邀請碼已儲存，請在同 WiFi 下開啟同步')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════
// lib/screens/sync_screen.dart
// ═══════════════════════════════════════════════════════

class SyncScreen extends StatefulWidget {
  final Trip trip;
  const SyncScreen({super.key, required this.trip});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  List<SyncDevice> _devices = [];
  SyncStatus _status = SyncStatus.idle;
  String _message = '';
  bool _discovering = false;

  @override
  void initState() {
    super.initState();
    _discover();
  }

  void _discover() async {
    setState(() { _discovering = true; _devices = []; _message = '搜尋附近裝置中…'; });
    final devices = await SyncService.instance.discoverDevices(
      inviteCode: widget.trip.inviteCode,
    );
    setState(() {
      _discovering = false;
      _devices = devices;
      _message = devices.isEmpty ? '未找到裝置，請確認對方已開啟 App 且在相同 WiFi' : '找到 ${devices.length} 台裝置';
    });
  }

  void _syncWith(SyncDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    setState(() { _status = SyncStatus.syncing; _message = '同步中…'; });

    final result = await SyncService.instance.syncWithDevice(
      peer: device,
      inviteCode: widget.trip.inviteCode,
      myDeviceId: deviceId,
    );

    setState(() {
      _status = result.success ? SyncStatus.done : SyncStatus.error;
      _message = result.success
          ? '同步完成！更新了 ${result.updatedFields} 個項目，${result.syncedImages} 張圖片'
          : '同步失敗：${result.errorMessage}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(backgroundColor: const Color(0xFFF7F5F0), title: const Text('同步行程')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 狀態指示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                if (_discovering || _status == SyncStatus.syncing)
                  const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(
                    _status == SyncStatus.done ? Icons.check_circle : Icons.sync,
                    color: _status == SyncStatus.done ? Colors.green : const Color(0xFF5B8A72),
                  ),
                const SizedBox(width: 12),
                Expanded(child: Text(_message)),
              ]),
            ),
            const SizedBox(height: 16),

            // 裝置列表
            if (_devices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.phone_android, color: Color(0xFF5B8A72)),
                        title: Text(d.nickname),
                        subtitle: Text(d.host),
                        trailing: ElevatedButton(
                          onPressed: _status == SyncStatus.syncing
                              ? null
                              : () => _syncWith(d),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B8A72),
                              foregroundColor: Colors.white),
                          child: const Text('同步'),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Spacer(),
            TextButton.icon(
              onPressed: _discovering ? null : _discover,
              icon: const Icon(Icons.refresh),
              label: const Text('重新搜尋'),
            ),
          ],
        ),
      ),
    );
  }
}

// 需要 import
import '../models/trip_model.dart';
import '../services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';