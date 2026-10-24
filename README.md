# 📁 File Organizer (WhatsApp-Style Folder Contacts)

> Bypassing the friction of navigating nested Google Drive sub-folders by visually styling folders as conversational WhatsApp contacts.

---

## 📱 Android Releases (Ready to Install)

The newest compiled Android release package is ready in the workspace root:
- 👉 **[`FileOrganizer_v1.3.apk`](file:///p:/Other%20computers/My%20Computer%20(2)/Raisul%20DESCO%20HR/Programming/Mobile%20App/FileOrganizer/FileOrganizer_v1.3.apk)** *(51.5 MB — Release APK with Real Physical File Vault & Google Drive Save)*

> 📘 **For Future LLM Agents & Developers:** Refer to the master architecture and build guide:  
> 👉 **[`IMPLEMENTATION_ASSUMPTIONS_INSTRUCTIONS.md`](file:///p:/Other%20computers/My%20Computer%20(2)/Raisul%20DESCO%20HR/Programming/Mobile%20App/FileOrganizer/IMPLEMENTATION_ASSUMPTIONS_INSTRUCTIONS.md)**  
> 🎓 **Master Educational Guide & Deep Architecture (NotebookLM Ready):**  
> 👉 **[`COMPREHENSIVE_DEVELOPER_AND_ARCHITECTURE_GUIDE.md`](file:///p:/Other%20computers/My%20Computer%20(2)/Raisul%20DESCO%20HR/Programming/Mobile%20App/FileOrganizer/COMPREHENSIVE_DEVELOPER_AND_ARCHITECTURE_GUIDE.md)**  
> 📑 **System Explainer (What, Why, How & Backup Architecture):**  
> 👉 **[`APP_OVERVIEW_WHAT_HOW_WHY.md`](file:///p:/Other%20computers/My%20Computer%20(2)/Raisul%20DESCO%20HR/Programming/Mobile%20App/FileOrganizer/APP_OVERVIEW_WHAT_HOW_WHY.md)**

### How to Install on Your Android Phone:
1. Transfer `FileOrganizer_v1.3.apk` to your phone via USB cable, Google Drive, WhatsApp, or Bluetooth.
2. Tap the APK file on your phone and choose **Install** (or **Update** if updating from v1.2 — your data will NOT be lost).
3. Open the app or use Android's **Share** sheet to share any file, image, or document directly into your folder contacts!

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
