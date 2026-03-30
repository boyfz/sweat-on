# SweatOn - Technical Interview Preparation Guide

---

## 1. Brief Overview (Elevator Pitch)

**SweatOn** is a mobile application built with **Flutter** and **Firebase** that allows users to **book sports venues** (football/futsal courts) and **create or join pickup games** with other players. It has two roles: **regular users** who book venues and organize games, and **admins** who manage venues and monitor platform activity. Think of it as a "Grab for sports bookings" - connecting players with available courts and teammates.

---

## 2. Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart 3.7.2+) |
| UI System | Material Design 3 |
| Auth | Firebase Authentication (Email/Password) |
| Database | Cloud Firestore (NoSQL) |
| File Storage | Firebase Storage |
| Maps | Google Maps Flutter + Geolocator |
| State Mgmt | Stateful Widgets + StreamBuilder (no external state lib) |
| Platform | Android, iOS, Web, macOS, Windows |

---

## 3. Architecture Diagram

```
+------------------------------------------------------------------+
|                        SweatOn Flutter App                        |
+------------------------------------------------------------------+
|                                                                    |
|   +-------------------+    +-------------------+                   |
|   |   LOGIN / REGISTER |    |   ADMIN PANEL     |                   |
|   +--------+----------+    +--------+----------+                   |
|            |                         |                              |
|            v                         v                              |
|   +--------+----------+    +--------+----------+                   |
|   | MainNavigation (5) |    | AdminNavigation(3)|                   |
|   |  Home | Book |     |    | Venues | Add |    |                   |
|   |  Join | Create |   |    | Monitor           |                   |
|   |  Profile           |    +-------------------+                   |
|   +--------------------+                                           |
|                                                                    |
+---------------------------+----------------------------------------+
                            |
                     Firebase SDK
                            |
          +-----------------+------------------+
          |                 |                   |
+---------v---+   +---------v----+   +---------v----+
| Firebase    |   | Cloud        |   | Firebase     |
| Auth        |   | Firestore    |   | Storage      |
| (users,     |   | (users,      |   | (venue imgs, |
|  sessions)  |   |  venues,     |   |  profile     |
|             |   |  bookings,   |   |  pictures)   |
+-------------+   |  teams)      |   +--------------+
                  +--------------+
```

---

## 4. Firestore Database Schema

```
Firestore (NoSQL)
│
├── users/                          # User profiles
│   ├── {uid}/
│   │   ├── fullName: String
│   │   ├── email: String
│   │   ├── phone: String           # Must start with "01"
│   │   ├── isAdmin: Boolean
│   │   ├── isDisabled: Boolean
│   │   ├── createdAt: Timestamp
│   │   └── bookings/               # Subcollection: joined games
│   │       └── {teamId}/
│   │           ├── teamId: String
│   │           ├── position: String
│   │           ├── joinedAt: Timestamp
│   │           └── teamData: Map    # Denormalized team snapshot
│
├── venues/                         # Sports venues
│   └── {venueId}/
│       ├── name: String
│       ├── address: String
│       ├── type: String             # "Futsal" | "Football"
│       ├── pricePerHour: Double
│       ├── imageUrl: String         # Firebase Storage URL
│       ├── location: GeoPoint       # lat/lng
│       ├── facilities: [String]     # ["Parking", "Toilet", "Changing Room"]
│       ├── openHour: Int            # default 8
│       ├── closeHour: Int           # default 22
│       ├── isVisible: Boolean
│       └── createdAt: Timestamp
│
├── bookings/                       # Venue bookings
│   └── {bookingId}/
│       ├── uid: String
│       ├── email: String
│       ├── venue: String
│       ├── venueAddress: String
│       ├── date: String             # ISO 8601
│       ├── startTime: String        # e.g., "2:00 PM"
│       ├── durationHours: Int
│       ├── pricePerHour: Double
│       ├── totalPrice: Double
│       └── createdAt: Timestamp
│
└── teams/                          # Created games/teams
    └── {teamId}/
        ├── createdBy: String        # uid
        ├── createdByName: String
        ├── phoneNumber: String
        ├── sport: String            # "Football" | "Futsal"
        ├── venueName: String
        ├── venueAddress: String
        ├── latitude: Double
        ├── longitude: Double
        ├── description: String
        ├── date: Timestamp
        ├── startTime: String
        ├── duration: Int
        ├── playersNeeded: Int
        ├── joined: Int              # Current count
        ├── joinedPlayers: [Map]     # [{uid, displayName, position, joinedAt}]
        ├── positions: Map           # {"Goalkeeper": 1, "Defender": 2, ...}
        └── createdAt: Timestamp
```

