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



建立步驟
1. 建立 Flutter 專案
bashflutter create travel_app
cd travel_app
2. 把提供的檔案複製進去
把所有 .dart 檔案依照上方路徑放到對應位置，
pubspec.yaml 直接取代原本的。
3. 建立資料夾
bashmkdir -p lib/models lib/services lib/screens/tabs assets/images assets/icons
4. 安裝套件
bashflutter pub get
5. Android 權限設定
在 android/app/src/main/AndroidManifest.xml 的 <manifest> 標籤內加入：
xml<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
6. iOS 權限設定
在 ios/Runner/Info.plist 加入：
xml<key>NSPhotoLibraryUsageDescription</key>
<string>需要存取相簿來上傳行程圖片</string>
<key>NSCameraUsageDescription</key>
<string>需要使用相機拍攝行程照片</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要藍牙來與旅伴同步行程資料</string>
<key>NSLocalNetworkUsageDescription</key>
<string>需要區域網路來與旅伴同步行程資料</string>
7. 執行
bash# 確認模擬器已啟動
flutter devices

# 執行
flutter run

已實作功能
功能狀態建立行程 + 自動產生邀請碼✅行程天數 + 景點（含圖片）✅景點交通資訊✅機票資訊✅住宿資訊（含備註）✅伴手禮清單（含購買狀態）✅圖片壓縮存本機✅JSON 離線儲存✅WiFi 同步（mDNS 發現 + HTTP 傳輸）✅AES-256 加密傳輸✅離線偵測（隱藏同步按鈕）✅中文介面✅
下一步可請 Claude 繼續實作

藍牙同步（flutter_blue_plus）
權限角色完整判斷（owner/editor/viewer）
圖片全螢幕預覽
行程封面圖設定
拖曳排序景點/天數
行程匯出 PDF


資料存放位置
手機本地/Documents/TravelApp/
├── invite_codes.json          # 持有的邀請碼清單
└── trips/
    └── {邀請碼}/
        ├── trip.json          # 完整行程資料
        ├── {dayId}/
        │   └── images/        # 景點圖片
        └── souvenirs/
            └── images/        # 伴手禮圖片




