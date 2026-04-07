# Technical Overview: Voice Alarm Reminder

A deep-dive into the architectural decisions, technical challenges, and research-led solutions implemented in the Voice Alarm Project.

## 🏗 Architecture & State Management

The app follows a **Layered Architecture** to ensure separation of concerns and maintainability:

1.  **UI Layer (Flutter)**: Material 3 screens and widgets utilizing the **Bloc Pattern**.
2.  **Logic Layer (Blocs)**: 
    - `AlarmBloc`: Handles scheduling, saving, and deleting alarms.
    - `RecorderBloc`: Manages the real-time recording session.
    - `RecordingBloc`: CRUD operations for the saved voice library.
3.  **Data Layer (Repositories)**: Abstracts data sources (SQFlite for databases and local file system for audio files).
4.  **Service Layer (Singletons)**: `NotificationService` and `AudioService` (playback) provide a clean API for interacting with system-level resources.

### Why Singletons?
I implemented the **Singleton Pattern** for core services to ensure data consistency and prevent resource conflicts. A key example is the `AudioService`: by sharing a single audio player across the entire app, we ensure that if multiple alarms trigger at once, the most recent one gracefully takes over the audio focus instead of creating a chaotic overlap of voices.

### Why Bloc?
I chose `flutter_bloc` for state management to ensure that UI updates are predictable and reactive. For an alarm app, where the state (Active/Inactive) is critical and changes based on external triggers, a robust state machine is essential.

## 🔬 Research & Problem Solving

### The "Android Wake-up" Challenge
One of the most significant challenges was ensuring the alarm could reliably "wake up" the device and show the ringing screen—even when locked—on **Android 12, 13, and 14**.

**My Research & Solution**:
1.  **Exact Timing**: I implemented `USE_EXACT_ALARM` after researching Android's power-saving restrictions. This ensures the OS doesn't "delay" the alarm to save battery.
2.  **Full Screen Intent**: By leveraging `USE_FULL_SCREEN_INTENT`, the app can launch its own activity directly from a high-priority notification.
3.  **Overlay Permission**: I researched the `SYSTEM_ALERT_WINDOW` permission to allow the alarm screen to bypass lock screens and appear on top of other applications.
4.  **Battery Optimization**: Implemented logic to request the user to exclude the app from battery optimization, preventing the OS from hibernating the background alarm listeners.

### The MethodChannel Bridge
Since Flutter is a cross-platform framework, it doesn't have direct access to some deep Android system flags like `FLAG_SHOW_WHEN_LOCKED` or `FLAG_DISMISS_KEYGUARD`. 

**My Solution**:
I wrote custom **Kotlin** bridge code in `MainActivity.kt` to:
- Dynamically set window flags that allow the Activity to wake the screen.
- Dismiss the system keyguard automatically.
- Ensure the app wins the focus "race" when multiple system alerts are triggering.

## 📚 Resources & Documentation Referenced

To build this project, I performed extensive research across:
- **Android Developer Documentation**: Task scheduling, power management, and permission models.
- **Flutter Local Notifications Plugin**: Source code analysis for `fullScreenIntent` and custom notification channels.
- **Material 3 Design Guidelines**: Implementation of color seeds and custom font integration (Outfit).

## 🚀 Future Roadmap

- **Cloud Sync**: Future integration with Firebase for cross-device backup of voice recordings.
- **AI Integration**: Analyzing voice recordings to detect mood or ensure clarity during playback.

---
*Developed by a developer who believes in the power of voice and personal touch.*
