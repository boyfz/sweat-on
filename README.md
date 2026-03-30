# SweatOn

A sports venue booking and team management platform built with Flutter and Firebase.

## Features

### User
- **Venue Booking** — Browse, search, and book sports venues with a multi-step booking flow (details → payment → confirmation)
- **Team Creation** — Create teams for Football/Futsal with customizable positions (Goalkeeper, Defender, Midfielder, Forward), date/time, and player count
- **Join Games** — Discover and join existing games
- **Profile Management** — Edit profile, view booking history, created teams, and joined games
- **Location-Based Discovery** — Find nearby venues using geolocation and Google Maps

### Admin
- **Venue Management** — Add, edit, and manage venue listings
- **Monitoring Dashboard** — Track teams, bookings, and user activity in real time

## Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Maps:** Google Maps Flutter
- **Location:** Geolocator
- **Platforms:** iOS, Android, Web, macOS, Windows, Linux

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── admin/                    # Admin panel (venues, monitoring)
└── pages/
    ├── login_page.dart
    ├── register_page.dart
    ├── home_page.dart
    ├── book_venue_page.dart
    ├── create_team_page.dart
    ├── booking_flow/         # Booking details → payment → success
    ├── join_flow/            # Join game discovery and details
    └── profile/              # Profile, history, settings
```

## Getting Started

### Prerequisites
- Flutter SDK (^3.7.2)
- Firebase project configured

### Setup

```bash
# Clone the repo
git clone https://github.com/<your-username>/sweat-on.git
cd SweatOn

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase

This project uses Firebase. Ensure your `firebase_options.dart` is configured for your Firebase project. See the [FlutterFire docs](https://firebase.flutter.dev/docs/overview) for setup instructions.

## Design

- Material Design 3 with custom purple brand color (`#4B39EF`)
- Urbanist font family
- Loading animations and staggered list transitions
