# 💸 MUKHLA - Kharche Pai Charcha

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)

**A modern expense-splitting app for college students built with Flutter & Firebase**

</div>

---

## 🎯 About

MUKHLA helps college students track and split expenses with friends in real-time. Built with Flutter for cross-platform support and Firebase for instant synchronization.

---

## ✨ Key Features

- 🔐 **Google Authentication** - Quick sign-in
- 👥 **Group Management** - Create unlimited groups
- 💰 **4 Split Types** - Equal, Exact, Percentage, Shares
- 🎯 **Smart Settlements** - Minimizes transactions
- ⚡ **Real-time Sync** - Instant updates across devices
- 📱 **WhatsApp Export** - Share settlement summaries
- 🎨 **Modern UI** - Material 3 design

---

## 🛠️ Tech Stack

- **Flutter** - Cross-platform framework
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Real-time database
- **Provider** - State management

---

## 🚀 Quick Start

```bash
# Clone repo
git clone https://github.com/yourusername/mukhla-splitw.git

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Firebase Setup

1. Create project at [Firebase Console](https://console.firebase.google.com)
2. Add Android app: `com.mukhla.splitw`
3. Download `google-services.json` → place in `android/app/`
4. Enable Authentication (Google, Email, Phone)
5. Create Firestore Database (test mode)
6. Update `lib/firebase_options.dart` with your config

---

## 📁 Structure

```
lib/
├── main.dart
├── services/          # Auth & Firestore logic
├── models/            # Data models
└── screens/           # UI screens
    ├── auth/          # Login & profile
    ├── home/          # Dashboard
    ├── friends/       # Friend management
    ├── groups/        # Group operations
    └── expenses/      # Expense tracking
```

---

## 🎮 Usage

1. **Sign in** with Google
2. **Add friends** by searching names
3. **Create group** with custom icon
4. **Add expense** with flexible split options
5. **Settle up** with smart algorithm
6. **Export** to WhatsApp

---

## 💡 Perfect For

🍕 Food orders • 🎬 Movie tickets • 🚗 Cab shares • 🏠 Hostel expenses • ✈️ Trip planning • 🎉 Parties

---

## 📊 Roadmap

**v1.0** (Current): Core features  
**v2.0** (Planned): Push notifications, bill photos, recurring expenses  
**v3.0** (Future): AI categorization, UPI integration, insights

---

## 👨‍💻 Developer

**Shreya Jaiswal** - AI Automation Engineer  
Building production-ready apps with Flutter & Firebase

---

## 📝 License

MIT License - Free to use and modify

---

<div align="center">

**Made with 💜 for College Students**

⭐ Star this repo if you find it useful!

</div>