---

## 5. Application Flow Diagrams

### 5.1 Authentication Flow

```
App Launch
    │
    v
Firebase.initializeApp()
    │
    v
LoginPage
    │
    ├── [Login] ──> FirebaseAuth.signInWithEmailAndPassword()
    │                   │
    │                   ├── Check isDisabled ──> Block if true
    │                   │
    │                   ├── Check isAdmin == true ──> AdminMainNavigation
    │                   │
    │                   └── isAdmin == false ──> MainNavigation (User)
    │
    ├── [Register] ──> RegisterPage
    │                   │
    │                   ├── Validate fields (phone starts with "01")
    │                   ├── Check phone uniqueness in Firestore
    │                   ├── FirebaseAuth.createUserWithEmailAndPassword()
    │                   ├── Create Firestore user doc
    │                   └── Navigate back to LoginPage
    │
    └── [Forgot Password] ──> FirebaseAuth.sendPasswordResetEmail()
```

### 5.2 Venue Booking Flow

```
BookVenuePage (browse venues)
    │
    ├── Load venues where isVisible == true
    ├── Request location permission
    ├── Calculate distance to each venue
    ├── Search/filter venues
    │
    └── [Book] ──> BookingDetailsPage
                    │
                    ├── Step 1: Select Date (tomorrow to +30 days)
                    ├── Step 2: Select Duration (1-4 hours)
                    ├── Step 3: Select Start Time
                    │     └── Query existing bookings for that date
                    │         to filter out taken slots
                    │
                    └── [Proceed] ──> PaymentPage
                                       │
                                       ├── Show booking summary
                                       │
                                       └── [Pay] ──> MockCardPaymentPage
                                                      │
                                                      ├── Enter card details
                                                      ├── 2-sec processing delay
                                                      │
                                                      └── [Success] ──> Save to Firestore
                                                                         │
                                                                         └── BookingSuccessPage
```

### 5.3 Team Creation & Join Flow

```
CREATE TEAM:                           JOIN GAME:
CreateTeamPage                         JoinGamePage
    │                                      │
    └── CreateTeamFormPage                 ├── Load all teams from Firestore
        │                                  ├── Filter out past games
        ├── Select sport type              ├── Sort by distance, full games last
        ├── Set player count               ├── Search/filter
        ├── Pick date & time               │
        ├── Enter venue details            └── [View More] ──> JoinGameDetailsPage
        ├── Allocate positions                                     │
        │   (must match player count)                              ├── Show game details
        │                                                          ├── Select position (radio)
        └── Save to Firestore 'teams'                              ├── Check if already joined
            │                                                      │
            └── TeamSummaryPage                                    └── [Join] ──> Firestore Transaction
                                                                       ├── Update positions count
                                                                       ├── Increment joined count
                                                                       ├── Add to joinedPlayers array
                                                                       └── Store in user subcollection
```

### 5.4 Admin Flow

```
AdminMainNavigation
    │
    ├── Tab 1: AdminVenueListPage
    │   ├── List all venues
    │   ├── Toggle visibility (show/hide)
    │   ├── [Edit] ──> EditVenuePage
    │   └── [Delete] ──> Confirmation ──> Delete from Firestore + Storage
    │
    ├── Tab 2: AddVenuePage ──> AddVenueFormPage
    │   ├── Upload image to Firebase Storage
    │   ├── Enter venue details + GeoPoint
    │   └── Save to Firestore
    │
    └── Tab 3: AdminMonitoringPage
        ├── Bookings Tab: List all bookings (searchable)
        ├── Teams Tab: List all teams (searchable)
        └── Users Tab: List users + enable/disable accounts
```

---

## 6. File Structure

