# Project Blueprint

## Overview

A Flutter application that allows users to sign in, view a list of devices, and interact with a Gemini-powered chatbot.

## Style, Design, and Features

### Version 1.0
- **Initial Setup:** Basic Flutter application with a `MaterialApp`.
- **Theme:**
  - `ThemeData` with a purple-based color scheme.
  - Light and dark mode support using `provider` and `ThemeProvider`.
  - Custom fonts using `google_fonts` (`Oswald`, `Roboto`, `Open Sans`).
- **Authentication:**
  - Firebase Authentication with email and password.
  - Sign-in and sign-up screens.
  - `fluttertoast` for user-friendly error messages.
- **Routing:**
  - `go_router` for declarative navigation.
  - Protected routes that require authentication.
  - Automatic redirection for signed-in/signed-out users.
  - Routes for:
    - `/` (Landing Page)
    - `/sign-in`
    - `/sign-up`
    - `/devices` (Device List)
    - `/devices/:id` (Device Detail)
    - `/chatbot`
- **Pages & UI:**
  - **Landing Page:** Simple page with "Sign In" and "Sign Up" buttons.
  - **Sign-In Page:** Form for email and password entry.
  - **Sign-Up Page:** Form for creating a new account.
  - **Device Page:** Placeholder page with an `AppBar` containing navigation to the chatbot, a theme toggle, and a logout button.
  - **Device Detail Page:** Placeholder page.
  - **Chatbot Screen:**
    - Basic UI for a chat interface.
    - Integration with `firebase_ai` for connecting to Gemini.
- **Services:**
  - `GeminiChatService` to handle interactions with the Gemini model.

## Current Plan & Steps

*(No active plan. Ready for new feature requests.)*
