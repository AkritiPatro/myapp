# Sane Machine: Project Overview & System Explanation

This document explains the architecture and logic of the **Sane Machine Maintenance Monitoring System**. You can use this to explain the project to others during a presentation or demo.

---

## 1. Core Objective
The goal of this project is to move from **Reactive Maintenance** (fixing things when they break) to **Predictive Maintenance** (fixing things right before they break). 

Instead of generic alerts, we provide **Technical Diagnostics** based on real sensor data.

---

## 2. Key Features

### A. Catalog-Driven Fleet Management
The system doesn't just "add a name." It synchronizes with an authentic catalog of over 20+ real industrial washing machine models (LG, Samsung, IFB, Bosch, etc.).
*   **Why?** Because a machine that spins at 1400 RPM has different "normal" vibration levels than one that spins at 600 RPM. We use the **Max RPM** to calculate custom safety thresholds for each machine.

### B. Smart Diagnostic Engine
The system uses real-world sensor data (Vibration, Power, Current) to determine the health of the machine.
*   **Vibration (Bearing Health)**: High vibration at high RPM suggests "Bearing Fatigue."
*   **Power (Heater Integrity)**: Spikes in power on non-heated cycles suggest electrical leakage.
*   **Current (Motor Load)**: High amperage suggests a motor overload or mechanical lock.

### C. Automated Analytics (One-Click Stress Test)
When you click **"Run Smart Analytics,"** the app simulates a diagnostic run using historical "Fast" and "Slow" sensor logs.
*   It picks a random scenario (Healthy, Heating Issue, or Bearing Fail) to show variety.
*   It analyzes the *Peaks* of that data to give a final verdict.

### D. Context-Aware AI Assistant
We integrated **Gemini AI** as a "Support Expert." 
*   **Situational Awareness**: The AI is automatically fed the live status of all your machines.
*   **Plain English**: If a machine has a "Warning," you can ask the AI: *"What should I do about my LG machine?"* It will explain the technical issue (e.g., floor instability) and recommend an action.

---

## 3. Maintenance Status Levels

| Status | Color | Meaning |
| :--- | :--- | :--- |
| **Normal** | Green | Machine is in Standby / Ambient Monitoring. |
| **Early Warning** | Yellow | Minor sensor drifts (Noise/Instability). Monitor closely. |
| **Maintenance Req** | Orange | Technical intervention needed (e.g., Lubrication or Cleaning). |
| **Critical Failure** | Red | Safety risk or mechanical lock. Immediate shutdown recommended. |

---

## 4. Technology Stack
*   **Frontend**: Flutter (Web & Mobile ready).
*   **Backend**: Firebase (Hosting, Auth, Database).
*   **Artificial Intelligence**: Google Gemini (Custom technical instructions).
*   **Data Source**: CSV archives from real industrial washing machine runs.

---
*Created for the Major Project: Sane Machine Maintenance Monitoring*
