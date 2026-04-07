# Voice Alarm Reminder

A premium, reliable Flutter application that allows users to record custom voice reminders as alarm sounds. Designed with a focus on high-fidelity audio and robust background execution on modern Android devices.

![App Icon](assets/icon/app_icon.png)

## 🌟 Features

- **Custom Voice Library**: Record, save, and manage your own voice reminders.
- **Reliable Scheduling**: Uses Android's Exact Alarm API to ensure pinpoint timing.
- **Aggressive Wake-up**: Screen-on and Lock-screen bypassing logic for high-priority alerts.
- **Elegant UI**: Minimalist Material 3 design with "Outfit" typography and curated color palettes.
- **Automatic Setup**: Seamless permission handling for Notifications, Battery Optimization, and Overlays.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.11.0+)
- Android Studio / VS Code
- Physical Android device (recommended for testing background alarms)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### 🔑 Permissions
To ensure the alarm fires correctly every time, the app will request:
1. **Notifications**: To show alerts.
2. **Appear on Top (Overlay)**: Crucial for showing the alarm screen over other apps.
3. **Exact Alarms**: Required for Android 12+ to prevent OS-level timing delays.
4. **Ignore Battery Optimization**: Prevents the system from "killing" the alarm service while the phone is idle.

## 🛠️ Technical Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Audio Handling**: [record](https://pub.dev/packages/record) & [audioplayers](https://pub.dev/packages/audioplayers)
- **Native Bridge**: Custom MethodChannel implementation in Kotlin for Android System Integration.

---
*Built with ❤️ for a better morning routine.*
