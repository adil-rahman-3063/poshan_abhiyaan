# Poshan Abhiyaan — Nutrition & Maternal Health App

A role‑based Flutter application that supports India’s **Poshan Abhiyaan** mission by connecting **Admins**, **ASHA workers**, and **Beneficiaries (Users)** for nutrition awareness, pregnancy tracking, event scheduling, and secure communication.

> **Tech**: Flutter (Android, iOS, Web, Desktop targets supported), Google Sheets & Drive integrations

---

## Table of Contents
- [Overview](#overview)
- [Core Features](#core-features)
- [Role-Based Functionality](#role-based-functionality)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Getting Started](#getting-started)
- [Configuring Google APIs (Securely)](#configuring-google-apis-securely)
- [Running & Building](#running--building)
- [Environment & Secrets](#environment--secrets)
- [Security Notes](#security-notes)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

The app streamlines community nutrition services by enabling:
- **Admins** to manage ASHA workers, broadcast notifications, and review feedback.
- **ASHA workers** to manage beneficiaries, track pregnancies, schedule visits/events, and chat.
- **Users** to track pregnancy milestones, receive program notifications, chat with ASHA workers, and view local calendars.

This repository contains the Flutter frontend. Google integrations are abstracted in `/lib/services/`.

---

## Core Features

- **Authentication**: Login and role‑specific registration (ASHA/User).
- **Dashboards**: Dedicated homepages per role.
- **Pregnancy Tracking**: Milestones, visits, and notes.
- **Event Calendar**: Health camps, checkups, outreach events.
- **Chat**: User ↔ ASHA secure messaging (front-end scaffolding).
- **Notifications**: System and admin broadcasts.
- **Feedback Loop**: Collect feedback from users and workers.
- **Google Integrations**: Drive/Sheets services for reports, logs, or data sync (configurable).

---

## Role-Based Functionality

### Admin
- Verify & manage ASHA workers
- Send announcements/notifications
- View feedback & maintain profile

### ASHA Worker
- Manage assigned beneficiaries
- Track pregnant users
- Maintain schedule (calendar)
- Receive notifications; update profile & settings

### User (Beneficiary)
- Pregnancy tracker & notes
- Events/appointments calendar
- Chat with assigned ASHA worker
- Receive notifications; submit feedback; profile & settings

---

## Architecture

**Flutter UI** → **Services layer** (Google Drive/Sheets) → **Google Cloud APIs**  
Add your own secure backend if needed (recommended for production).

```
+---------------------+
|     Flutter UI      |
|  (Admin/ASHA/User)  |
+----------+----------+
           |
           v
+---------------------+
|     Services        |
|  google_drive_*.dart|
|  google_sheets_*.dart
+----------+----------+
           |
           v
+---------------------+
|  Google APIs (OAuth |
|  / Service Account) |
+---------------------+
```

---

## Folder Structure

```
lib/
├─ admin/
│  ├─ edit_asha_workers.dart
│  ├─ feedback.dart
│  ├─ notification.dart
│  ├─ profile.dart
│  └─ verify_asha.dart
├─ asha/
│  ├─ calendar.dart
│  ├─ manage_user.dart
│  ├─ notification.dart
│  ├─ pregnant.dart
│  ├─ profile.dart
│  └─ settings.dart
├─ homepage/
│  ├─ admin_homepage.dart
│  ├─ asha_homepage.dart
│  └─ user_homepage.dart
├─ services/
│  ├─ google_drive_service.dart
│  └─ google_sheets_service.dart
├─ user/
│  ├─ about.dart
│  ├─ calendar.dart
│  ├─ chat.dart
│  ├─ feedback.dart
│  ├─ notification.dart
│  ├─ pregnancy_tracker.dart
│  ├─ profile.dart
│  └─ settings.dart
├─ asha_register_page.dart
├─ login_page.dart
├─ main.dart
└─ user_register_page.dart
```

> **Note**: File names reflect the latest structure shared by the author. Update this section if you add/rename modules.

---

## Getting Started

### Prerequisites
- Flutter SDK installed (`flutter --version`)
- Dart SDK (bundled with Flutter)
- Android Studio/Xcode for emulators or physical devices
- A Google Cloud project if you plan to enable Drive/Sheets

### Installation
```bash
git clone <this-repo-url>
cd poshan_abhiyaan
flutter pub get
```

### Run
```bash
flutter run
# or target a specific device:
flutter run -d chrome
flutter run -d android
```

---

## Configuring Google APIs (Securely)

You have two secure options. **Avoid bundling service_account.json inside the app** (assets/apk).

### Option A — Backend Proxy (Recommended)
1. Host a small backend (Cloud Run, Firebase Functions, Supabase Edge, etc.).
2. Backend holds the **service account** and talks to Google APIs.
3. Flutter app calls your backend endpoints (no Google keys in the client).

### Option B — OAuth (Per-User Access)
- Use Google Sign-In and OAuth scopes for Drive/Sheets.
- No service account file in the app; tokens are issued per user.

> If you **must** use a service account for automation, store its JSON **server-side only** and never commit it to Git. If previously committed, revoke the key in Google Cloud, rotate credentials, and purge from git history.

---

## Running & Building

### Debug
```bash
flutter run
```

### Build APK / AppBundle
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

> Configure signing, icons, and splash screens per platform as needed.

---

## Environment & Secrets

- Do **not** commit secrets. Add entries to `.gitignore`:
```
# Secrets
*.secret.json
assets/service_account.json
.env
```
- If you accidentally committed `service_account.json` in the past, rotate the key and remove it from history using **git filter-repo** or **BFG Repo Cleaner**.

**Quick BFG example:**
```bash
# Install BFG (requires Java)
# Remove the file from all commits:
bfg --delete-files service_account.json

# Then clean and force push
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin --force
```

---

## Security Notes

- **Never** hardcode API keys.
- Keep Google Service Account keys **server-side**.
- Limit OAuth scopes & use least privilege.
- Use HTTPS everywhere and validate backend TLS.
- Consider end‑to‑end encryption for chat in future versions.
- Plan for **offline-first** with secure local storage if needed.

---

## Roadmap

- Push notifications (FCM or equivalent)
- Offline sync for low connectivity areas
- Multi-language support (English/Hindi/regional)
- Analytics dashboard for Admins (charts & insights)
- AI‑assisted nutrition guidance
- Role-based access control hardening
- Media uploads for visit reports

---

## Contributing

1. Fork the repo & create a branch: `feat/my-change`
2. Commit with clear messages: `git commit -m "feat: add ASHA calendar filters"`
3. Ensure `flutter analyze` passes and code is formatted: `flutter format .`
4. Open a Pull Request describing your change and test scope.

---

## Troubleshooting

**CRLF warnings on Windows**
```
warning: LF will be replaced by CRLF
```
Set consistent line endings:
```bash
git config core.autocrlf true   # Windows
```

**Rebase/Pull conflicts**
```bash
git pull --rebase origin main
# resolve conflicts, then:
git add <files>
git rebase --continue
```

**Clean build cache**
```bash
flutter clean && flutter pub get
```

---

## License

This project is released under the **MIT License** (or choose another). See `LICENSE` for details.
