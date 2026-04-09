# Sane Machine: Technical Reference & Diagnostic Logic

This document provides a deep-dive into the technical implementation of the monitoring system, including data structures, sensor thresholds, and diagnostic algorithms.

---

## 1. Data Architecture

### A. The Master Catalog (`Washingmachine.csv`)
This is the core "Identity" database for the application. Each entry defines:
- **Brand & Model**: Used for identification.
- **Max Spin Speed (RPM)**: **CRITICAL**. This value is used to dynamically scale vibration thresholds. A 1400 RPM machine naturally vibrates more than a 600 RPM machine.
- **Heater Presence**: Boolean flag. Used to determine if high power consumption (Wattage) is "Normal" or a "Fault."

### B. Sensor Archives (`fast.csv` & `slow.csv`)
These files contain raw telemetry from IoT sensors attached to industrial machines.
- **Vibration**: Measured in high-frequency units.
- **Power**: Real-time wattage consumption.
- **Current**: Amperage draw from the motor and logic board.

---

## 2. The Diagnostic Engine (Expert Logic)

The following logic is implemented in `MaintenanceService.evaluateHealth()` and is used to categorize every machine run.

### A. Vibration (Bearing & Balance Health)
We use a **Dynamic Threshold** that adapts to the machine's capability:
1. **Early Warning Level**: `(MaxRPM / 10) + 1500 units`
   - *Example (1200 RPM machine)*: `120 + 1500 = 1620 units`.
2. **Maintenance Required Level**: `(MaxRPM / 5) + 2000 units`
   - *Example (1200 RPM machine)*: `240 + 2000 = 2240 units`.
3. **Critical Failure**: Any spike hitting **4095 units**.
   - *Reasoning*: 4095 is the maximum sensor limit, representing a physical mechanical "bottoming out" or extreme shock.

### B. Power & Heat (Electrical Health)
- **Normal Operation**: High power (>2000W) is expected *only* if `hasHeater` is true.
- **The Anomaly**: If a machine without a heater (or a cold cycle) draws **>1900W**, the system flags **Amperage Overload**. This usually indicates a motor winding short or faulty logic.

### C. Amperage (Motor Load)
- **Threshold**: **>3000 units**.
- **Diagnostic Result**: Indicates high mechanical resistance (e.g., something stuck in the drum) or an electrical surge in the control board.

---

## 3. Maintenance Verifications

| Condition | Technical Message | Actionable Insight |
| :--- | :--- | :--- |
| Vibration > Warning | "Minor instability / Bearing noise" | Check floor leveling or balance load. |
| Vibration > Required | "Bearing Fatigue detected" | **Schedule manual lubrication.** |
| Peak Vibration = 4095 | "Mechanical Lock / Major Failure" | Immediate motor shutdown. |
| Power > 1900W (No Heat) | "Amperage Overload / Logic Fault" | Check motor windings & wiring. |

---

## 4. AI Contextual Intelligence
The **Gemini AI** doesn't guess. When you click "Ask AI," the system generates a **Context String** which is hidden from the user but sent to the AI:
`"USER DEVICE CONTEXT: - LG FHM1207 (Status: Warning, Vibration: 1850, Message: Bearing Fatigue)"`

The AI then correlates the **Vibration: 1850** against its internal knowledge of the machine's **MaxRPM** to explain the "Early Warning" situation in natural language.

---
*Created for the Major Project: Technical Documentation*
