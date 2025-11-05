# Sane Machine: Project Blueprint

## Overview

Sane Machine is a Flutter-based mobile and web application designed for managing devices. Built within Firebase Studio, it leverages a suite of Firebase services to provide a secure, scalable, and real-time user experience. The primary goal of the app is to offer users a seamless way to sign in, manage their profile, and interact with a list of devices. The application features a modern, dual-theme interface (light and dark mode) with a consistent design language, ensuring a high-quality user experience across all platforms.

## Style, Design, and Features

This section outlines the complete architecture, design choices, and features implemented in the application from its initial version to the current state.

### 1. Project Setup & Core Dependencies

*   **Framework:** Flutter
*   **Environment:** Firebase Studio
*   **Firebase Project:** Connected to `sane-machine-3e910`.
*   **Core Packages:**
    *   `firebase_core`: For Firebase initialization.
    *   `firebase_auth`: For user authentication.
    *   `cloud_firestore`: For database (setup pending full implementation).
    *   `firebase_analytics`: For usage tracking and analytics.
    *   `provider`: For state management (`ThemeProvider`, `DeviceProvider`).
    *   `google_fonts`: For custom typography (`Poppins`).
    *   `fluttertoast`: For non-intrusive user notifications.

### 2. Authentication System

*   **Email & Password:** Full sign-up and sign-in flows are implemented.
*   **Auth State Persistence:**
    *   A "Remember Me" checkbox on the sign-in screen controls the session persistence.
    *   If checked, `Persistence.LOCAL` is used to keep the user signed in across app restarts.
    *   If unchecked, `Persistence.SESSION` is used, ending the session when the app is closed.
*   **Automatic Redirects:** The app uses a `StreamBuilder` to listen to `authStateChanges()` from Firebase Auth. This automatically navigates the user to the device page upon successful sign-in or to the landing page upon sign-out, ensuring a seamless transition.
*   **Error Handling:** Clear and user-friendly toast messages are displayed for common authentication errors like `user-not-found` or `wrong-password`.

### 3. UI/UX and Theming

*   **Dual-Theme System (Light/Dark Mode):**
    *   A `ThemeProvider` class, managed by the `provider` package, allows users to toggle between light and dark modes.
    *   The user's theme preference is managed within the app's state.
*   **Color Palette:**
    *   **Light Mode:** A clean and modern look with a `deepPurple` primary color and white backgrounds.
    *   **Dark Mode:** A sleek, eye-friendly interface using `tealAccent` as the primary color against dark backgrounds (`Colors.grey[900]`, `Colors.black87`).
*   **Typography:**
    *   The `google_fonts` package is used to apply the **Poppins** font, giving the app a professional and contemporary feel.
*   **Component Styling:**
    *   A centralized theme is defined in `main.dart` for both light and dark modes, specifying styles for `appBarTheme`, `floatingActionButtonTheme`, and `elevatedButtonTheme` for consistency.
    *   Input fields are custom-styled with rounded borders and theme-aware colors for a modern, clean appearance.
*   **Layout & Responsiveness:**
    *   Pages like Sign In and Sign Up use `SingleChildScrollView` to ensure the UI is scrollable and avoids rendering overflow on smaller screens.
    *   Logical spacing and alignment are maintained using `SizedBox`, `Padding`, and `Center` widgets.
*   **Navigation:**
    *   The app uses named routes (`/`, `/signin`, `/signup`, `/devices`) for clear and maintainable navigation.
    *   `FirebaseAnalyticsObserver` is integrated with the `MaterialApp` navigator to automatically track screen views.

### 4. Current Plan & Next Steps

*   **Resolved Issue:** The "Remember Me" checkbox color was inconsistent with the dark theme. This was addressed by directly setting the `activeColor` to a neutral `Colors.grey`, ensuring it looks acceptable in both light and dark modes as a temporary workaround for a complex theming issue.

*   **Next Steps:** With the authentication and theming systems now stable, the immediate priority is to build out the core functionality of the application:
    1.  **Implement the Device Page:** Flesh out the `DevicePage` to display a list of devices associated with the logged-in user.
    2.  **Firestore Integration:** Connect the `DevicePage` to Cloud Firestore to fetch and display device data.
    3.  **Add/Edit Device Functionality:** Implement features to allow users to add new devices or edit existing ones.
