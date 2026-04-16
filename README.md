# FLUTTER-APP
尚未測試


檔案對應關係
travel_app/                         ← flutter create 建立的資料夾
├── pubspec.yaml                    ← ✅ 已提供（相依套件）
├── lib/
│   ├── main.dart                   ← ✅ App 入口
│   ├── models/
│   │   └── trip_model.dart         ← ✅ 所有資料結構
│   ├── services/
│   │   ├── storage_service.dart    ← ✅ 檔案讀寫
│   │   ├── invite_service.dart     ← ✅ 邀請碼 + AES加密
│   │   └── sync_service.dart       ← ✅ WiFi 同步
│   └── screens/
│       ├── home_screen.dart        ← ✅ 首頁
│       ├── trip_screen.dart        ← ✅ 行程主畫面
│       ├── tabs/
│       │   ├── days_tab.dart           ← ✅ 行程天數
│       │   └── flights_hotels_souvenirs_tabs.dart ← ✅ 機票/住宿/伴手禮
│       └── other_screens.dart      ← ✅ 建立/加入/同步畫面



