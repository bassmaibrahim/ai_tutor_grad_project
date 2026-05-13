# Eshrhly AI Tutor

An AI-powered educational platform built with Flutter that helps teachers generate educational content automatically and allows students to learn through AI-assisted lessons and quizzes.

---

## Features

- Teacher & Student roles
- Classroom creation and management
- multiple input formats including PDF documents (with text extraction), OCR-based handwritten note recognition, and plain text input
- AI-generated summaries, explanations, key points, and quizzes
- Recommended educational videos
- Quiz system with score tracking
- Text-to-speech support
- Students can use the AI tutor individually OR join a class with a teacher
- Real-time updates using Firestore

---

## Technologies Used

- Flutter & Dart
- Firebase Authentication
- Cloud Firestore
- Railway-hosted AI API
- HTTP API integration
- flutter_tts
- file_picker
- OCR for text extraction from PDF content

---

## System Architecture

```text
Flutter App
   ├── Firebase Authentication
   ├── Cloud Firestore
   └── Railway AI Backend
```

---

## Prerequisites

- Flutter SDK 3.19.0+
- Android Studio 
- Firebase project configuration
- Internet connection

---
## How to Run the Project

This project is already pre-configured to run without any additional setup.

---

### 1. Install Dependencies

Run the following command:

```bash
flutter pub get
```

---

### 2. Run the Application

For Android / Emulator:

```bash
flutter run
```

For Web (Chrome):

```bash
flutter run -d chrome
```

---

## Important Notes

- Firebase is already fully configured inside the project.
- No manual Firebase setup is required.
- The AI backend is deployed online and will work automatically.
- If needed, AI source code is available here:
  https://drive.google.com/drive/folders/1omkuADFCm0N2Vf-9ScpXTAL1DmcFFVIF?usp=sharing

---


## Teacher Flow

1. Register as Teacher
2. Create Class
3. Upload PDF, images, or paste text (including OCR extracted content from written notes)
4. Generate AI content
5. Publish lesson and quiz

---

## Student Flow

1. Register as Student
2. Either:
    - Join a class using a code
    - OR use AI tutor individually without joining a class
3. View lessons
4. Take quizzes
5. View scores and recent studies

---

## Firestore Collections

```text
users/
classes/
lessons/
quizzes/
user_studies/
teachers/
```

---

## Security

- Firebase Authentication secures user access
- Firestore rules restrict unauthorized access
- AI API keys are stored securely in backend environment variables

---

## Demo Access

For evaluation purposes, pre-created accounts will be provided:

- Teacher Account (for full system management)
- account: teacher@gmail.com password: Teachertest1 
- Student Account (for joining classes and interacting with content)
- account: student@gmail.com password: Studenttest1

👉 This allows you to test the full workflow without creating new accounts.

---

## Project Demo

A full video demonstration of the project will be provided here:
👉 **[[Demo Video Link Will Be Added Here](https://drive.google.com/file/d/1U7IUc2pBrQEiiB6pTkV0sJoymvl6noZR/view?usp=drive_link)]**

---

## Troubleshooting

| Issue | Solution |
|---|---|
| Firebase error | Check Firebase configuration files |
| AI processing delay | Railway server may need cold start |
| Permission denied | Update Firestore rules |
| Flutter dependency issue | Run `flutter clean` then `flutter pub get` |

---

## Quick Test Guide

1. Run the app
2. Login using provided teacher account
3. Create class and lesson/or view the created class and lessons
4. Generate AI content
5. Publish lesson
6. Login using student account
7. Join class or use AI tutor directly/view joined classes and created lessons
8. Take quiz and view results

---
