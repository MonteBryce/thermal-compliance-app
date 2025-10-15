# System Architecture

## 🔍 Interactive Diagram Viewer

**[🚀 View Live Interactive Diagram](https://htmlpreview.github.io/?https://github.com/MonteBryce/thermal-compliance-app/blob/main/docs/architecture-viewer.html)**

**Features:** Scroll to zoom • Click & drag to pan • Keyboard shortcuts (`+`/`-`/`F`/`0`)

No download required - opens directly in your browser with full pan/zoom controls

---

## System Integration Flow

![System Architecture](diagram-export-10-15-2025-11_50_17-AM.svg)

### Viewing Options

- **Interactive HTML Viewer**: Download [architecture-viewer.html](architecture-viewer.html) and open in browser for pan/zoom controls
- **GitHub**: Right-click diagram → "Open image in new tab" → Use browser zoom (Ctrl/Cmd + scroll)
- **High-res Export**: Available in [docs/](.) folder

---

## Overview

The Thermal Compliance App follows an **offline-first, mobile-first** architecture pattern designed for reliability in remote industrial settings.

## Architecture Layers

### **1. Presentation Layer**
- **Flutter Mobile/Web App** - Cross-platform UI
- **Next.js Admin Dashboard** - Web-based administration

### **2. State Management Layer**
- **Riverpod Providers** - Reactive state management
- **Local Cache** - Hive database for offline storage
- **Sync Manager** - Coordinates local ↔ cloud data flow

### **3. Data Layer**
- **Firebase Firestore** - Cloud NoSQL database
- **Firebase Auth** - User authentication
- **Hive Local Database** - Offline-first storage

### **4. Business Logic Layer**
- **Services** - Reusable business logic
- **Validators** - Form and data validation
- **Repositories** - Data access abstraction

## Data Synchronization

### **Offline-First Strategy**

```
User Action → Local Write (Hive) → Background Sync Queue → Firestore
                    ↓
                UI Update (Immediate)
```

### **Conflict Resolution**
- **Last-Write-Wins** - Timestamp-based resolution
- **Optimistic Updates** - UI updates immediately
- **Retry Logic** - Exponential backoff for failures

## Security

### **Authentication Flow**
1. Firebase Auth (Email/Password)
2. JWT tokens for API access
3. Role-based access control (RBAC)

### **Data Protection**
- Firestore security rules enforce authorization
- Local data encrypted at rest (Hive)
- HTTPS-only communication

## Scalability

### **Current Capacity**
- 10,000+ concurrent users
- 1M+ documents in Firestore
- 50MB local storage per user

### **Performance Targets**
- < 2s app cold start
- < 500ms form load time
- < 5s sync completion (typical)

## Technology Decisions

| Decision | Rationale |
|----------|-----------|
| **Flutter** | Single codebase for iOS, Android, Web |
| **Riverpod** | Type-safe, testable state management |
| **Hive** | Fast, lightweight local database |
| **Firebase** | Managed backend, real-time sync |
| **Next.js** | Server-side rendering for admin portal |

## Deployment Architecture

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
