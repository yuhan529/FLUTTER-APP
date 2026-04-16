
// lib/services/invite_service.dart
// 邀請碼產生、驗證、加密處理

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import 'storage_service.dart';

class InviteService {
  static InviteService? _instance;
  static InviteService get instance => _instance ??= InviteService._();
  InviteService._();

  final _uuid = const Uuid();
  final _random = Random.secure();

  // ── 產生邀請碼（8碼英數，大寫）────────────────
  String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 排除易混淆字元 O,0,I,1
    return List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  // ── 建立新行程 ───────────────────────────────
  Future<Trip> createTrip({
    required String title,
    required String ownerNickname,
    required String ownerDeviceId,
  }) async {
    final inviteCode = generateInviteCode();
    final now = DateTime.now();

    final trip = Trip(
      id: _uuid.v4(),
      inviteCode: inviteCode,
      title: title,
      days: [],
      flights: [],
      hotels: [],
      souvenirs: [],
      members: [
        TripMember(
          deviceId: ownerDeviceId,
          nickname: ownerNickname,
          role: UserRole.owner,
        ),
      ],
      createdAt: now,
      lastModified: now,
    );

    await StorageService.instance.saveTrip(trip);
    await StorageService.instance.saveInviteCode(inviteCode, 'owner');
    return trip;
  }

  // ── 加入行程（輸入邀請碼後） ─────────────────
  // 回傳 true = 格式合法（實際資料要靠同步取得）
  bool validateInviteCodeFormat(String code) {
    if (code.length != 8) return false;
    final valid = RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]+$');
    return valid.hasMatch(code.toUpperCase());
  }

  // ── AES-256 加密（傳輸用）────────────────────
  // key 由邀請碼衍生，確保只有知道邀請碼的人能解密
  enc.Key _keyFromInviteCode(String inviteCode) {
    final hash = sha256.convert(utf8.encode('TravelApp:$inviteCode')).bytes;
    return enc.Key(Uint8List.fromList(hash));
  }

  String encryptPayload(String plainText, String inviteCode) {
    final key = _keyFromInviteCode(inviteCode);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // 把 IV + 密文一起打包成 base64
    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  String? decryptPayload(String cipherBase64, String inviteCode) {
    try {
      final key = _keyFromInviteCode(inviteCode);
      final combined = base64.decode(cipherBase64);
      final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
      final cipherBytes = combined.sublist(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(enc.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
    } catch (_) {
      return null; // 解密失敗 = 邀請碼錯誤 or 資料被篡改
    }
  }

  // ── 裝置 ID（唯一識別此裝置） ─────────────────
  // 首次啟動時產生，存在 SharedPreferences
  static String generateDeviceId() => const Uuid().v4();
}

// 讓 encrypt 套件能用 Uint8List
import 'dart:typed_data';