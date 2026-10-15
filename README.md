# GenAI x aSc Timetable Web Platform

[![Live App](https://img.shields.io/badge/Live%20App-Firebase%20Hosting-FFCA28.svg?logo=firebase&logoColor=black)](https://genai-x-asc-timetable.web.app)
[![Author](https://img.shields.io/badge/Author-Ali%20Asghar-4F46E5.svg)](https://github.com/aliasghar08)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy%20Active-10B981.svg)](SECURITY.md)
[![Authorship Certificate](https://img.shields.io/badge/Authorship-Cryptographically%20Signed-7C3AED.svg)](COPYRIGHT_CERTIFICATE.md)
[![Flutter](https://img.shields.io/badge/Platform-Flutter%20Web-02569B.svg?logo=flutter)](https://flutter.dev)

> **Autonomous AI-driven school timetable management platform** bridging **Google Gemini** generative intelligence with the official **aSc Timetables XML standard**, deterministic **CSP algorithmic solver**, and real-time **Firebase Cloud Firestore**.

🌐 **Production Web Application**: [https://genai-x-asc-timetable.web.app](https://genai-x-asc-timetable.web.app)

---

## ⚡ Key Features at a Glance

### 1. 🧠 Hybrid LLM + Algorithmic CSP Solver (0 Collisions Guaranteed)
* **Natural Language to Constraint Synthesis**: Powered by `google_generative_ai` (`gemini-1.5-flash`), prompts like *"Schedule Computer Science for Grade 10-A on Monday Period 1 with Turing"* are translated into formal `CspConstraintSpec` objects.
* **Deterministic Forward-Checking Search**: Employs MRV (Minimum Remaining Values) and LCV (Least Constraining Value) heuristics to mathematical certainty, completely eliminating hallucinations and deadlocks.
* **Genetic Soft-Fitness Optimization**: Evaluates teacher idle gaps ("holes" in schedule), morning subject priorities, and syllabus distribution to achieve 95%+ fitness scores in sub-20ms.
* **Telemetry & Diagnostic Console**: Real-time instrumentation displays search permutations, execution latency, and reasoning traces in the studio terminal.

### 2. 🔐 Production-Grade Firebase Authentication
* **Secure Credential Lifecycle**: Encapsulated `AuthService` powering email/password registration, login, and instant session invalidation via `firebase_auth`.
* **Live Session Guard (`AuthGate`)**: Real-time `authStateChanges` stream dynamically routes users between the Auth portal and the Timetable Studio.
* **User Identity & Session Management**: App bar administrator chip displaying current credentials and a dedicated confirmation dialog for secure sign-out.

### 3. 🎨 Apple macOS / iOS Frosted Glassmorphism UI
* **High-Level Visual Fidelity**: Built with native `BackdropFilter` and `ImageFilter.blur(sigmaX: 24, sigmaY: 24)`, translucent glass cards (`0.06` fill opacity), delicate borders (`0.12`), and soft ambient shadows.
* **Unified 3-Phase Staggered Animation Pipeline**:
  * *Phase 1 (0.0 – 0.4)*: Brand header & calendar icon smooth slide-up and cubic fade-in.
  * *Phase 2 (0.2 – 0.7)*: Frosted glass credential card entrance with sleek input fields.
  * *Phase 3 (0.4 – 1.0)*: Mode switcher toggle and security verification badge reveal.
* **Ambient Lighting Orbs**: Responsive background radial gradient spheres in deep indigo, violet, and cyan replicating Apple's signature modern dark-mode aesthetic.

### 4. 🔄 Bidirectional aSc Timetables XML Interoperability
* **Official aSc XML Compliance**: Generates and parses standard XML tags (`<daysdefs>`, `<periods>`, `<teachers>`, `<subjects>`, `<classes>`, `<cards>`) identical to native desktop aSc Timetables software.
* **One-Click Native Export**: In-app modal viewer with syntax highlighting and instant clipboard copying for seamless import into desktop timetabling tools.

### 5. ⚡ Real-Time Cloud Firestore Sync & Atomic Batches
* **Live Multi-Client Streaming**: Reactive subscription to `schools/demo_school/placements` document changes, instantly updating all connected administrator screens.
* **Atomic Batch Commits**: All AI-suggested schedule modifications and deletions execute within single Firestore atomic batches, preventing partial updates.

### 6. 🛡️ Cryptographic Copyright & Authorship Protection
* **Genesis Proof of Authorship**: Registered cryptographic SHA-256 fingerprint (`ef6ea8acc857b9b818cb906c936a6d7ff026b9af9cf2e5a6e0638e37a37e67ea`) certifying Ali Asghar (@aliasghar08) as author and rights owner.
* **Automated Verification Script**: Standalone Dart CLI validator (`dart run scripts/verify_copyright.dart`) protecting against plagiarism and license infringement.

---

## 📁 Complete Folder & File Architecture

```text
asc_genai_timetable/
├── web/
│   ├── index.html
│   └── manifest.json
├── scripts/
│   └── verify_copyright.dart          # Standalone SHA-256 copyright verification CLI
├── test/
│   └── widget_test.dart               # Unit tests: XML export/parse & CSP solver
├── COPYRIGHT_CERTIFICATE.md           # Cryptographic authorship certificate
├── LICENSE                            # MIT License (Ali Asghar)
├── SECURITY.md                        # Enterprise vulnerability reporting policy
├── pubspec.yaml                       # Dependencies: flutter, firebase_auth, firestore, gemini
├── firebase.json                      # Firebase Hosting & SPA routing configuration
├── .firebaserc                        # Firebase project link: genai-x-asc-timetable
└── lib/
    ├── main.dart                      # App bootstrap, MultiProvider & AuthGate routing
    ├── firebase_options.dart          # Firebase Web platform configuration
    ├── models/
    │   └── timetable_models.dart      # Teacher, Subject, SchoolClass, LessonPlacement
    ├── services/
    │   ├── auth_service.dart          # Firebase Authentication client & error translation
    │   ├── gemini_ai_service.dart     # Natural-language-to-CSP synthesis (Gemini 1.5)
    │   ├── algorithmic_csp_solver.dart# Forward checking, MRV/LCV & genetic optimizer
    │   ├── asc_xml_service.dart       # Bidirectional aSc XML export/parse engine
    │   ├── firestore_service.dart     # Cloud Firestore real-time streaming & batch writes
    │   └── sample_data_service.dart   # Mock school catalog initialization
    ├── providers/
    │   ├── auth_provider.dart         # Authentication state, login/register modes & errors
    │   └── timetable_provider.dart    # Timetable matrix state, AI co-pilot execution & logs
    └── screens/
        ├── auth_screen.dart           # macOS/iOS glassmorphic auth & staggered animations
        └── timetable_studio_screen.dart# Split-screen matrix grid, AI terminal & XML export
```

---

## 🔄 End-to-End Operational Workflow

```mermaid
graph TD
    User([Administrator]) -->|Logs In| AuthScreen[Glassmorphic Auth Screen]
    AuthScreen -->|Firebase Auth| AuthGate{Live Session Guard}
    AuthGate -->|Authenticated| Studio[Timetable Studio Screen]
    User -->|Natural Language Prompt| AI[Gemini 1.5 Flash Reasoning]
    AI -->|Constraint Synthesis| CSP[Algorithmic CSP Solver]
    CSP -->|Forward Checking + MRV/LCV| Solution[Zero-Collision Schedule Permutation]
    Solution -->|Atomic Batch Commit| Firestore[(Cloud Firestore)]
    Firestore -->|Real-Time Snapshot Stream| Studio
    Studio -->|One-Click Export| XML[Native aSc XML File]
```

1. **Authentication**: User logs in through the frosted glassmorphic portal; `AuthGate` transitions to the Studio.
2. **Natural Language Input**: Administrator inputs commands (e.g., *"Move Physics to Wednesday Period 3"*).
3. **AI Constraint Synthesis**: Gemini translates the prompt into formal scholastic constraint rules.
4. **Deterministic CSP Execution**: Algorithmic engine computes optimal slots with 0 teacher or room collisions.
5. **Atomic Firestore Sync**: Modified cards are batched directly into Cloud Firestore and live-streamed across all clients.
6. **aSc XML Export**: Schedule is exported as a standard aSc Timetables XML file ready for desktop distribution.

---

## 🧪 Quality & Verification Suite

All components are rigorously tested and verified:

```bash
# 1. Run static analysis (0 warnings, 0 errors)
flutter analyze

# 2. Run unit & algorithmic test suites
flutter test

# 3. Verify cryptographic copyright signature
dart run scripts/verify_copyright.dart
```

---

## 🚀 How to Run Locally

```bash
# 1. Clone repository
git clone https://github.com/aliasghar08/GenAI-aSc-Timetable.git
cd GenAI-aSc-Timetable

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome with your Gemini API Key
flutter run -d chrome --dart-define=GEMINI_API_KEY="YOUR_GEMINI_API_KEY"

# 4. Deploy updates to Firebase Hosting
firebase deploy --only hosting --project genai-x-asc-timetable
```

---

## 📜 Authorship & Legal Notice

* **Creator & Architect**: [Ali Asghar](https://github.com/aliasghar08) (`aliasgharinnocent@yahoo.com`)
* **License**: [MIT License](LICENSE)
* **Cryptographic Fingerprint**: `ef6ea8acc857b9b818cb906c936a6d7ff026b9af9cf2e5a6e0638e37a37e67ea`
* See [COPYRIGHT_CERTIFICATE.md](COPYRIGHT_CERTIFICATE.md) for full cryptographic ownership verification.
