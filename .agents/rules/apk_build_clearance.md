# Rule: User Clearance Required Before Building APKs

For all chats and tasks in the FileOrganizer project:
- **NEVER** run `flutter build apk` or generate an APK file automatically or prematurely before the user checks and verifies the code.
- Always implement the requested updates, run `flutter analyze` and unit tests to ensure stability, and present the changes clearly to the user.
- Only compile a new `.apk` release package when the user explicitly requests or gives clear clearance to build it.