```
lib/
├── main.dart                              # Entry point, Firebase init, theme
├── firebase_options.dart                  # Firebase config (all platforms)
│
├── pages/
│   ├── login_page.dart                    # Auth: login, forgot password
│   ├── register_page.dart                 # Auth: registration with validation
│   ├── main_navigation.dart               # Bottom nav (5 tabs)
│   ├── home_page.dart                     # Dashboard with feature cards
│   ├── book_venue_page.dart               # Venue listing with location
│   ├── create_team_page.dart              # Team creation landing
│   ├── create_team_form_page.dart         # Team creation form
│   ├── team_summary_page.dart             # Team created confirmation
│   ├── change_password_page.dart          # Standalone password change
│   │
│   ├── booking_flow/
│   │   ├── booking_details_page.dart      # Date/time/duration selector
│   │   ├── payment_page.dart              # Payment confirmation
│   │   ├── mock_card_payment_page.dart    # Mock card form
│   │   └── booking_success_page.dart      # Booking confirmed screen
│   │
│   ├── join_flow/
│   │   ├── join_game_page.dart            # Browse available games
│   │   └── join_game_details_page.dart    # Game details + join action
│   │
│   └── profile/
│       ├── profile_page.dart              # Profile menu hub
│       ├── account_details_page.dart      # Edit phone
│       ├── edit_profile_page.dart         # Edit name/email/photo
│       ├── change_password_page.dart      # Password change
│       ├── booking_history_page.dart      # Booking list with status
│       ├── created_teams_page.dart        # User's created teams
│       └── joined_games_page.dart         # User's joined games
│
└── admin/
    ├── admin_main_navigation.dart         # Admin bottom nav (3 tabs)
    ├── admin_venue_list_page.dart          # Venue CRUD list
    ├── add_venue_page.dart                # Add venue landing
    ├── add_venue_form_page.dart           # Add venue form
    ├── edit_venue_page.dart               # Edit venue
    └── admin_monitoring_page.dart         # Monitor bookings/teams/users
```

---

## 7. Key Technical Decisions & Why

### Why Firebase (not custom backend)?
- **Real-time sync** via StreamBuilder + Firestore snapshots
- **Zero server management** - fully serverless
- **Built-in auth** - no need to implement JWT, sessions, etc.
- **Scales automatically** for a sports booking app's typical load
- **Fast prototyping** - ideal for a project of this scope

### Why Stateful Widgets (not Provider/Riverpod/Bloc)?
- App has relatively simple state (form inputs, lists, auth state)
- Each page manages its own state independently
- StreamBuilder handles real-time Firestore data reactively
- Reduces boilerplate and dependency complexity
- Trade-off: less scalable for very large apps, but sufficient here

### Why NoSQL (Firestore) over SQL?
- Flexible schema suits evolving feature set
- Nested data (joinedPlayers array, positions map) fits document model naturally
- Real-time listeners are first-class in Firestore
- Trade-off: denormalization (e.g., teamData stored in user subcollection) needed to avoid extra reads

### Data Denormalization Strategy
- `joinedPlayers` stored as array inside team document (avoids separate collection query)
- `teamData` duplicated into `users/{uid}/bookings` subcollection (avoids cross-collection join)
- `createdByName` stored alongside `createdBy` uid (avoids user lookup on team list)
- Trade-off: data can become stale if source changes, but acceptable for this use case

---

## 8. Key Features - Technical Deep Dive

### 8.1 Booking Slot Conflict Prevention
```
Location: lib/pages/booking_flow/booking_details_page.dart

How it works:
1. User selects a date and duration
2. App queries Firestore: bookings where venue == selected AND date == selected
3. For each existing booking, calculates the blocked time range
4. Generates available slots from openHour to closeHour
5. Removes any slot that would overlap with existing bookings
6. Only shows non-conflicting time slots to user
```

### 8.2 Location-Based Venue Sorting
```
Location: lib/pages/book_venue_page.dart

How it works:
1. Request location permission via Geolocator
2. Get user's current lat/lng
3. For each venue, calculate distance using Geolocator.distanceBetween()
4. Sort venues by distance (nearest first)
5. Display distance in km alongside each venue
```

### 8.3 Position-Based Team Joining
```
Location: lib/pages/join_flow/join_game_details_page.dart

How it works:
1. Team creator defines positions map: {"Goalkeeper": 1, "Defender": 3, ...}
2. When a player joins, they select a position
3. App checks remaining slots for that position
4. On join: decrements position count, increments joined count
5. Adds player data to joinedPlayers array
6. If joined == playersNeeded, game shows as "Full"
```

### 8.4 Admin User Disable/Enable
```
Location: lib/admin/admin_monitoring_page.dart + lib/pages/login_page.dart

How it works:
1. Admin toggles isDisabled field in user's Firestore document
2. On next login attempt, app checks isDisabled before granting access
3. If disabled, shows error and blocks login
4. Note: doesn't invalidate existing sessions (client-side check only)
```

