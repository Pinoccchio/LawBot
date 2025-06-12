# LawBot - AI Legal Assistant for Philippine Cybercrime Law

## Overview

LawBot is a mobile application designed to be a personal legal assistant, providing accessible information and guidance on cybercrime laws in the Philippines. It leverages AI to help users understand complex legal topics, connect with resources, and get answers to their questions in a conversational manner.

## Key Features

-   **🤖 AI Legal Chat Assistant**: Get answers to your legal questions about Philippine cybercrime laws from an AI-powered chatbot using Google's Generative AI.
-   **📚 Legal Resources**: Access a database of cybercrime laws, government agency contacts, and educational materials on digital safety.
-   **📊 Chat History**: Review and search your past conversations with the legal assistant.
-   **👤 User Profiles**: Create and manage a personal account with a customizable profile picture.
-   **🔐 Secure Authentication**: Secure sign-up and sign-in using Firebase Authentication.

## Technologies Used

-   **Framework**: Flutter/Dart
-   **Backend & Authentication**: Firebase
-   **Database & Storage**: Supabase
-   **AI Chat**: Google Generative AI (`google_generative_ai`)
-   **State Management**: Provider (`provider`)
-   **Key Packages**:
    -   `image_picker`: For selecting profile pictures.
    -   `cached_network_image`: For efficient image caching.
    -   `url_launcher`: For opening external links to legal resources.
    -   `shared_preferences`: For local data persistence.
    -   `share_plus`: For sharing content from the app.

## Installation

### Prerequisites

-   Flutter SDK (3.0.0 or higher)
-   Dart SDK (3.0.0 or higher)
-   Android Studio / VS Code with Flutter extensions
-   A Firebase project
-   A Supabase project

### Setup Instructions

1.  **Clone the repository**

    ```bash
    git clone https://github.com/yourusername/lawbot.git
    cd lawbot
    ```

2.  **Install dependencies**

    ```bash
    flutter pub get
    ```

3.  **Configure Firebase**
    -   Create a Firebase project.
    -   Add your Android/iOS app to the project.
    -   Download `google-services.json` (for Android) or `GoogleService-Info.plist` (for iOS) and place it in the appropriate directory.
    -   Enable Email/Password authentication in the Firebase console.

4.  **Configure Supabase**
    -   Create a Supabase project.
    -   Set up the necessary tables (e.g., `user_profiles`, `chat_history`).
    -   Add your Supabase URL and anon key to the app's configuration file.

5.  **Run the app**

    ```bash
    flutter run
    ```

## Project Structure

```
lib/
├── assets/                 # Images and other static assets
├── config/                 # Configuration files (e.g., Supabase)
├── providers/              # State management (Provider)
├── screens/                # UI screens for different app features
├── services/               # Business logic (Firebase, Supabase, etc.)
├── utils/                  # Utility functions and helpers
├── widgets/                # Reusable UI components
├── firebase_options.dart   # Firebase configuration
└── main.dart               # App entry point
```

## Usage

-   **Authentication**: Sign up, log in, or reset your password.
-   **Chat**: Ask legal questions and receive AI-generated answers.
-   **Resources**: Browse and search for laws and articles.
-   **Profile**: Update your profile information and picture.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
