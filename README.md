# Sane Machine 🛠️
**AI-Powered Predictive Maintenance & Diagnostics for Appliances**

Sane Machine is a technical tool designed to monitor machine health using real-time sensor data. It predicts mechanical failures by analyzing vibration and power consumption, backed by Google’s Gemini AI.

## ✨ Key Features
*   **Predictive Diagnostics**: Real-time evaluation of machine health (Healthy, Warning, Failure) based on dynamic RPM scaling.
*   **Gemini AI Chat**: Context-aware AI assistant that helps interpret diagnostic results in plain English.
*   **Admin Dashboard**: Manage device catalogs and user access with Role-Based Access Control (RBAC).
*   **Data History**: Visual history charts to track sensor trends and anomalies over time.

## 🧠 Technical Overview
The system utilizes a custom diagnostic engine that scales thresholds based on machine specifications (e.g., Max RPM). For a deep dive into the math and logic, see:
*   [Technical Details](TECHNICAL_DETAILS.md)
*   [System Explainer](SYSTEM_EXPLAINER.md)

## 🚀 Getting Started
1. **Initialize Firebase**: `flutterfire configure`
2. **Configure API Key**: Access Gemini by adding your key to an `.env` file (`GEMINI_API_KEY`).
3. **Run**: `flutter run`
