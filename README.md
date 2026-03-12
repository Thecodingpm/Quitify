# 🚭 Quitify — Your Calm Quit-Smoking Companion

A beautifully designed Flutter app that helps users quit smoking with science-backed tools, streak tracking, and real-time progress visualization.

## ✨ Features

### 🏠 Dashboard
- **Smoke-free timer** — Track days, hours, and streaks since your quit date
- **Cigarette jar** — Visual jar that fills up with every cigarette avoided
- **Money tree** — Watch your savings grow into a blooming tree
- **Lung recovery** — Animated breathing visualization showing healing progress
- **Impact stats** — Cigarettes avoided, money saved, life regained, cravings beaten
- **Achievements** — Milestone badges for 1 day, 7 days, 30 days, 90 days, 1 year

### 🆘 Craving SOS Toolkit
- **5-minute countdown** — Ride out cravings with a guided timer
- **Box breathing** — Animated 4-4-6 breathwork guide
- **Coping tips** — Quick actionable strategies
- **Mini game** — Tap-to-smash distraction game

### 📊 Analytics
- Visual charts powered by `fl_chart`
- Track craving patterns, streak history, and savings over time

### 💎 Premium
- AI quit coach chatbot
- Advanced analytics & craving prediction
- Deep breathing meditation library
- Personalized quit plans & health recovery timeline
- Custom motivation reminders
- Ad-free experience

### 🔐 Authentication
- Email/password sign-up & sign-in
- Google Sign-In
- Apple Sign-In (iOS)
- Password reset

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart) |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Backend** | Firebase (Auth, Firestore, FCM, Analytics) |
| **In-App Purchases** | `in_app_purchase` |
| **Charts** | `fl_chart` |
| **Fonts** | Google Fonts |
| **Auth Providers** | Google Sign-In, Sign in with Apple |

## 📁 Project Structure

```
lib/
├── core/
│   ├── router/          # GoRouter configuration
│   ├── services/        # FCM, Analytics, Premium services
│   └── theme/           # App-wide theming (colors, typography)
├── features/
│   ├── auth/            # Authentication (repository, presentation)
│   ├── onboarding/      # 4-step onboarding flow
│   ├── dashboard/       # Main dashboard with stats & craving SOS
│   ├── premium/         # Subscription paywall & controller
│   └── analytics/       # Charts & usage analytics
├── firebase_options.dart
└── main.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Xcode (for iOS)
- Android Studio (for Android)
- Firebase project with Auth, Firestore, FCM enabled

### Setup
```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/Quitify.git
cd Quitify

# Install dependencies
flutter pub get

# Configure Firebase (you'll need your own Firebase project)
flutterfire configure

# Run on iOS
cd ios && pod install && cd ..
flutter run
```

### Firebase Configuration
This project requires:
1. **Firebase Auth** — Enable Email/Password, Google, and Apple providers
2. **Cloud Firestore** — For user profiles and progress data
3. **Firebase Messaging** — For push notifications
4. **Firebase Analytics** — For usage tracking

> ⚠️ Firebase credential files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are excluded from version control for security. You must generate your own.

## 🧪 Testing Premium

Use promo code **`QUITIFY2026`** in the Premium screen to activate premium features for testing.

## 📄 License

This project is proprietary. All rights reserved.

---

Built with 💚 using Flutter
