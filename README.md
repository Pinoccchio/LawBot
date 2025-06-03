# LawBot - Legal Assistant Mobile App

![LawBot Logo](assets/images/logo.png)

## Overview

LawBot is a comprehensive mobile application designed to provide accessible legal assistance and information about cybercrime laws in the Philippines. The app serves as a personal legal assistant, helping users understand complex legal concepts, access relevant resources, and get guidance on cybercrime-related issues.

## Key Features

### 🤖 Legal Chat Assistant
- AI-powered legal assistant that answers questions about cybercrime laws
- Natural language processing for conversational interactions
- Contextual responses based on Philippine legal framework

### 📚 Legal Resources
- Comprehensive database of Philippine cybercrime laws and regulations
- Government agency information and contact details
- Educational materials on digital rights and online safety
- Searchable legal database with filtering options

### 📊 Chat History
- Complete history of all conversations with the legal assistant
- Categorized chat logs for easy reference
- Analytics on most discussed legal topics

### 👤 User Profiles
- Personalized user accounts with customizable profiles
- TikTok-style profile picture management
- Account settings and preferences
- Complete account management (create, read, update, delete)

### 🔐 Security Features
- Secure authentication with Firebase
- Data privacy compliance
- End-to-end encryption for sensitive information

## Technologies Used

- **Frontend**: Flutter/Dart
- **Backend**:
    - Firebase Authentication
    - Supabase for database and storage
- **AI Integration**: Custom NLP model for legal assistance
- **State Management**: Provider pattern
- **Storage**: Supabase Storage for profile pictures and assets

## Installation

### Prerequisites
- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Firebase project setup
- Supabase project setup

### Setup Instructions

1. **Clone the repository**
   \`\`\`bash
   git clone https://github.com/yourusername/lawbot.git
   cd lawbot
   \`\`\`

2. **Install dependencies**
   \`\`\`bash
   flutter pub get
   \`\`\`

3. **Configure Firebase**
    - Create a Firebase project
    - Add Android/iOS apps to your Firebase project
    - Download and add the google-services.json (Android) or GoogleService-Info.plist (iOS)
    - Enable Email/Password authentication

4. **Configure Supabase**
    - Create a Supabase project
    - Set up the required tables (user_profiles, chat_history, legal_resources, etc.)
    - Update the Supabase URL and anon key in the app

5. **Run the app**
   \`\`\`bash
   flutter run
   \`\`\`

## Project Structure

\`\`\`
lib/
├── config/                 # Configuration files
│   └── supabase_config.dart
├── main.dart               # Entry point
├── providers/              # State management
│   ├── auth_provider.dart
│   ├── language_provider.dart
│   ├── notification_provider.dart
│   └── theme_provider.dart
├── screens/                # UI screens
│   ├── auth/               # Authentication screens
│   │   ├── sign_in_screen.dart
│   │   ├── sign_up_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── home_screen_container.dart
│   ├── onboarding_screen.dart
│   ├── splash_screen.dart
│   └── tabs/               # Main app tabs
│       ├── history_tab.dart
│       ├── profile_tab.dart
│       └── resources_tab.dart
├── services/               # Business logic and API services
│   ├── auth_service.dart
│   └── database_service.dart
└── widgets/                # Reusable UI components
└── tiktok_avatar.dart
\`\`\`

## Usage

### Authentication
- Users can sign up with email and password
- Login with existing credentials
- Reset password functionality

### Chat Interface
- Type legal questions in the chat interface
- Receive AI-generated responses based on Philippine cybercrime laws
- Save important conversations for future reference

### Resources
- Browse categorized legal resources
- Search for specific laws or topics
- Access government agency information
- View educational materials on cybercrime prevention

### Profile Management
- Upload and manage profile pictures
- Edit personal information
- View chat history and saved resources
- Delete account and all associated data

## Screenshots

![Login Screen](/placeholder.svg?height=400&width=200&query=mobile%20app%20login%20screen)
![Chat Interface](/placeholder.svg?height=400&width=200&query=AI%20chat%20interface%20mobile%20app)
![Resources Tab](/placeholder.svg?height=400&width=200&query=resources%20list%20mobile%20app)
![Profile Screen](/placeholder.svg?height=400&width=200&query=user%20profile%20mobile%20app)

## Roadmap

- **Short-term**
    - Add haptic feedback
    - Implement pull-to-refresh
    - Add skeleton loading screens
    - Create custom animations
    - Add sound effects
    - Implement image cropping

- **Mid-term**
    - Add profile picture zoom and animations
    - Implement profile sharing
    - Expand legal resources database
    - Add offline mode support
    - Implement multi-language support

- **Long-term**
    - Integrate with court case management systems
    - Add document scanning and analysis
    - Implement lawyer directory and booking
    - Create community forums for legal discussions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Legal content provided by legal experts specializing in Philippine cybercrime law
- UI/UX design inspired by modern mobile applications
- Special thanks to all contributors and testers
