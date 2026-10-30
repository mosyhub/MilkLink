# TCHMB Mobile Application (Flutter)
### Taguig City Human Milk Bank — Donors & Mothers App

A cross-platform Flutter mobile application designed specifically for **Mothers and Breast Milk Donors** of the **Taguig City Human Milk Bank (TCHMB)**.

---

## 📱 Features

1. **Mother & Donor Authentication**:
   - Register account (`first name`, `last name`, `email`, `phone`, `password`).
   - Sign in with JWT authentication (communicates with the backend with `x-client-type: mobile` header).
   - Password reset request.
   - Persistent session caching with `shared_preferences`.

2. **Donor Medical Screening & Application**:
   - Multi-step questionnaire for donor qualification (Mother's address/category, Infant details, and health lifestyle history).
   - Instant submission to the TCHMB backend eligibility pipeline.

3. **Donation Tracker & History**:
   - View cumulative donated volume (mL).
   - Track verified donation sessions and dates.
   - Live eligibility status badge (`ELIGIBLE`, `PENDING`, `VERIFIED`).

4. **Milk Letting Events & Schedules**:
   - View upcoming Taguig milk letting activities, venues, and timings.
   - Event reminders and details.

5. **Educational Resources & Announcements**:
   - Read breast milk storage guides and nutritional health articles.
   - In-app notices and bank announcements.

6. **Notification Center**:
   - Status updates on donor applications and upcoming events.
   - Mark as read / dismiss notifications.

---

## 🏗️ Architecture & Project Structure

```text
Mobile/
├── lib/
│   ├── main.dart                          # App entry point & MultiProvider configuration
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart         # Base URL & API endpoints
│   │   │   └── app_colors.dart            # TCHMB brand colors & palette
│   │   ├── network/
│   │   │   └── api_client.dart            # HTTP client with mobile headers & auth injection
│   │   └── utils/
│   │       └── session_manager.dart       # JWT token & user persistence
│   ├── models/
│   │   ├── user_model.dart                # User schema model
│   │   ├── donor_model.dart               # Donor profile, address, child & donation records
│   │   ├── letting_event_model.dart       # Milk letting event details & venue
│   │   ├── article_model.dart             # Articles & announcements
│   │   └── notification_model.dart        # User notification model
│   ├── providers/
│   │   ├── auth_provider.dart             # Authentication state management
│   │   ├── donor_provider.dart            # Donor profile & screening form state
│   │   ├── events_provider.dart           # Milk letting events state
│   │   ├── articles_provider.dart         # Guides & announcements state
│   │   └── notifications_provider.dart    # User notifications state
│   ├── screens/
│   │   ├── splash_screen.dart             # Animated splash & session check
│   │   ├── auth/                          # Login, Register, Forgot Password
│   │   ├── main_navigation_screen.dart    # 5-tab persistent bottom bar
│   │   ├── home/                          # Dashboard, stats, CTA & upcoming events
│   │   ├── donor/                         # 3-step screening form & donation history
│   │   ├── events/                        # Letting calendar & event detail views
│   │   ├── articles/                      # Articles & announcements feeds
│   │   ├── notifications/                 # Notifications inbox
│   │   └── profile/                       # User profile, server settings, sign out
│   └── widgets/                           # Reusable buttons, inputs, cards & badges
├── android/                               # Native Android configuration (permissions & gradle)
└── pubspec.yaml                           # Flutter dependencies
```

---

## 🚀 How to Run the App

### 1. Start the TCHMB Backend
In your terminal, navigate to `Backend/` and start the server:
```bash
cd "c:\Users\mosy\Desktop\TCHMB\Source Codes\Backend"
npm run dev
# Server will run on http://localhost:4000
```

### 2. Configure the API Host
- **Android Emulator**: Uses `http://10.0.2.2:4000/api/v1` automatically.
- **Physical Phone**: Tap the ⚙️ **Settings icon** on the top right of the Login screen (or inside **Profile > Server Connection URL**) and enter your computer's local Wi-Fi IP address:
  ```text
  http://192.168.1.X:4000/api/v1
  ```

### 3. Run Flutter
In your terminal:
```bash
cd "c:\Users\mosy\Desktop\TCHMB\Source Codes\Mobile"
flutter pub get
flutter run
```
Or open the `Mobile/` folder in VS Code or Android Studio, select your emulator/device, and press **F5** (Run).

