# 📁 File Organizer (WhatsApp-Style Folder Contacts)

> Bypassing the friction of navigating nested Google Drive sub-folders by visually styling folders as conversational WhatsApp contacts.

---

## 📱 Android Releases (Ready to Install)

The newest compiled Android release package is ready in the workspace root:
- 👉 **[`FileOrganizer_v1.4.apk`](file:///c:/src/FileOrganizer/FileOrganizer_v1.4.apk)** *(51.6 MB — Release APK with Preserved Facebook Look & Feel, Multi-File Sharing & Long-Press Caption Editing)*

> 📘 **For Future LLM Agents & Developers:** Refer to the master architecture and build guide:  
> 👉 **[`IMPLEMENTATION_ASSUMPTIONS_INSTRUCTIONS.md`](file:///c:/src/FileOrganizer/IMPLEMENTATION_ASSUMPTIONS_INSTRUCTIONS.md)**  
> 🎓 **Master Educational Guide & Deep Architecture (NotebookLM Ready):**  
> 👉 **[`COMPREHENSIVE_DEVELOPER_AND_ARCHITECTURE_GUIDE.md`](file:///c:/src/FileOrganizer/COMPREHENSIVE_DEVELOPER_AND_ARCHITECTURE_GUIDE.md)**  
> 📑 **System Explainer (What, Why, How & Backup Architecture):**  
> 👉 **[`APP_OVERVIEW_WHAT_HOW_WHY.md`](file:///c:/src/FileOrganizer/APP_OVERVIEW_WHAT_HOW_WHY.md)**

### How to Install on Your Android Phone:
1. Transfer `FileOrganizer_v1.4.apk` to your phone via USB cable, Google Drive, WhatsApp, or Bluetooth.
2. Tap the APK file on your phone and choose **Install** (or **Update** if updating from v1.3 — your data will NOT be lost).
3. Open the app or use Android's **Share** sheet to share any file, image, or document directly into your folder contacts!

---

## 🌟 Level 6 (v1.4) New Enhancements & Problem Solutions

### 1. 💬 Preserved Facebook Text Look & Feel
* Eliminates the single-line flattening bug when pasting copied posts from Facebook, browsers, or other apps.
* Standardizes all line break formats (`\r\n`, `\r`, `\u2028`, `\u2029` to `\n`) and renders text messages as conversational WhatsApp-style message bubbles with natural paragraph spacing (`height: 1.45`), emoji support, timestamps, and double blue checkmarks (`✓✓`), without clunky fake attachment cards.

### 2. 📁 Duplicate Folder Contact Fix
* Resolved the bug where creating a new folder contact while sharing a file caused two identical folders to appear in the list.
* Enforced singleton folder identity and eliminated redundant list insertions.

### 3. ✏️ Long-Press to Edit / Add Caption & Tags
* Long-press any file attachment or message bubble in any chathead to instantly open the **Edit / Add Caption** sheet.
* Modify captions, edit text notes, and update `#tags` with live global search synchronization and instant local storage persistence.

### 4. 📦 Multi-File Batch Sharing
* Selecting multiple files in Android Gallery, Files app, or via the in-app storage file picker now shares ALL files simultaneously into the chosen folder contact.
* Features a multi-file preview carousel, aggregate size badge, and atomic batch storage persistence.

---

## 🌟 Level 5 (v1.3) Features

### 1. 🏷️ Tagging & Custom Searchable Captions
* Every file share allows entering a custom caption and selecting `#tags` (`#work`, `#tax`, `#receipt`, `#invoice`, `#personal`, `#urgent`) or typing custom tags.
* Indexed by Central Search alongside file names and note contents.

### 2. 🔄 In-App "Check for Updates" via GitHub
* Connects to your personal GitHub repository releases (`api.github.com/repos/{owner}/{repo}/releases/latest`).
* Compares version tags, displays release notes, and offers direct APK download.
* Includes in-app interactive 5-step tutorial on uploading APKs to GitHub.

### 3. 🎨 Glassmorphic App Launcher Icon
* Modern teal-and-emerald glassmorphic folder icon deployed across all Android mipmap densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).

### 4. 📥 Google Drive Full Import ("Restore Everything")
* One-click restore button in the **Cloud & Backup** tab that traverses your Google Drive `FileOrganizer_Backup/` cloud folder and restores all folders, files, and notes to a new device.

### 5. 👤 Clear & Configurable Google Account Selection
* Displays the active Google Drive account email and badge.
* Includes an account switcher dialog to choose or enter the exact Google account to use for sync and backups.

### 6. 🗑️ Delete Chatheads & Contents
* Delete folder contacts directly from the 3-dots chat menu or by long-pressing on the home screen contact card.
* Option to delete local physical files from device storage as well.

### 7. 📂 Storage File Picker (Top Menu)
* Tap the top action bar upload icon to pick any file, photo, or document directly from device storage and sort it into a folder contact with captions and tags.

### 8. 📱 Android System App Chooser
* Uses native `Intent.createChooser` with `FileProvider` so opening a file presents all installed applications (Adobe Acrobat, Google Drive, Microsoft 365, VLC, Gallery, WPS Office) rather than defaulting to a single app.

---

## 🌐 Instant Interactive Web Prototype
Test all features in your PC browser:
👉 **`http://localhost:8080`**
