# WasteHotspot AI

**AI-Powered Township Waste Intelligence System**

WasteHotspot AI is a Flutter-based mobile application prototype developed for the **Sime Darby Property University Hackathon 2026** under the **PLANET – Waste Management** theme.

The application helps township residents report public waste while transforming individual reports into useful township waste intelligence.

Instead of only allowing residents to complain about rubbish, WasteHotspot AI helps residents:

**Detect → Verify → Merge → Prioritise → Escalate → Track → Resolve**

---

## Problem

Residents may notice rubbish in parks, playgrounds, walking tracks and other township public areas.

However, common problems include:

- Residents repeatedly report the same waste issue.
- Management may not immediately know which issue is more urgent.
- Residents may not know whether action has been taken.
- Repeated waste hotspots are difficult to identify.
- Reports may remain unresolved for several days.

WasteHotspot AI provides a smarter reporting workflow that organises resident reports into structured waste hotspots.

---

## Solution

WasteHotspot AI converts public waste reports into a single intelligent hotspot record.

When a resident scans rubbish, the system analyses the waste, verifies whether it is located in a public area, checks whether the hotspot already exists and calculates its priority.

If another resident reports the same waste, the system does not create another case.

Instead, the report is merged into the existing hotspot and increases the number of resident confirmations.

---

## Main Features

### 1. AI Waste Analysis

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

---

### 2. Public vs Personal Waste Verification

WasteHotspot AI is designed to prevent private household waste from becoming a township public waste report.

The intended full system combines:

- Smartphone GPS
- Geofencing
- Registered home location
- Image and surrounding-area analysis

Public waste can continue to submission while personal household waste is blocked.

---

### 3. Township Waste Hotspot Map

Residents can view waste hotspots across the township.

Hotspots use different priority indicators:

- Low
- Medium
- High
- Urgent
- Resolved

The map helps residents understand where waste problems are occurring.

---

### 4. Duplicate Detection and Smart Report Merging

If multiple residents report the same physical waste hotspot, WasteHotspot AI merges the reports into one case.

Example:

```text
Resident A
First report
→ New hotspot
→ +10 EcoPoints

Resident B
Same hotspot
→ Duplicate detected
→ Merged into existing hotspot
→ +3 EcoPoints