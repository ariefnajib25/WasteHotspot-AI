# WasteHotspot AI

**AI-Powered Township Waste Intelligence System**

WasteHotspot AI is a Flutter-based mobile application prototype developed for the **Sime Darby Property University Hackathon 2026** under the **PLANET – Waste Management** theme.

The application helps township residents report public waste while transforming individual reports into useful township waste intelligence.

**Detect → Verify → Merge → Prioritise → Escalate → Track → Resolve**

---

## 1. Problem

Residents may notice rubbish in parks, playgrounds, walking tracks, and other public township areas.

However, several problems may happen:

- Residents may repeatedly report the same waste issue.
- It may be difficult to identify which hotspot requires faster action.
- Residents may not know what happens after submitting a report.
- Repeated waste hotspots may be difficult to identify.
- Waste may remain unresolved for several days.

WasteHotspot AI provides a smarter reporting workflow that converts individual reports into structured waste hotspots.

---

## 2. Solution

WasteHotspot AI turns resident waste reports into useful township waste intelligence.

When a resident scans rubbish, the system analyses the waste, verifies whether it is located in a public area, checks whether the hotspot already exists, and determines its priority.

If another resident reports the same physical waste, the system does not create another hotspot.

Instead, the new report is merged into the existing hotspot and increases the number of resident confirmations.

This helps reduce duplicate reports while providing stronger information about the seriousness of a waste hotspot.

---

## 3. Main Features

### 3.1 AI Waste Analysis

Residents capture an image of waste using the application.

The prototype analyses:

- Waste detection
- Waste type
- Severity
- Public or personal waste
- Duplicate hotspot
- Resident confirmations
- Hotspot priority
- Hotspot status

The prototype also includes an animated AI scanning process to demonstrate the intended computer vision workflow.

---

### 3.2 Public vs Personal Waste Verification

WasteHotspot AI is designed for waste located in public township areas.

The intended full system combines:

- Smartphone GPS
- Geofencing
- Registered home location
- Image and surrounding-area analysis

If the waste is identified as public waste, the resident can continue with the report.

If the waste appears to be personal household waste inside private property, hotspot creation is blocked.

---

### 3.3 Township Waste Hotspot Map

Residents can view current waste hotspots across the township.

The map uses different indicators for hotspot conditions:

- Low
- Medium
- High
- Urgent
- Resolved

This allows residents to understand where waste problems are occurring around the township.

---

### 3.4 Duplicate Detection and Smart Report Merging

WasteHotspot AI checks whether a newly scanned waste issue matches an existing hotspot.

If the hotspot already exists, the system merges the new report into the same case instead of creating another hotspot.

Example:

**Resident A**

Same location, first report

→ New hotspot  
→ +10 EcoPoints

**Resident B**

Same hotspot

→ Duplicate detected  
→ Merged into existing hotspot  
→ Resident confirmation increases  
→ +3 EcoPoints

The prototype also follows this rule:

**One user = one confirmation per hotspot incident.**

This prevents the same user from repeatedly increasing hotspot confirmations or earning additional EcoPoints.

---

### 3.5 Smart Hotspot Priority

WasteHotspot AI uses resident confirmations to help determine hotspot priority.

Example:

**1 resident confirmation**

→ New Hotspot  
→ HIGH

**2 resident confirmations**

→ Existing Hotspot  
→ HIGH

**3 or more resident confirmations**

→ Repeated Hotspot  
→ URGENT

This allows repeated waste issues to receive greater priority.

---

### 3.6 Time-Based Escalation

WasteHotspot AI also considers how long a waste hotspot remains unresolved.

Example:

**Day 0**

→ Report submitted

**Day 1**

→ Pending Action

**Day 2**

→ Township management notification

**Day 3 and above**

→ Overdue Hotspot  
→ Priority becomes URGENT

This helps prevent unresolved waste reports from being forgotten.

---

### 3.7 Progress Tracking

After submitting or confirming a hotspot, residents can track the report through the Progress page.

Residents can view information such as:

- Severity
- Hotspot priority
- Resident confirmations
- Report age
- Hotspot status
- Action status
- Resolution timeline
- Original waste image

The Progress page allows residents to follow what happens to their report from submission until resolution.

The township map can be viewed by all residents, while the Progress page only shows reports that the logged-in resident has personally submitted or confirmed.

---

### 3.8 Resolution Lifecycle

When a waste hotspot is resolved, its status changes from active to resolved.

The flow is:

**Active Hotspot 🔴**

↓

**Resolved 🟢**

↓

Green `RESOLVED` marker remains visible temporarily

↓

After 2 hours

↓

Removed from the resident active view

The old incident is closed, allowing a new waste incident to be reported at the same location in the future.

---

### 3.9 EcoPoints

Residents receive EcoPoints for useful participation.

**First resident discovering a new hotspot**

→ +10 EcoPoints

**Resident confirming an existing hotspot**

→ +3 EcoPoints

**Same user attempting to confirm the same hotspot again**

→ +0 EcoPoints

This encourages participation while reducing spam.

---

## 4. Technology Used

The current prototype was developed using:

- Flutter
- Dart
- Visual Studio Code
- Android Studio
- Android Emulator
- Git
- GitHub

---

## 5. Running the Project

Make sure **Flutter**, **Git**, and **Google Chrome** are installed on your computer.

Clone the repository:

```bash
git clone https://github.com/ariefnajib25/WasteHotspot-AI.git
```

Open the project folder:

```bash
cd WasteHotspot-AI
```

Install the required Flutter dependencies:

```bash
flutter pub get
```

Run the prototype in Google Chrome:

```bash
flutter run -d chrome
```

The WasteHotspot AI prototype will open automatically in Google Chrome.

---

## 6. Prototype Status

WasteHotspot AI is currently a functional hackathon prototype.

The prototype demonstrates the intended system workflow using simulated analysis and application logic.

The following components are currently simulated:

- AI computer vision analysis
- GPS and geofencing verification
- Township management integration
- Cloud database
- Real-time multi-device synchronisation

A full implementation could integrate real computer vision models, smartphone GPS, backend services, cloud storage, and township management systems.

---

## 7. Current Prototype Flow

**Resident Login**

↓

**Capture Waste**

↓

**AI Scan**

↓

**Public / Personal Verification**

↓

**Duplicate Detection**

↓

**Create or Merge Hotspot**

↓

**Resident Confirmation**

↓

**Priority Calculation**

↓

**Time-Based Escalation**

↓

**Progress Tracking**

↓

**Resolution**

---

## 8. Hackathon

**Sime Darby Property University Hackathon 2026**

**Theme:** PLANET – Waste Management

**Project:** WasteHotspot AI

**System:** AI-Powered Township Waste Intelligence System

---

## Project Vision

> **From Complaints to Community Action.**

WasteHotspot AI does not just report rubbish.

It transforms resident waste reports into township intelligence that can help identify repeated waste problems, prioritise action, escalate unresolved hotspots, and track issues until resolution.