// lib/services/storage_service.dart
// 負責所有本地檔案讀寫：JSON 行程資料 + 圖片

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/trip_model.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  // ── 取得根目錄 ────────────────────────────────────
  // iOS:   /Documents/TravelApp/
  // Android: /data/data/<app>/files/TravelApp/
  Future<Directory> get _rootDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/TravelApp');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get _tripsDir async {
    final root = await _rootDir;
    final dir = Directory('${root.path}/trips');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // 特定行程的資料夾
  Future<Directory> tripDir(String inviteCode) async {
    final trips = await _tripsDir;
    final dir = Directory('${trips.path}/$inviteCode');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> tripImagesDir(String inviteCode, String dayId) async {
    final base = await tripDir(inviteCode);
    final dir = Directory('${base.path}/$dayId/images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> souvenirImagesDir(String inviteCode) async {
    final base = await tripDir(inviteCode);
    final dir = Directory('${base.path}/souvenirs/images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── 行程 JSON ────────────────────────────────────
  Future<void> saveTrip(Trip trip) async {
    final dir = await tripDir(trip.inviteCode);
    final file = File('${dir.path}/trip.json');
    await file.writeAsString(trip.toJsonString());
  }

  Future<Trip?> loadTrip(String inviteCode) async {
    try {
      final dir = await tripDir(inviteCode);
      final file = File('${dir.path}/trip.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return Trip.fromJsonString(content);
    } catch (e) {
      return null;
    }
  }

  Future<List<Trip>> loadAllTrips() async {
    final trips = await _tripsDir;
    final List<Trip> result = [];
    if (!await trips.exists()) return result;
    await for (final entity in trips.list()) {
      if (entity is Directory) {
        final inviteCode = entity.path.split('/').last;
        final trip = await loadTrip(inviteCode);
        if (trip != null) result.add(trip);
      }
    }
    return result;
  }

  Future<void> deleteTrip(String inviteCode) async {
    final dir = await tripDir(inviteCode);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  // ── 邀請碼列表 ───────────────────────────────────
  // 記錄此裝置建立 or 加入的所有邀請碼
  Future<File> get _inviteCodesFile async {
    final root = await _rootDir;
    return File('${root.path}/invite_codes.json');
  }

  Future<Map<String, String>> loadInviteCodes() async {
    // 回傳 {inviteCode: role}
    try {
      final f = await _inviteCodesFile;
      if (!await f.exists()) return {};
      final content = await f.readAsString();
      final Map<String, dynamic> json = jsonDecode(content);
      return json.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveInviteCode(String inviteCode, String role) async {
    final codes = await loadInviteCodes();
    codes[inviteCode] = role;
    final f = await _inviteCodesFile;
    await f.writeAsString(jsonEncode(codes));
  }

  Future<void> removeInviteCode(String inviteCode) async {
    final codes = await loadInviteCodes();
    codes.remove(inviteCode);
    final f = await _inviteCodesFile;
    await f.writeAsString(jsonEncode(codes));
  }

  // ── 圖片存取 ─────────────────────────────────────
  // 儲存景點圖片，回傳相對路徑
  Future<String> savePlaceImage({
    required String inviteCode,
    required String dayId,
    required String imageId,
    required File sourceFile,
  }) async {
    final dir = await tripImagesDir(inviteCode, dayId);
    final ext = sourceFile.path.split('.').last.toLowerCase();
    final dest = File('${dir.path}/$imageId.$ext');

    // 壓縮後存檔（節省空間，保留品質）
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
      final compressed = await FlutterImageCompress.compressWithFile(
        sourceFile.absolute.path,
        quality: 82,
        minWidth: 1200,
        minHeight: 1200,
      );
      if (compressed != null) {
        await dest.writeAsBytes(compressed);
      } else {
        await sourceFile.copy(dest.path);
      }
    } else {
      // gif 等其他格式直接複製
      await sourceFile.copy(dest.path);
    }

    // 回傳相對路徑（用於 JSON 儲存）
    return '$dayId/images/$imageId.$ext';
  }

  // 儲存伴手禮圖片
  Future<String> saveSouvenirImage({
    required String inviteCode,
    required String imageId,
    required File sourceFile,
  }) async {
    final dir = await souvenirImagesDir(inviteCode);
    final ext = sourceFile.path.split('.').last.toLowerCase();
    final dest = File('${dir.path}/$imageId.$ext');

    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
      final compressed = await FlutterImageCompress.compressWithFile(
        sourceFile.absolute.path,
        quality: 82,
        minWidth: 800,
        minHeight: 800,
      );
      if (compressed != null) {
        await dest.writeAsBytes(compressed);
      } else {
        await sourceFile.copy(dest.path);
      }
    } else {
      await sourceFile.copy(dest.path);
    }

    return 'souvenirs/images/$imageId.$ext';
  }

  // 根據相對路徑取得完整 File
  Future<File> resolveImageFile(String inviteCode, String relativePath) async {
    final dir = await tripDir(inviteCode);
    return File('${dir.path}/$relativePath');
  }

  // 刪除圖片
  Future<void> deleteImage(String inviteCode, String relativePath) async {
    final file = await resolveImageFile(inviteCode, relativePath);
    if (await file.exists()) await file.delete();
  }

  // ── 同步用：打包整個行程 ─────────────────────────
  // 回傳 trip.json 內容（同步時傳給對方）
  Future<String?> exportTripJson(String inviteCode) async {
    final trip = await loadTrip(inviteCode);
    return trip?.toJsonString();
  }

  // 回傳指定行程所有圖片路徑清單（同步時用來比對哪些圖需要傳）
  Future<List<String>> listAllImages(String inviteCode) async {
    final dir = await tripDir(inviteCode);
    final List<String> result = [];
    if (!await dir.exists()) return result;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final ext = entity.path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
          // 轉為相對路徑
          final rel = entity.path.replaceFirst('${dir.path}/', '');
          result.add(rel);
        }
      }
    }
    return result;
  }

  // 取得圖片 bytes（用於藍牙/WiFi 傳輸）
  Future<List<int>?> readImageBytes(String inviteCode, String relativePath) async {
    final file = await resolveImageFile(inviteCode, relativePath);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  // 接收並儲存從其他裝置傳來的圖片
  Future<void> writeImageBytes({
    required String inviteCode,
    required String relativePath,
    required List<int> bytes,
  }) async {
    final dir = await tripDir(inviteCode);
    final file = File('${dir.path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }
}