### 8.5 Profile Image Upload
```
Location: lib/pages/profile/edit_profile_page.dart

How it works:
1. User picks image via ImagePicker
2. Image uploaded to Firebase Storage at: profile_pictures/{uid}.jpg
3. Download URL retrieved from Storage
4. URL saved to Firebase Auth user profile (photoURL)
5. Profile page displays image from photoURL
```

---

## 9. Security Considerations

| Area | Implementation | Notes |
|------|---------------|-------|
| Auth | Firebase Auth (email/password) | Handles hashing, tokens |
| Admin Access | `isAdmin` field in Firestore | Client-side routing only |
| Account Block | `isDisabled` field check on login | Existing sessions not revoked |
| Phone Validation | Must start with "01", uniqueness check | Malaysia format |
| Password | Min 6 chars, confirmation match | Firebase default |
| Payment | Mock only (not real) | No real card processing |
| Firestore Rules | Not visible in codebase | Should be configured server-side |

**Potential interview talking point:** The admin check is client-side. In production, Firestore Security Rules should enforce admin-only writes to venues/user-disable operations. Custom Claims via Firebase Admin SDK would be more secure than a Firestore field.

---

## 10. Possible Interview Questions & Answers

---

### General / Overview

**Q1: Can you give a brief overview of your project?**

> SweatOn is a Flutter mobile app for booking sports venues and organizing pickup football/futsal games. Users can browse nearby venues, book time slots, create teams specifying player positions needed, and join other people's games. There's also an admin panel for venue management and user monitoring. The backend is entirely Firebase - Firestore for data, Firebase Auth for authentication, and Firebase Storage for images.

**Q2: Why did you choose Flutter for this project?**

> Flutter allows cross-platform development from a single codebase - we can target Android, iOS, web, and desktop. It has excellent Firebase integration through official plugins, a rich widget library for building polished UIs quickly, and hot reload speeds up development significantly. The Dart language is also type-safe which helps catch errors at compile time.

**Q3: What was the most challenging part of this project?**

> The booking slot conflict prevention was the most technically interesting challenge. I needed to query existing bookings for the same venue and date, calculate which time slots overlap with existing bookings (considering variable durations), and only present available slots. Another challenge was the position-based team joining system where I had to ensure atomic updates to prevent race conditions when multiple players try to join the same position simultaneously.

---

### Firebase / Backend

**Q4: Why Firebase instead of a custom backend (Node.js, Django, etc.)?**

> Firebase provides real-time data sync, built-in authentication, file storage, and auto-scaling without server management. For a project of this scope, it dramatically reduced development time. Firestore's real-time listeners (used via StreamBuilder) give instant UI updates when data changes - for example, when a player joins a game, all viewers see the updated count immediately. The trade-off is less control over backend logic and potential vendor lock-in.

**Q5: Explain your Firestore data model. Why did you structure it this way?**

> I have 4 main collections: `users`, `venues`, `bookings`, and `teams`. I chose to denormalize data in several places - for example, storing `createdByName` in the team document alongside the `createdBy` uid, and duplicating team data into a user's subcollection when they join. This avoids expensive cross-collection joins that Firestore doesn't natively support. The trade-off is potential data staleness, but for this use case (game details rarely change after creation), it's acceptable.

**Q6: How do you handle real-time updates?**

> I use Firestore's `snapshots()` method combined with Flutter's `StreamBuilder` widget. When a Firestore document or query changes, the stream emits a new snapshot, and StreamBuilder automatically rebuilds the UI. For example, on the Join Game page, if a new team is created, it appears instantly for all users viewing that page. This is more efficient than polling because Firestore only sends deltas.

**Q7: What are the limitations of your current Firebase approach?**

> 1. **Security rules**: Admin access is checked client-side via an `isAdmin` field. In production, I'd use Firebase Custom Claims set via the Admin SDK.
> 2. **Atomic operations**: When a player joins a game, I update multiple fields. Ideally this should be a Firestore transaction or batch write to prevent race conditions.
> 3. **No server-side validation**: All validation is client-side. A malicious user could bypass it. Cloud Functions should validate writes.
> 4. **Cost at scale**: Firestore charges per read/write. The current approach of loading all venues/teams could become expensive. Pagination and caching would be needed.

---

### State Management

**Q8: Why didn't you use Provider, Riverpod, or Bloc for state management?**

