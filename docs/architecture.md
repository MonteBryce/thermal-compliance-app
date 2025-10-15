# System Architecture

# Architecture Overview
The Thermal Compliance App is an enterprise-grade, offline-first system for industrial environmental compliance. It uses a modular monolith style, with clear separation between mobile/web client (Flutter), admin dashboard (Next.js), and Firebase backend (Auth, Firestore, Functions, Storage).

## High-Level Diagram
![System Architecture](diagram-export-10-15-2025-11_50_17-AM.svg)
*For interactive pan/zoom, see [architecture-viewer.html](architecture-viewer.html).*

## Code Map / Components
- **lib/**: Main Flutter app code
  - `main.dart`: App entry point
  - `screens/`: UI pages
  - `services/`: Business logic, sync, validation
  - `models/`, `types/`, `schemas/`: Data structures
  - `providers/`: State management (Riverpod)
  - `firestore/`, `auth/`, `cache/`: Data access layers
  - `widgets/`: Reusable UI components
- **admin-dashboard/**: Next.js admin portal
  - `src/app/`: Main app logic
  - `firebase-admin.ts`, `firebase.ts`: Firebase integration
- **test/**: Unit and widget tests
- **integration_test/**: End-to-end and emulator tests
- **assets/**: Data and images for charts, logs, etc.
- **docs/**: Architecture diagrams and documentation

## Technology Stack
- **Languages**: Dart (Flutter), TypeScript (Next.js)
- **Frameworks**: Flutter, Next.js, Riverpod
- **Backend/Infra**: Firebase (Auth, Firestore, Functions, Storage)
- **Local Storage**: Hive (Flutter)
- **CI/CD**: GitHub Actions, Firebase Emulator Suite

## Design Decisions
- **Offline-first**: Hive local DB, background sync, conflict resolution
- **Single codebase**: Flutter for all operator platforms
- **Admin separation**: Next.js for advanced admin features
- **Managed backend**: Firebase for scalability and security
- **State management**: Riverpod for testability and modularity

## Getting Started for Developers
1. **Clone the repo**  
    `git clone https://github.com/MonteBryce/thermal-compliance-app.git`
2. **Install dependencies**  
    - Flutter: `flutter pub get`
    - Admin: `cd admin-dashboard && npm install`
3. **Run locally**  
    - Flutter: `flutter run`
    - Admin: `npm run dev`
    - Firebase Emulator: `firebase emulators:start`
4. **Test**  
    - Flutter: `flutter test`
    - Admin: `npm test`
    - Integration: See `integration_test/` scripts

## Cross-Cutting Concerns
- **Testing**: Unit (`test/`), integration (`integration_test/`)
- **Error Handling**: Centralized in services and middleware
- **Logging**: Local logs, Firestore logs, audit trails
- **Security**: Firestore rules, JWT, RBAC, encrypted local storage
- **Performance**: Sync batching, lazy loading, optimized queries

## References
- [README.md](../README.md)
- [SETUP_INSTRUCTIONS.md](../SETUP_INSTRUCTIONS.md)
- [WIREFRAME_project_summary.md](../WIREFRAME_project_summary.md)
- [docs/architecture-viewer.html](architecture-viewer.html)
- [Firebase Emulator Integration Test](../integration_test/firebase_emulator_integration_test.dart)

```
┌──────────────────────────────────────────┐
│         Firebase Hosting (CDN)           │
├──────────────────────────────────────────┤
│  Flutter Web App    │  Next.js Dashboard │
└──────────────────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────┐
│          Firebase Services               │
├──────────────────────────────────────────┤
│  Firestore  │  Auth  │  Storage  │ Rules│
└──────────────────────────────────────────┘
```

## Future Enhancements

- **Cloud Functions** - Background processing
- **Cloud Storage** - Image uploads
- **Analytics** - User behavior tracking
- **CDN** - Global content delivery
