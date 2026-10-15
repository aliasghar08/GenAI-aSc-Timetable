# Security Policy — GenAI x aSc Timetable

Platform security, intellectual integrity, and data safety are fundamental to the **GenAI x aSc Timetable** platform. This document outlines our security architecture, supported versions, and vulnerability disclosure protocol.

---

## 1. Supported Versions

We actively provide security updates, vulnerability patches, and dependency audits for the following versions:

| Version | Supported | Notes |
| :--- | :--- | :--- |
| **1.0.x (Current)** | ✅ Yes | Production-ready Flutter Web release |
| **< 1.0.0** | ❌ No | Deprecated developmental prototypes |

---

## 2. Core Security Safeguards & Architecture

### 2.1 Gemini AI Key Safety & Execution Perimeter
- **Zero Hardcoded Secrets**: The client-side application does not store sensitive cloud credentials. Secrets and Gemini API keys are injected via compile-time Dart defines (`--dart-define=GEMINI_API_KEY=...`) or secure environment configurations.
- **Client-Side Deterministic Fallback**: Even without network connectivity or API keys, the autonomous CSP solver executes locally with mathematical guarantee against hallucinations or denial-of-service loops.

### 2.2 Cloud Firestore Security & Granular Rules
- **Rule Verification**: Read and write access to academic placements (`/schools/{schoolId}/placements/*`) must be guarded by Firebase Authentication rules in production.
- **Atomic State Transitions**: Schedule migrations and timetable updates are dispatched via atomic batched commits to eliminate partial updates or corruption.

### 2.3 Cryptographic Authorship Verification
- This codebase is cryptographically signed and fingerprinted against unauthorized republishing, plagiarism, or intellectual property infringement. Refer to [COPYRIGHT_CERTIFICATE.md](file:///Users/aliasghar08/development/GenAI%20Timetable%20Repo/COPYRIGHT_CERTIFICATE.md) and [scripts/verify_copyright.dart](file:///Users/aliasghar08/development/GenAI%20Timetable%20Repo/scripts/verify_copyright.dart).

---

## 3. Reporting a Vulnerability

If you discover a security vulnerability or credential leak within this repository, **do not open a public GitHub issue**.

Please report vulnerabilities directly to the author via email:

* **Security Contact**: Ali Asghar
* **Email**: [aliasgharinnocent@yahoo.com](mailto:aliasgharinnocent@yahoo.com)
* **GitHub Profile**: [@aliasghar08](https://github.com/aliasghar08)

Please include:
1. Description of the vulnerability and its potential impact.
2. Steps to reproduce or proof-of-concept code.
3. Any suggested mitigations.

You will receive an initial response within **48 hours**, followed by a timeline for remediation.
