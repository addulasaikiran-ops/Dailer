# OpenDialer

<div align="center">

<img src="assets/icons/logo.svg" alt="OpenDialer logo" width="96" />

**A clean, modern, open-source Android dialer**  
Inspired by the OPPO O Dialer UX • Built with Flutter • MIT Licensed

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue?logo=flutter)](https://flutter.dev)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9%2B-orange?logo=kotlin)](https://kotlinlang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Android](https://img.shields.io/badge/Android-8.0%2B-brightgreen?logo=android)](https://developer.android.com)

</div>

---

## ✨ Features

| Feature | Status |
|---|---|
| 🔢 Smart Dialpad (T9 search, haptic feedback) | ✅ |
| 📞 Incoming Call Screen (swipe to answer/reject) | ✅ |
| 📲 Active Call (mute, speaker, hold, keypad) | ✅ |
| 🕐 Call History (missed / incoming / outgoing, grouped) | ✅ |
| 👥 Contacts (alphabetical, favorites, search) | ✅ |
| 📼 Voicemail Inbox (play/pause/delete) | ✅ |
| 🎙️ Call Recording (manual + auto, saved locally) | ✅ |
| 🌙 Dark / Light / System theme | ✅ |
| 📶 Dual SIM selector | ✅ |
| 🚫 Spam blocking | ✅ |
| ⚙️ Full Settings screen | ✅ |
| 🏠 Default Dialer request flow | ✅ |

---

## 🏗️ Architecture

```
OpenDialer/
├── lib/
│   ├── main.dart                    # Entry point, routing (GoRouter)
│   ├── core/
│   │   ├── database/                # SQLite via sqflite
│   │   │   └── app_database.dart
│   │   ├── models/                  # Data models
│   │   │   └── models.dart          # CallLog, Contact, Voicemail, Recording
│   │   └── services/
│   │       ├── settings_service.dart    # SharedPreferences + Riverpod
│   │       ├── telecom_service.dart     # Android Telecom MethodChannel
│   │       └── recording_service.dart  # Call recording via record package
│   ├── features/
│   │   ├── dialpad/                 # Dial pad + T9 search
│   │   ├── call_history/            # Call log list
│   │   ├── contacts/                # Device contacts integration
│   │   ├── voicemail/               # Voicemail inbox
│   │   ├── settings/                # App settings
│   │   ├── incoming_call/           # Incoming call UI
│   │   └── active_call/             # In-call UI
│   └── shared/
│       ├── theme/                   # AppTheme, AppColors
│       ├── widgets/                 # ContactAvatar, etc.
│       └── screens/                 # DefaultDialerRequestScreen
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── java/com/opendialer/
│           ├── MainActivity.kt              # MethodChannel + EventChannel bridge
│           ├── connection/
│           │   ├── OpenDialerConnection.kt          # Telecom Connection
│           │   ├── OpenDialerConnectionService.kt   # ConnectionService
│           │   └── ConnectionManager.kt             # Singleton bridge
│           ├── service/
│           │   └── OpenInCallService.kt     # InCallService
│           └── receiver/
│               └── CallReceiver.kt          # Broadcast receiver
└── pubspec.yaml
```

**Pattern:** MVVM + Clean Architecture  
**State:** Riverpod (StateNotifier + Provider + StreamProvider)  
**Navigation:** GoRouter (StatefulShellRoute for bottom tabs)  
**Database:** sqflite (SQLite)

---

## 🚀 Getting Started

### Prerequisites

- Flutter **3.10+** (`flutter --version`)
- Android Studio or VS Code with Flutter plugin
- Android device / emulator with **API 26+** (Android 8.0 Oreo)

### 1. Clone

```bash
git clone https://github.com/your-org/open-dialer.git
cd open-dialer
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run

```bash
flutter run --release   # or debug
```

### 4. Set as Default Dialer

On first launch, OpenDialer will prompt you to become the default dialer.  
You can also go to **Settings → Apps → Default apps → Phone app → OpenDialer**.

---

## 📱 Android Telecom Integration

OpenDialer uses two complementary Android APIs:

### ConnectionService (for SIM-based calls)
`OpenDialerConnectionService` handles outgoing and incoming SIM calls.  
Registered in `AndroidManifest.xml` with `BIND_TELECOM_CONNECTION_SERVICE`.

### InCallService (for all calls managed by Telecom)
`OpenInCallService` receives call events from Android's Telecom framework when calls are managed centrally. Registered with `IN_CALL_SERVICE_UI = true`.

### Flutter ↔ Native Bridge

| Direction | Mechanism | Purpose |
|---|---|---|
| Flutter → Native | `MethodChannel` | Make call, answer, hang up, mute, speaker |
| Native → Flutter | `EventChannel` | Call state events (incoming, answered, ended) |

---

## 🎙️ Call Recording

Call recording is **opt-in** and disabled by default.

- Enable in **Settings → Call Recording**
- Recordings are saved to `External Storage / OpenDialer / Recordings /`
- Each file: `recording_<timestamp>.m4a`
- View recordings in **Settings → Recordings folder**

> ⚠️ **Legal notice:** Call recording laws vary by country and region.  
> Always comply with local consent requirements. OpenDialer does not  
> display a visible recording indicator to the remote party — **it is your  
> responsibility to inform the other party if required by law.**

---

## 🎨 Design System

| Token | Light | Dark |
|---|---|---|
| Primary | `#3D7BFF` | `#6B9FFF` |
| Accent | `#00D4AA` | `#00D4AA` |
| Surface | `#F8F9FF` | `#0D0F1A` |
| Card | `#FFFFFF` | `#161829` |
| Missed | `#FF4D6D` | `#FF4D6D` |
| Answered | `#06D6A0` | `#06D6A0` |

**Font:** Nunito (weights 400–800)  
**Corner radius:** 14–32px depending on component  
**Animations:** flutter_animate for entry / micro-interactions

---

## 🔒 Permissions

| Permission | Why |
|---|---|
| `READ_PHONE_STATE` | Detect call state |
| `CALL_PHONE` | Place outgoing calls |
| `READ_CALL_LOG` / `WRITE_CALL_LOG` | Read and store call history |
| `MANAGE_OWN_CALLS` | Use ConnectionService |
| `READ_CONTACTS` / `WRITE_CONTACTS` | Show contact names |
| `RECORD_AUDIO` | Call recording (optional) |
| `POST_NOTIFICATIONS` | Incoming call notifications |

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit with conventional commits: `feat:`, `fix:`, `docs:`
4. Open a pull request

All contributions are welcome — bug fixes, new features, translations, or design improvements.

---

## 📄 License

```
MIT License

Copyright (c) 2025 OpenDialer Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">
Built with ❤️ using Flutter · Open Source · MIT
</div>
