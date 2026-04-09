# Maintenance Monitoring Data Schema (Major Project)

This document outlines the data parameters and diagnostic logic derived from the project datasets (`archive.zip` and `Washingmachine.csv`).

## 1. Monitoring Parameters (The 10 Vital Signs)

| Category | Parameter | Data Source | Usage |
| :--- | :--- | :--- | :--- |
| **Sensors** | Vibration | `fast.csv` | Detecting physical imbalance or bearing failure. |
| **Sensors** | Electric Current | `fast.csv` | Detecting motor start-up stress or electrical shorts. |
| **Sensors** | Active Power (W) | `slow.csv` | Monitoring overall cycle efficiency and heating health. |
| **Context** | Load Level | `stream_labels.csv`| Categorized as Empty, Half, or Full (Mapped to **Water Level**). |
| **Context** | Target Temp | `stream_labels.csv`| Used to verify if the heater is functioning correctly. |
| **Context** | Program Type | `stream_labels.csv`| Differentiates between wash cycles (Cotton, Mix, etc.). |
| **Spec** | Brand / Model | `Washingmachine.csv`| Providing real-world identity to monitored devices. |
| **Spec** | Max Spin Speed | `Washingmachine.csv`| Calibrating the vibration threshold (Normalization). |
| **Spec** | Inbuilt Heater | `Washingmachine.csv`| Validating high power draw as "Normal" vs "Anomalous." |
| **Spec** | Capacity (kg) | `Washingmachine.csv`| Adjusting tolerance for vibration based on machine size. |

---

## 2. Diagnostic Logic & Thresholds

The application evaluates machine health using a combination of sensor behavior and machine "DNA" (specifications).

### A. Vibration (Bearing Health)
*   **Normal**: Vibration < `(SpinSpeed / 10 + 1500)`.
    *   *Message*: "Performance within spec."
*   **Maintenance Required**: Vibration > `(SpinSpeed / 5 + 2000)`.
    *   *Message*: "Excessive vibration detected. Bearings require inspection."
*   **Note**: Tumble machines (front-load) have a 15% higher tolerance for vibration than Pulsator machines (top-load).

### B. Electrical (Heating & Motor)
*   **Normal Operation**: Power usage matches the selected Program.
    *   *Message*: "Electrical systems optimal."
*   **Early Warning (Heating)**: High power usage (> 1900W) or erratic fluctuations.
    *   *Message*: "Power surge detected. Potential heating element struggle."
*   **Critical Fault**: Current spikes exceeding 3000mA or hitting sensor max (4095).
    *   *Message*: "Critical electrical fault. Immediate inspection required."

### C. Water Level (Cycle Logic)
*   **Logic**: Mapped directly from the `load` parameter in historical logs.
*   **Diagnostic**: If Water Level remains "Full" while Power shows the drainage pump is active, a "Drainage Clog" alert is triggered.

---

## 3. Data Integration Strategy
1.  **Catalog Service**: Parses `Washingmachine.csv` to build a database of devices.
2.  **Maintenance Service**: Acts as the "Brain," comparing real-time sensor data against the limits defined above.
3.  **Archive Parser**: Extracts 3-5 representative runs from the zip to provide "Active" data for demonstration.
