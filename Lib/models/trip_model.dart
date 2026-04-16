
// lib/models/trip_model.dart
// 所有資料結構定義，序列化為 JSON 存在手機檔案

import 'dart:convert';

// ─────────────────────────────────────────
// 權限角色
// ─────────────────────────────────────────
enum UserRole { owner, editor, viewer }

UserRole userRoleFromString(String s) {
  switch (s) {
    case 'editor': return UserRole.editor;
    case 'viewer': return UserRole.viewer;
    default: return UserRole.owner;
  }
}

String userRoleToString(UserRole r) {
  switch (r) {
    case UserRole.owner: return 'owner';
    case UserRole.editor: return 'editor';
    case UserRole.viewer: return 'viewer';
  }
}

// ─────────────────────────────────────────
// 參與者
// ─────────────────────────────────────────
class TripMember {
  final String deviceId;
  final String nickname;
  final UserRole role;

  TripMember({
    required this.deviceId,
    required this.nickname,
    required this.role,
  });

  factory TripMember.fromJson(Map<String, dynamic> j) => TripMember(
    deviceId: j['deviceId'],
    nickname: j['nickname'],
    role: userRoleFromString(j['role']),
  );

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'nickname': nickname,
    'role': userRoleToString(role),
  };
}

// ─────────────────────────────────────────
// 交通資訊
// ─────────────────────────────────────────
class TransportInfo {
  final String id;
  String departureTime;   // "09:30"
  String departurePlace;
  String arrivalPlace;
  String transportType;   // 捷運、公車、計程車、步行、租車…
  String note;
  DateTime lastModified;

  TransportInfo({
    required this.id,
    required this.departureTime,
    required this.departurePlace,
    required this.arrivalPlace,
    required this.transportType,
    this.note = '',
    required this.lastModified,
  });

  factory TransportInfo.fromJson(Map<String, dynamic> j) => TransportInfo(
    id: j['id'],
    departureTime: j['departureTime'],
    departurePlace: j['departurePlace'],
    arrivalPlace: j['arrivalPlace'],
    transportType: j['transportType'],
    note: j['note'] ?? '',
    lastModified: DateTime.parse(j['lastModified']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'departureTime': departureTime,
    'departurePlace': departurePlace,
    'arrivalPlace': arrivalPlace,
    'transportType': transportType,
    'note': note,
    'lastModified': lastModified.toIso8601String(),
  };
}

// ─────────────────────────────────────────
// 景點 / 行程項目
// ─────────────────────────────────────────
class PlaceItem {
  final String id;
  String time;             // "10:00"
  String name;
  String description;
  String imagePath;        // 相對路徑，例如 "day1/images/abc.jpg"
  DateTime lastModified;

  PlaceItem({
    required this.id,
    required this.time,
    required this.name,
    this.description = '',
    this.imagePath = '',
    required this.lastModified,
  });

  factory PlaceItem.fromJson(Map<String, dynamic> j) => PlaceItem(
    id: j['id'],
    time: j['time'],
    name: j['name'],
    description: j['description'] ?? '',
    imagePath: j['imagePath'] ?? '',
    lastModified: DateTime.parse(j['lastModified']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'lastModified': lastModified.toIso8601String(),
  };
}

// ─────────────────────────────────────────
// 每日行程
// ─────────────────────────────────────────
class TripDay {
  final String id;
  int dayNumber;
  String date;             // "2025-03-15"
  String title;            // 例如 "第一天 · 東京抵達"
  List<PlaceItem> places;
  List<TransportInfo> transports;
  DateTime lastModified;

  TripDay({
    required this.id,
    required this.dayNumber,
    required this.date,
    required this.title,
    required this.places,
    required this.transports,
    required this.lastModified,
  });

  factory TripDay.fromJson(Map<String, dynamic> j) => TripDay(
    id: j['id'],
    dayNumber: j['dayNumber'],
    date: j['date'],
    title: j['title'],
    places: (j['places'] as List).map((e) => PlaceItem.fromJson(e)).toList(),
    transports: (j['transports'] as List).map((e) => TransportInfo.fromJson(e)).toList(),
    lastModified: DateTime.parse(j['lastModified']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayNumber': dayNumber,
    'date': date,
    'title': title,
    'places': places.map((e) => e.toJson()).toList(),
    'transports': transports.map((e) => e.toJson()).toList(),
    'lastModified': lastModified.toIso8601String(),
  };
}

// ─────────────────────────────────────────
// 機票
// ─────────────────────────────────────────
class FlightInfo {
  final String id;
  String flightNumber;     // "JL801"
  String airline;
  String departureAirport;
  String arrivalAirport;
  String departureTime;    // "2025-03-15 08:30"
  String arrivalTime;
  String note;
  DateTime lastModified;

  FlightInfo({
    required this.id,
    required this.flightNumber,
    required this.airline,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    this.note = '',
    required this.lastModified,
  });

