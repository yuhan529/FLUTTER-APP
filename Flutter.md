


# Flutter 開發環境建置指南（VS Code）
你需要的工具清單

VS Code（已有）
Flutter SDK
Git
Android Studio（僅需 Android 模擬器，不需要用它寫程式）
Xcode（如果你有 Mac，才能跑 iOS）


## 第一步：安裝 Git

前往 https://git-scm.com/downloads
下載並安裝（Windows 選預設選項即可）
安裝完成後開啟終端機輸入：git --version 確認成功


## 第二步：安裝 Flutter SDK
Windows：

前往 https://docs.flutter.dev/get-started/install/windows
下載 Flutter SDK zip
解壓縮到 C:\flutter（不要放在 Program Files，會有權限問題）
將 C:\flutter\bin 加入環境變數 PATH：

搜尋「環境變數」→ 編輯系統環境變數
Path → 新增 → C:\flutter\bin


重新開啟終端機，輸入：flutter --version

Mac：
bash# 用 Homebrew 安裝最簡單
brew install --cask flutter
flutter --version

## 第三步：安裝 Android Studio（取得 Android 模擬器）

前往 https://developer.android.com/studio
安裝完成後開啟 Android Studio
點選 More Actions → SDK Manager
確認已安裝 Android SDK
More Actions → Virtual Device Manager → 建立一台虛擬手機（推薦 Pixel 7, API 34）


## 第四步：安裝 VS Code 擴充套件
在 VS Code 的 Extensions（Ctrl+Shift+X）搜尋安裝：

Flutter（由 Dart Code 提供）
Dart（通常會自動安裝）


## 第五步：確認環境
在終端機執行：
bashflutter doctor
確認所有項目都是 ✓（Android toolchain 和 VS Code 那兩項最重要）

## 第六步：建立並執行專案
bash# 建立專案（在你想放的資料夾）
flutter create travel_app
cd travel_app

# 用 VS Code 開啟
code .

# 啟動模擬器後執行
flutter run

iOS 注意事項（需要 Mac）

Windows 無法編譯 iOS app，只能跑 Android
如果你有 Mac，需要額外安裝 Xcode：

bash  xcode-select --install
  sudo xcodebuild -license

實體 iPhone 測試需要 Apple Developer 帳號


### 常見問題
問題解法flutter: command not foundPATH 沒設好，重新檢查第二步Android 模擬器很慢開啟 BIOS 的 Intel VT-x 虛擬化Unable to locate Android SDK在 Android Studio 重新安裝 SDK

環境建置完成後，依照 01_專案結構說明.md 開始建立旅遊 App 專案。