> The app's state is mostly page-local (form inputs, search queries, selected filters) or comes directly from Firestore streams. Each page independently manages its own state via `setState()`, and real-time data flows through `StreamBuilder`. For this app's complexity level, introducing a state management library would add boilerplate without significant benefit. If the app grew to have shared state across many screens (e.g., a shopping cart, global settings), I'd consider Provider or Riverpod.

**Q9: How does data flow through your app?**

> There are two main data flows:
> 1. **User input -> Firestore**: User fills a form, validation runs locally, data is written to Firestore (e.g., creating a booking).
> 2. **Firestore -> UI**: StreamBuilder listens to Firestore queries and automatically rebuilds widgets when data changes (e.g., venue list, booking history).
>
> Navigation passes data between pages via constructor parameters. For example, when a user taps "Book" on a venue, the venue data object is passed to the BookingDetailsPage constructor.

---

### UI / Flutter Specifics

**Q10: How is navigation structured in your app?**

> The app uses a `NavigationBar` (Material 3 bottom nav) as the main navigation structure. Regular users get 5 tabs (Home, Book, Join, Create, Profile), while admins get 3 tabs (Venues, Add, Monitor). Within each tab, I use `Navigator.push()` for forward navigation and `Navigator.pop()` for back. After critical flows (like successful booking), I use `Navigator.pushAndRemoveUntil()` to clear the stack and prevent back-navigation to the payment page.

**Q11: How do you handle form validation?**

> I use Flutter's built-in form validation. Each `TextFormField` has a `validator` function that checks constraints (e.g., phone must start with "01", password must be 6+ chars, card number must be 16 digits). The form is wrapped in a `Form` widget with a `GlobalKey<FormState>`, and I call `formKey.currentState!.validate()` before submission. Additional async validation (like phone uniqueness) is done via a Firestore query before form submission.

**Q12: What UI patterns do you use?**

> - Card-based layouts for listing items (venues, bookings, teams)
> - Bottom sheets for selection dialogs
> - Stepper-like flow for bookings (date -> duration -> time)
> - Filter chips/tabs for categorization (Upcoming/Past/All)
> - Search bars with real-time filtering on already-loaded data
> - Loading animations while data is being fetched
> - Confirmation dialogs before destructive actions (delete, join)
> - Staggered animations for list items appearing on screen

---

### Location & Maps

**Q13: How do you implement location-based features?**

> I use two packages: `geolocator` for getting the user's position and calculating distances, and `url_launcher` to open Google Maps for directions. When the venue list loads, I request location permission, get the user's coordinates, then use `Geolocator.distanceBetween()` to compute the distance from the user to each venue's stored GeoPoint. Venues are then sorted by proximity. The "View Map" button constructs a Google Maps URL with the venue's coordinates and opens it via `launchUrl()`.

---

### Security

**Q14: How do you handle authentication and authorization?**

> Authentication uses Firebase Auth with email/password. On login, the app checks two things in the user's Firestore document: (1) `isDisabled` - blocks access if true, and (2) `isAdmin` - routes to admin or user interface. Password reset uses Firebase's built-in email flow. For password changes, I re-authenticate the user first using `reauthenticateWithCredential()` before updating.
>
> **Honest limitation**: Authorization is primarily client-side. The `isAdmin` check only controls UI routing. In production, Firestore Security Rules should enforce that only admins can write to the `venues` collection or toggle `isDisabled` on users.

**Q15: What would you improve for production security?**

> 1. Use Firebase Custom Claims for admin role (set via Admin SDK, verified server-side)
> 2. Implement Firestore Security Rules to restrict reads/writes per role
> 3. Add Cloud Functions for server-side validation of bookings and joins
> 4. Use Firestore transactions for atomic operations (joining a game)
> 5. Add rate limiting to prevent abuse
> 6. Implement real payment gateway (Stripe, etc.) instead of mock
> 7. Revoke sessions when admin disables an account (currently only blocks new logins)

---

### Scalability & Improvements

**Q16: How would you scale this app?**

> 1. **Pagination**: Replace loading all documents with paginated queries using `startAfterDocument()` for large datasets
> 2. **Caching**: Use Firestore's offline persistence (already built-in) and consider caching venue images
> 3. **Indexing**: Create composite Firestore indexes for complex queries (venue + date + time)
> 4. **Cloud Functions**: Move validation and business logic server-side
> 5. **Push Notifications**: Use FCM to notify users when someone joins their game or a booking is confirmed
> 6. **State Management**: Adopt Riverpod or Bloc if shared state becomes complex
> 7. **Search**: Use Algolia or Typesense for full-text search instead of client-side filtering

