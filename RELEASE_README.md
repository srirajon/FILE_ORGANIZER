# 📦 FileOrganizer — Release Readme

> **Mandatory Release Log & Distribution Reference**  
> *This document is automatically created/updated after every release build.*

---

## 🚀 Release Information: v1.5.0 (Build 5)

| Field | Detail |
|---|---|
| **Release Version** | `v1.5.0` (Build `5`) |
| **Release Date** | October 31, 2026 |
| **Compiled APK Package** | [`FileOrganizer_v1.5.0.apk`](./FileOrganizer_v1.5.0.apk) |
| **APK Binary Size** | **22.0 MB** (23,010,597 bytes) |
| **Package ID** | `com.fileorganizer.file_organizer` |
| **Target Architectures** | Universal: `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| **Minimum Android OS** | Android 7.0 (API Level 24) |
| **Target Android OS** | Android 15 (API Level 35) |
| **Compilation Toolchain** | Flutter 3.24.5 • Dart 3.5.4 • OpenJDK 17 • Gradle 8.7 • AGP 8.5.2 |

---

## 🌟 What's New in v1.5.0 (Level 7)

### 1. 🖼️ Rich Icon Catalog & Mobile Photo Avatars
* **Mobile Gallery Photos:** Users can now set any photo from their phone's gallery as the profile picture for a folder/chathead. Photos are automatically copied into the app's secure internal documents directory and persisted in `folders_config.json`.
* **6 Categorized Icon Sets:** Added an in-app icon picker dialog (`FolderAvatarPickerDialog`) featuring dozens of icons across:
  * 💼 **Work & Finance:** Briefcase, folders, charts, documents, bills, coins, calendar.
  * 🏠 **Personal & Home:** Home, keys, sofa, shopping, gifts, pets, travel, plane.
  * 🤖 **Tech & Media:** Laptop, mobile, robot, cameras, headphones, gaming, rocket.
  * 🏥 **Health & Fitness:** Hospital, medical, fitness, yoga, running, teeth, heart.
  * 📚 **Study & Research:** Books, graduation, pencils, ruler, science, microscope, brain.
  * ⭐ **Badges & Highlights:** Stars, sparks, fire, lightning, diamonds, targets, trophies.
* **Custom Emoji & Color Palette:** Enter any emoji from your keyboard and pick from 12 distinct background avatar colors.

### 2. 🛡️ Eliminated Duplicate Share Overlays (3-Screens Bug)
* **Stream Consolidation:** Replaced dual event firing in `ShareIntentService` by routing both single-file and multi-file intents into a unified `onIncomingFiles` dispatch stream.
* **Active Presentation Guard:** Added `_isShareOverlayShowing` lifecycle lock in `HomeScreen` ensuring exactly **ONE** share modal sheet appears on screen when sharing multiple files from other apps.

### 3. ⬇️ Chronological WhatsApp-Style Chat Stacking (Appending Down)
* **Chronological Flow:** Chat message bubbles now render from **oldest at the top to newest at the bottom** (matching authentic WhatsApp layout).
* **Auto-Scroll to Bottom:** Opening any chathead or sending a new file/note automatically scrolls smoothly down to the latest message.
* **Centered WhatsApp Date Dividers:** Messages across different days are cleanly separated by centered date pill badges (*"Today"*, *"Yesterday"*, or formatted dates like *"October 24"*).

### 4. 📄 PDF Full App Chooser Visibility
* **Android 11+ Package Visibility:** Added explicit `<queries>` intent filters in `AndroidManifest.xml` for `application/pdf`, images, videos, audio, and all mime types.
* **Accurate MIME Resolution:** Upgraded Kotlin native app launcher and Dart `SharedFileItem.effectiveMimeType` to detect `.pdf` extensions accurately so all third-party viewers (**Adobe Acrobat, Google Drive, Microsoft 365, WPS Office**) appear alongside system defaults.

### 5. 🎨 Resolved Front-End AppBar Overlap
* **Isolated Navigation & Avatar:** In `FolderChatScreen`, the back button is strictly confined to `leading`, while `FolderAvatar` and folder title occupy an adaptive flex container inside `title: InkWell(...)`.
* **Tap-to-Edit:** Tapping the AppBar avatar allows instant editing of the folder's photo, icon, or color directly from the chat screen.
* **Contact Tile Spacing:** Expanded title row in `WhatsAppContactTile` to guarantee no visual collision between avatars and long folder names.

### 6. 🕒 Authentic Dynamic Relative & Calendar Timestamps
* **Eliminated Static "Just now":** Removed hardcoded text on the main page. The app now displays authentic dynamic timestamps:
  * Same day: Exact time (e.g., `11:42 AM`)
  * Previous day: `Yesterday`
  * Within 2–6 days: Day name (e.g., `Wednesday`)
  * 7+ days: Standard date format (e.g., `24/10/26`)

### 7. ⏱️ Message Sent Time Retention
* Each shared file or text note permanently retains its original `sharedAt` timestamp across restarts and backups.

### 8. 🔝 WhatsApp-Style Chathead Auto-Sorting
* Implemented `sortFoldersByRecentActivity()` in `FolderConfigService` and `HomeScreen`.
* Whenever a new file, note, or caption is added to a folder, that chathead automatically re-sorts and bubbles to the very top of the list on the main page.

### 9. 🔄 Resilient Vault Restore & One-Tap Auto-Detection
* **In-Memory Bytes Decoding (`withData: true`):** Completely bypasses Android Scoped Storage file path restrictions when picking backup archives from Downloads or Google Drive.
* **ZIP Magic-Byte Header Detection:** Accurately recognizes ZIP archives by binary header (`PK\x03\x04`), regardless of temporary cache file names.
* **Deep Path Resolution:** Auto-detects `folders_config.json` inside the archive whether placed at the root or within subdirectories.
* **One-Tap "Auto-Detect & Restore Local Vault":** Added dedicated one-tap button in the Cloud Backup dialog that scans `/storage/emulated/0/Download/FileOrganizer/` and automatically restores without requiring the system file picker.
* **Permanent Release Keystore:** Signed with permanent RSA-2048 keystore (`android/app/release.jks`) ensuring future updates install seamlessly without signature conflicts.

---

## 💡 Why is this APK ~22 MB compared to the previous ~51 MB?

| Build Attribute | Previous Builds (`v1.3`, `v1.4`) | **v1.5.0 Release Build** |
|---|---|---|
| **Compilation Mode** | Debug / Non-minified JIT | **Production Release AOT** |
| **Dart Runtime** | Included full JIT compiler & VM (~30 MB) | **Compiled to native machine code (`libapp.so`)** |
| **R8 / ProGuard** | Disabled | **Enabled (dead code stripped)** |
| **Font Tree-Shaking** | Full font icon sets bundled (~2 MB) | **Tree-shaken (99.3% reduction to 10 KB)** |
| **Startup Speed** | Slower (JIT warmup) | **Instant native execution** |
| **Memory Footprint** | Higher (debugger hooks) | **Optimized for low RAM & battery** |
| **Feature Set** | Complete | **100% Complete & Untouched** |

> **Conclusion:** No features, code, or assets were lost. The 22 MB size represents the proper, optimized production release format for Android phones.

---

## 📲 How to Install & Upgrade on Your Device

1. **Transfer the APK:**  
   Copy [`FileOrganizer_v1.5.0.apk`](./FileOrganizer_v1.5.0.apk) to your Android phone via USB cable, Google Drive, WhatsApp, or local network.
2. **Open the File:**  
   On your phone, tap the APK in your file manager or browser downloads.
3. **Allow Installation:**  
   If prompted, enable *"Install unknown apps"* for the file manager.
4. **Tap Update / Install:**  
   The app will upgrade seamlessly in place; all your existing folders, notes, shared files, and configurations will be preserved.

---

## 🧪 Verification & Test Results

All automated unit and widget test suites passed with 0 errors:
```text
00:00 +0: Multiline text sanitization preserves paragraphs and converts CRLF to LF [PASS]
00:00 +1: SharedFileItem accurately detects isTextNote and updates caption/content [PASS]
00:00 +2: FolderContact and FolderConfigService prevent duplicate folders [PASS]
00:00 +3: FolderContact dynamically formats lastTimestamp according to WhatsApp rules [PASS]
00:00 +4: Chatheads auto-sort according to last message date [PASS]
00:00 +5: FolderContact supports customImagePath for mobile photo avatar [PASS]
00:00 +6: SharedFileItem effectiveMimeType reliably resolves PDF and documents [PASS]
00:05 +7: File Organizer App smoke test [PASS]
00:07 +8: All tests passed!
```

---

## 📋 Release History

| Version | Build | Release Date | APK Size | Key Focus |
|---|---|---|---|---|
| **v1.0** | 1 | Oct 2026 | — | MVP: System share intent interception, flat WhatsApp contact list. |
| **v1.1** | 2 | Oct 2026 | — | JSON config storage, dynamic folder creation, `.fo_backup` export/import. |
| **v1.2** | 3 | Oct 2026 | — | Copied AI text to `.md` notes, in-app Markdown reader, message pinning. |
| **v1.3** | 4 | Oct 2026 | 51.5 MB | File tagging, custom captions, Android system chooser, Google Drive sync. |
| **v1.4** | 4 | Oct 2026 | 51.6 MB | Preserved Facebook text formatting, duplicate folder fix, multi-file sharing. |
| **v1.5.0** | **5** | **Oct 2026** | **22.0 MB** | **Mobile photo avatars, rich icon catalog, chronological chat flow, PDF app chooser, dynamic dates & auto-sort to top.** |