  factory FlightInfo.fromJson(Map<String, dynamic> j) => FlightInfo(
    id: j['id'],
    flightNumber: j['flightNumber'],
    airline: j['airline'],
    departureAirport: j['departureAirport'],
    arrivalAirport: j['arrivalAirport'],
    departureTime: j['departureTime'],
    arrivalTime: j['arrivalTime'],
    note: j['note'] ?? '',
    lastModified: DateTime.parse(j['lastModified']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'flightNumber': flightNumber,
    'airline': airline,
    'departureAirport': departureAirport,
    'arrivalAirport': arrivalAirport,
    'departureTime': departureTime,
    'arrivalTime': arrivalTime,
    'note': note,
    'lastModified': lastModified.toIso8601String(),
  };
}

// ─────────────────────────────────────────
// 住宿
// ─────────────────────────────────────────
class HotelInfo {
  final String id;
  String name;
  String address;
  String checkIn;          // "2025-03-15"
  String checkOut;
  String confirmationCode;
  String note;             // 備註（停車、早餐時間…）
  DateTime lastModified;

  HotelInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.checkIn,
    required this.checkOut,
    this.confirmationCode = '',
    this.note = '',
    required this.lastModified,
  });

  factory HotelInfo.fromJson(Map<String, dynamic> j) => HotelInfo(
    id: j['id'],
    name: j['name'],
    address: j['address'],
    checkIn: j['checkIn'],
    checkOut: j['checkOut'],
    confirmationCode: j['confirmationCode'] ?? '',
    note: j['note'] ?? '',
    lastModified: DateTime.parse(j['lastModified']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'checkIn': checkIn,
    'checkOut': checkOut,
    'confirmationCode': confirmationCode,
    'note': note,
    'lastModified': lastModified.toIso8601String(),
  };
}

// ─────────────────────────────────────────
// 伴手禮
// ─────────────────────────────────────────
class SouvenirItem {
  final String id;
  String name;
  String shopName;
  String shopLocation;
  double price;
  String currency;         // "JPY", "TWD"…
  String imagePath;
  bool isPurchased;
  String note;
  DateTime lastModified;

  SouvenirItem({
    required this.id,
    required this.name,
    required this.shopName,
    required this.shopLocation,
    required this.price,
    this.currency = 'TWD',
    this.imagePath = '',
    this.isPurchased = false,
    this.note = '',
    required this.lastModified,
  });

  factory SouvenirItem.fromJson(Map<String, dynamic> j) => SouvenirItem(
    id: j['id'],
    name: j['name'],
    shopName: j['shopName'],
    shopLocation: j['shopLocation'],
    price: (j['price'] as num).toDouble(),
    currency: j['currency'] ?? 'TWD',
    imagePath: j['imagePath'] ?? '',
    isPurchased: j['isPurchased'] ?? false,
    note: j['note'] ?? '',
    lastModified: DateTime.parse(j['lastModified']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shopName': shopName,
    'shopLocation': shopLocation,
    'price': price,
    'currency': currency,
    'imagePath': imagePath,
    'isPurchased': isPurchased,
    'note': note,
    'lastModified': lastModified.toIso8601String(),
  };
}

// ─────────────────────────────────────────
// 主行程
// ─────────────────────────────────────────
class Trip {
  final String id;
  final String inviteCode;       // 8碼邀請碼
  String title;                  // "2025 東京五天四夜"
  String coverImagePath;
  List<TripDay> days;
  List<FlightInfo> flights;
  List<HotelInfo> hotels;
  List<SouvenirItem> souvenirs;
  List<TripMember> members;
  DateTime createdAt;
  DateTime lastModified;

  Trip({
    required this.id,
    required this.inviteCode,
    required this.title,
    this.coverImagePath = '',
    required this.days,
    required this.flights,
    required this.hotels,
    required this.souvenirs,
    required this.members,
    required this.createdAt,
    required this.lastModified,
  });

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    id: j['id'],
    inviteCode: j['inviteCode'],
    title: j['title'],
    coverImagePath: j['coverImagePath'] ?? '',
    days: (j['days'] as List).map((e) => TripDay.fromJson(e)).toList(),
    flights: (j['flights'] as List).map((e) => FlightInfo.fromJson(e)).toList(),
    hotels: (j['hotels'] as List).map((e) => HotelInfo.fromJson(e)).toList(),
    souvenirs: (j['souvenirs'] as List).map((e) => SouvenirItem.fromJson(e)).toList(),
    members: (j['members'] as List).map((e) => TripMember.fromJson(e)).toList(),
    createdAt: DateTime.parse(j['createdAt']),
    lastModified: DateTime.parse(j['lastModified']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'inviteCode': inviteCode,
    'title': title,
    'coverImagePath': coverImagePath,
    'days': days.map((e) => e.toJson()).toList(),
    'flights': flights.map((e) => e.toJson()).toList(),
    'hotels': hotels.map((e) => e.toJson()).toList(),
    'souvenirs': souvenirs.map((e) => e.toJson()).toList(),
    'members': members.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());
  static Trip fromJsonString(String s) => Trip.fromJson(jsonDecode(s));
}