**Q17: What features would you add next?**

> 1. **Real payment integration** (Stripe/payment gateway)
> 2. **Push notifications** (game full, booking reminder)
> 3. **Chat system** between team members
> 4. **Rating/review system** for venues
> 5. **Recurring bookings** for regular games
> 6. **Social features** (friends list, invite to game)
> 7. **Analytics dashboard** for venue owners

---

### Code Quality

**Q18: How do you handle errors in the app?**

> Firebase operations are wrapped in try-catch blocks. For auth errors, I catch specific `FirebaseAuthException` codes (e.g., `wrong-password`, `user-not-found`) and show user-friendly messages via SnackBars. For Firestore operations, generic error SnackBars are shown. Network errors are handled implicitly by Firestore's offline persistence - the SDK queues writes and syncs when connectivity resumes.

**Q19: What testing approach did you use?**

> The project includes a basic `test/` directory with the default Flutter widget test. In a production scenario, I would implement:
> - **Unit tests**: For validation logic (phone format, booking conflict detection)
> - **Widget tests**: For form validation behavior, navigation flows
> - **Integration tests**: For end-to-end booking flow with Firebase emulators
> - **Mock Firebase**: Using `fake_cloud_firestore` and `firebase_auth_mocks` packages

**Q20: If you could rewrite this project, what would you change?**

> 1. **Separate data layer**: Create repository classes to abstract Firestore calls instead of calling Firestore directly from widgets
> 2. **Model classes**: Create proper Dart data classes with fromJson/toJson for type safety instead of working with raw Maps
> 3. **State management**: Use Riverpod for dependency injection and testability
> 4. **Modular architecture**: Organize by feature (auth/, booking/, team/) rather than by type (pages/, admin/)
> 5. **Firestore transactions**: Use transactions for all multi-step writes (joining games)
> 6. **Environment configs**: Separate Firebase projects for dev/staging/prod

---

### Behavioral / Soft Questions

**Q21: How did you plan and organize this project?**

> I broke the app into core modules: Authentication, Venue Management, Booking Flow, Team System, and Admin Panel. I started with Firebase setup and auth, then built the venue booking flow (the core feature), followed by team creation/joining, and finally the admin panel. Each module was developed and tested independently before integration.

**Q22: What did you learn from building this project?**

> 1. How to design NoSQL data models with denormalization trade-offs
> 2. Real-time data synchronization patterns with StreamBuilder
> 3. Location services and permission handling on mobile
> 4. Multi-step form flows with state management across pages
> 5. Role-based access control patterns (even if simplified)
> 6. The importance of thinking about edge cases (booking conflicts, full games, disabled accounts)

---

## 11. Quick Reference: Key Code Patterns

### Firestore Read (Real-time)
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('venues')
      .where('isVisible', isEqualTo: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    final docs = snapshot.data!.docs;
    // Build UI from docs
  },
)
```

### Firestore Write
```dart
await FirebaseFirestore.instance.collection('bookings').add({
  'uid': user.uid,
  'venue': venueName,
  'date': selectedDate.toIso8601String(),
  'totalPrice': price * duration,
  'createdAt': FieldValue.serverTimestamp(),
});
```

### Firebase Auth
```dart
// Login
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email, password: password,
);

// Register
final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email, password: password,
);
```

### Location Distance
```dart
double distance = Geolocator.distanceBetween(
  userLat, userLng, venueLat, venueLng,
);
String formatted = (distance / 1000).toStringAsFixed(1) + " km";
```

---

## 12. Glossary

| Term | Meaning in SweatOn |
|------|-------------------|
| Venue | A football/futsal court available for booking |
| Team | A game organized by a user looking for players |
| Join | A player signing up for someone else's team/game |
| Position | Player role (Goalkeeper, Defender, etc.) |
| Duration | Booking length in hours (1-4 for venues, 1-6 for teams) |
| Facilities | Venue amenities (Parking, Toilet, Changing Room) |
| GeoPoint | Firestore type storing latitude/longitude |
| isVisible | Admin toggle to show/hide venue from users |
| isDisabled | Admin toggle to block user account |
| Mock Payment | Simulated card payment (not real processing) |
