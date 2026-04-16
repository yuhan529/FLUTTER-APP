
// lib/services/sync_service.dart
// 區域網路同步：mDNS 裝置發現 + HTTP 資料傳輸
// 安全：所有 payload 用 AES-256 加密，以邀請碼為金鑰

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/trip_model.dart';
import 'storage_service.dart';
import 'invite_service.dart';

const int _kSyncPort = 47832; // 固定 port，可自訂
const String _kServiceType = '_travelapp._tcp';

enum SyncStatus { idle, discovering, syncing, done, error, offline }

class SyncDevice {
  final String deviceId;
  final String nickname;
  final String host;
  final int port;
  SyncDevice({
    required this.deviceId,
    required this.nickname,
    required this.host,
    required this.port,
  });
}

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();

  HttpServer? _server;
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  final List<SyncDevice> _discoveredDevices = [];
  List<SyncDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  // ── 檢查是否有 WiFi ───────────────────────────
  Future<bool> isOnLocalNetwork() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.wifi;
  }

  // ── 啟動本機 HTTP 伺服器（接收同步請求）────────
  Future<void> startServer({
    required String deviceId,
    required String nickname,
  }) async {
    if (_server != null) return;

    final handler = const Pipeline().addHandler((Request req) async {
      // 驗證來源：header 必須有 X-Device-Id
      final senderId = req.headers['X-Device-Id'];
      if (senderId == null) return Response.forbidden('Missing device id');

      final path = req.url.path;

      // GET /trip-json?inviteCode=XXXX  → 回傳加密的 trip.json
      if (req.method == 'GET' && path == 'trip-json') {
        final inviteCode = req.url.queryParameters['inviteCode'];
        if (inviteCode == null) return Response.badRequest();
        final json = await StorageService.instance.exportTripJson(inviteCode);
        if (json == null) return Response.notFound('Trip not found');
        final encrypted = InviteService.instance.encryptPayload(json, inviteCode);
        return Response.ok(encrypted, headers: {'Content-Type': 'text/plain'});
      }

      // GET /image-list?inviteCode=XXXX → 回傳圖片清單
      if (req.method == 'GET' && path == 'image-list') {
        final inviteCode = req.url.queryParameters['inviteCode'];
        if (inviteCode == null) return Response.badRequest();
        final list = await StorageService.instance.listAllImages(inviteCode);
        final encrypted = InviteService.instance.encryptPayload(
          jsonEncode(list), inviteCode,
        );
        return Response.ok(encrypted, headers: {'Content-Type': 'text/plain'});
      }

      // GET /image?inviteCode=XXXX&path=day1/images/abc.jpg
      if (req.method == 'GET' && path == 'image') {
        final inviteCode = req.url.queryParameters['inviteCode'];
        final imgPath = req.url.queryParameters['path'];
        if (inviteCode == null || imgPath == null) return Response.badRequest();
        final bytes = await StorageService.instance.readImageBytes(inviteCode, imgPath);
        if (bytes == null) return Response.notFound('Image not found');
        return Response.ok(bytes, headers: {'Content-Type': 'application/octet-stream'});
      }

      return Response.notFound('Unknown endpoint');
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _kSyncPort);
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  // ── mDNS 發現同網路裝置 ───────────────────────
  Future<List<SyncDevice>> discoverDevices({
    required String inviteCode,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _discoveredDevices.clear();
    _status = SyncStatus.discovering;

    final client = MDnsClient();
    await client.start();

    final deadline = DateTime.now().add(timeout);

    await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(_kServiceType),
    )) {
      if (DateTime.now().isAfter(deadline)) break;

      await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      )) {
        // 嘗試連線驗證是否持有相同邀請碼
        final device = await _probePeer(
          host: srv.target,
          port: srv.port,
          inviteCode: inviteCode,
        );
        if (device != null && !_discoveredDevices.any((d) => d.deviceId == device.deviceId)) {
          _discoveredDevices.add(device);
        }
        break;
      }
    }

    client.stop();
    _status = SyncStatus.idle;
    return _discoveredDevices;
  }

  // 探測對方是否有此邀請碼的行程
  Future<SyncDevice?> _probePeer({
    required String host,
    required int port,
    required String inviteCode,
  }) async {
    try {
      final res = await http.get(
        Uri.http('$host:$port', 'trip-json', {'inviteCode': inviteCode}),
        headers: {'X-Device-Id': 'probe'},
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return SyncDevice(
          deviceId: host, // 暫用 host
          nickname: host,
          host: host,
          port: port,
        );
      }
    } catch (_) {}
    return null;
  }

  // ── 執行同步（拉取對方資料，以 lastModified 決定勝負）
  Future<SyncResult> syncWithDevice({
    required SyncDevice peer,
    required String inviteCode,
    required String myDeviceId,
  }) async {
    _status = SyncStatus.syncing;
    int updatedFields = 0;
    int syncedImages = 0;

    try {
      // 1. 拉取對方 trip.json
      final res = await http.get(
        Uri.http('${peer.host}:${peer.port}', 'trip-json', {'inviteCode': inviteCode}),
        headers: {'X-Device-Id': myDeviceId},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('取得行程失敗');

      final decrypted = InviteService.instance.decryptPayload(res.body, inviteCode);
      if (decrypted == null) throw Exception('解密失敗，邀請碼不符');

      final remoteTrip = Trip.fromJsonString(decrypted);
      final localTrip = await StorageService.instance.loadTrip(inviteCode);

      // 2. 合併：各區塊以 lastModified 為準
      Trip merged;
      if (localTrip == null) {
        merged = remoteTrip;
      } else {
        merged = _mergeTrips(local: localTrip, remote: remoteTrip);
        updatedFields = _countDiff(localTrip, merged);
      }
      await StorageService.instance.saveTrip(merged);

      // 3. 同步圖片（只抓本地沒有的）
      final imgRes = await http.get(
        Uri.http('${peer.host}:${peer.port}', 'image-list', {'inviteCode': inviteCode}),
        headers: {'X-Device-Id': myDeviceId},
      ).timeout(const Duration(seconds: 5));

      if (imgRes.statusCode == 200) {
        final decryptedList = InviteService.instance.decryptPayload(imgRes.body, inviteCode);
        if (decryptedList != null) {
          final remoteImages = List<String>.from(jsonDecode(decryptedList));
          final localImages = await StorageService.instance.listAllImages(inviteCode);
          final missing = remoteImages.where((r) => !localImages.contains(r)).toList();

          for (final imgPath in missing) {
            final imgData = await http.get(
              Uri.http('${peer.host}:${peer.port}', 'image',
                {'inviteCode': inviteCode, 'path': imgPath}),
              headers: {'X-Device-Id': myDeviceId},
            ).timeout(const Duration(seconds: 30));

            if (imgData.statusCode == 200) {
              await StorageService.instance.writeImageBytes(
                inviteCode: inviteCode,
                relativePath: imgPath,
                bytes: imgData.bodyBytes,
              );
              syncedImages++;
            }
          }
        }
      }

      _status = SyncStatus.done;
      return SyncResult(success: true, updatedFields: updatedFields, syncedImages: syncedImages);
    } catch (e) {
      _status = SyncStatus.error;
      return SyncResult(success: false, errorMessage: e.toString());
    }
  }

  // ── 合併邏輯：比較 lastModified ──────────────
  Trip _mergeTrips({required Trip local, required Trip remote}) {
    final now = DateTime.now();

    // 對每個 list 做 upsert（以 id 對齊，取較新的版本）
    List<T> mergeList<T extends _HasId>(List<T> localList, List<T> remoteList) {
      final map = <String, T>{};
      for (final item in localList) map[item.id] = item;
      for (final item in remoteList) {
        final existing = map[item.id];
        if (existing == null || item.lastModified.isAfter(existing.lastModified)) {
          map[item.id] = item;
        }
      }
      return map.values.toList();
    }

    return Trip(
      id: local.id,
      inviteCode: local.inviteCode,
      title: remote.lastModified.isAfter(local.lastModified) ? remote.title : local.title,
      coverImagePath: remote.lastModified.isAfter(local.lastModified)
          ? remote.coverImagePath
          : local.coverImagePath,
      days: mergeList(local.days, remote.days),
      flights: mergeList(local.flights, remote.flights),
      hotels: mergeList(local.hotels, remote.hotels),
      souvenirs: mergeList(local.souvenirs, remote.souvenirs),
      members: [...{...local.members.map((m) => m.deviceId)}
          .map((id) => local.members.firstWhere((m) => m.deviceId == id))
          ...(remote.members.where(
              (m) => !local.members.any((lm) => lm.deviceId == m.deviceId)))],
      createdAt: local.createdAt,
      lastModified: now,
    );
  }

  int _countDiff(Trip a, Trip b) {
    int count = 0;
    if (a.title != b.title) count++;
    count += (b.days.length - a.days.length).abs();
    count += (b.flights.length - a.flights.length).abs();
    count += (b.hotels.length - a.hotels.length).abs();
    count += (b.souvenirs.length - a.souvenirs.length).abs();
    return count;
  }
}

// ── 結果物件 ──────────────────────────────────
class SyncResult {
  final bool success;
  final int updatedFields;
  final int syncedImages;
  final String? errorMessage;

  SyncResult({
    required this.success,
    this.updatedFields = 0,
    this.syncedImages = 0,
    this.errorMessage,
  });
}

// ── 讓 mergeList 能取 id 的 mixin ─────────────
abstract class _HasId {
  String get id;
  DateTime get lastModified;
}