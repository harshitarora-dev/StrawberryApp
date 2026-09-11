<div align="center">

<img src="strawberry/assets/images/logo.png" alt="Strawberry App Logo" width="130"/>

# 🍓 Strawberry — Preschool & Daycare ERP
### Full-Stack School Management System, Parent Portal & Public Web Platform

**An end-to-end digital ecosystem custom-engineered for Strawberry Preschool & Daycare, replacing paper-based administration with automated workflows, real-time analytics, and seamless parent engagement.**

[![Live Web Platform](https://img.shields.io/badge/Live%20Platform-strawberrydaycare.co.in-E94464?style=for-the-badge&logo=google-chrome&logoColor=white)](https://strawberrydaycare.co.in/)
[![Android App](https://img.shields.io/badge/Android%20App-Testing%20Phase-34A853?style=for-the-badge&logo=google-play&logoColor=white)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Deployed on Vercel](https://img.shields.io/badge/Deployment-Vercel%20PWA-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://vercel.com)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%26%20Storage-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)

<br/>

### 🌐 Platform Status & Access
- 🌐 **Live Web Application**: **[https://strawberrydaycare.co.in/](https://strawberrydaycare.co.in/)**
- 📱 **Android Mobile App**: Currently in **Internal Testing Phase** and will be launched live on the **Google Play Store** very soon! 🚀

</div>

---

## 📌 Executive Summary & Case Study

Before this platform, **Strawberry Preschool & Daycare** (Sector 85, Faridabad) relied heavily on traditional manual workflows: physical paper attendance registers, manual fee collection receipts, unorganized WhatsApp broadcasts, and phone-based parent inquiries.

**Strawberry ERP** was designed and engineered from the ground up as a modern, unified cloud solution that seamlessly connects three key stakeholders:
1. **Prospective Parents & Public Visitors** — Discover school programs, explore safety standards & campus facilities, and initiate one-click admissions.
2. **Enrolled Parents & Students** — Monitor real-time attendance trends, view category fee breakdowns, make instant UPI payments, and receive school notices.
3. **School Administrators & Faculty** — Handle multi-program student records, mark daily attendance in seconds, collect and track fees, manage holiday calendars, and export audited reports.

---

## 🌟 Core System Modules & Architecture

```
                                  ┌───────────────────────────────┐
                                  │      🍓 Strawberry ERP        │
                                  │  (Unified Flutter Codebase)   │
                                  └───────────────┬───────────────┘
                                                  │
                ┌─────────────────────────────────┼─────────────────────────────────┐
                │                                 │                                 │
                ▼                                 ▼                                 ▼
   🌐 Public Showcase & CMS            👨‍👩‍👧 Parent & Student App         🧑‍💼 Admin Management Suite
  • Programs & Admissions Flow        • GitHub-style Attendance Heatmap • 1-Student Multi-Category Engine
  • Interactive Campus & Safety Tour  • Flexible Fee Breakdown & UPI    • 1-Tap Attendance & Excel Export
  • In-App Dynamic "About" Editor     • Instant Receipt Download        • Custom Fee Heads & Ledger
  • SEO & Social Preview Engine       • Notice Board & Media Gallery    • Role-Based Access Control (RBAC)
  • One-Tap WhatsApp & Call Inquiries • Direct Admin In-App Chat        • Holiday & Academic Calendar
```

---

## 🚀 Key Feature Showcase

### 1. 💳 Intelligent Fee Management & Online UPI Payments
- **Dynamic Fee Heads**: Administrators can configure customized fee structures (Tuition Fee, Daycare Fee, Transport, Admission Fee, Annual Charges, etc.) for each student or category.
- **Instant Online Payments**: Integrated UPI payments supporting direct app intent (Google Pay, PhonePe, Paytm, BHIM) and dynamic on-screen QR codes.
- **Automated Balance Tracking**: Real-time calculation of paid amounts, outstanding balances, and overdue accounts.
- **Digital Receipts & Ledger**: Automatic transaction logging with printable and downloadable payment receipts for parents.

### 2. 🏷️ 1-Student Multi-Category Engine
- Solves a major real-world daycare challenge: **one child enrolled across multiple programs** (e.g., *Nursery Morning Batch* + *Extended Daycare* + *Transport*).
- System handles multi-category tagging with independent attendance records, category-specific fee schedules, and tailored analytics per program.

### 3. 📅 Attendance Analytics & Excel Reporting
- **GitHub-style Activity Heatmap**: Visual day-by-day attendance grid allowing parents to see their child's consistency at a glance.
- **Bulk Attendance Marking**: Admins can mark an entire class as Present, Absent, or Holiday with a single tap.
- **One-Click Excel Export**: Instantly exports audited monthly attendance rosters into formatted `.xlsx` spreadsheets for administrative archiving and reporting.

### 4. 🖼️ Smart Gallery & WhatsApp Social Sharing Proxy
- **Vercel Serverless Image Proxy (`/photo/:file`)**: WhatsApp requires thumbnail previews to be strictly under 300KB. A custom serverless Node.js proxy formats Supabase images on-the-fly, generating rich OpenGraph cards when photos are shared.
- **Optimized Media Pipeline**: High-resolution image capture with automatic client-side compression (`flutter_image_compress`) to minimize bandwidth consumption.

### 5. 🏫 Dynamic "About School" CMS
- Public-facing showcase presenting the school's philosophy, age-specific programs (Playgroup, Pre-Nursery, Nursery, Kindergarten, Daycare), and campus infrastructure.
- **Live In-App Editor**: Primary administrators can update school images, announcements, emergency contacts, and program descriptions without needing a code redeploy.
- **Local SEO & Rich Snippets**: Equipped with Schema.org JSON-LD structured data for ChildCare & Preschool, local geo-tags (`IN-HR`, Faridabad), OpenGraph meta cards, and search engine sitemaps.

### 6. 🔒 Enterprise Security & Multi-Tier RBAC
- **Multi-Role Administration**: Clear separation of responsibilities between **Primary Admins** (full financial control, fee head modification, admin management) and **Operational Staff Admins** (attendance marking, notices, chat).
- **Secure Authentication**: Firebase Authentication with single-tab redirect flow optimized for mobile web browsers, eliminating popup blocking issues.

---

## 🛠️ Technology Stack & Engineering Highlights

| Domain | Technologies | Engineering Highlights |
|---|---|---|
| **Frontend & UI** | **Flutter Web, Android & iOS** (Dart 3.x) | Single responsive codebase adapting across mobile phones, tablets, and wide desktop screens using custom layout breakpoints. |
| **Backend & Database** | **Supabase** (PostgreSQL) | Real-time listeners, relational schema for student categories & fee heads, and cloud bucket storage for event media. |
| **Authentication & Messaging** | **Firebase Auth & FCM** | OAuth Google Sign-In with browser session management, combined with cloud push notifications for real-time alerts. |
| **Edge & Serverless** | **Vercel Serverless Functions** (Node.js) | Dynamic OpenGraph metadata generator and image optimization proxy for social media sharing. |
| **Payments Integration** | **UPI Intent & Dynamic QR Engine** | Frictionless checkout supporting all major Indian UPI applications. |
| **Data Processing** | **`excel` engine & `flutter_image_compress`** | Client-side spreadsheet generation and on-device image optimization. |
| **Web Architecture & SEO** | **PWA + Schema.org JSON-LD** | Local business rich snippets for Google search, robots.txt, and automated CI/CD via `vercel-build.sh`. |

---

## 📂 System Architecture & Modules

```
strawberry/
├── api/
│   └── photo.js                   # Serverless OpenGraph proxy for WhatsApp previews
├── assets/images/                 # Brand identity, campus assets & vector illustrations
├── lib/
│   ├── main.dart                  # Application initialization & routing engine
│   ├── core/
│   │   ├── firebase_config.dart   # Firebase credentials & service binding
│   │   ├── supabase_config.dart   # PostgreSQL client connection & storage hooks
│   │   ├── upi_config.dart        # Payment gateway & merchant parameters
│   │   ├── theme/                 # Design tokens, typography & playschool palettes
│   │   ├── utils/
│   │   │   ├── responsive.dart             # Responsive web & mobile layout utilities
│   │   │   ├── student_category_utils.dart # Multi-category student management engine
│   │   │   └── image_utils.dart            # Compression & asset handling utilities
│   │   └── widgets/               # Reusable UI primitives, cards & student avatars
│   └── features/
│       ├── about/                 # Public school showcase, virtual tour & dynamic CMS
│       ├── auth/                  # Authentication, role verification & onboarding flow
│       ├── chat/                  # In-app real-time messaging between parents and school
│       ├── payments/              # Fee structures, dynamic UPI payment & receipts engine
│       ├── splash/                # Animated brand splash & state-based routing
│       └── dashboard/
│           ├── admin/             # Admin operations (attendance, fee ledger, gallery,
│           │                      # holidays, analytics, multi-admin management)
│           └── student/           # Parent portal (attendance heatmap, fee payments,
│                                  # payment receipts, notices & event gallery)
├── web/                           # PWA manifests, SEO metadata & favicon sets
├── vercel.json                    # Edge routing, SPA rewrites & security headers
└── vercel-build.sh                # Automated Vercel build script for Flutter Web
```

---

## 📈 Impact & Client Value Delivered

- ⏱️ **90% Reduction in Administrative Overhead**: Attendance marking and report generation that previously took 30+ minutes daily is now completed in under 2 minutes.
- 💵 **100% Digital Fee Tracking**: Eliminated manual paper receipts; every transaction is accounted for with instant payment confirmation and transparent digital ledgers.
- 📱 **Enhanced Parent Trust & Engagement**: Parents receive instant updates, transparent attendance heatmaps, and a direct communication channel to the administration.
- 🌐 **Strong Digital Presence**: The live portal at **[strawberrydaycare.co.in](https://strawberrydaycare.co.in/)** ranks for local preschool searches in Sector 85, Faridabad, driving new student admissions.

---

## 👨‍💻 Engineering & Development

Designed, architected, and built end-to-end by **Harshit Arora**.

- 🌐 **Live Web App**: [https://strawberrydaycare.co.in/](https://strawberrydaycare.co.in/)
- 📱 **Android Mobile App**: In Closed Testing / Review Track — *Launching Soon on Google Play Store*
- 🏫 **Client**: Strawberry Preschool & Daycare (BPTP Parklands, Sector 85, Faridabad, Haryana)
