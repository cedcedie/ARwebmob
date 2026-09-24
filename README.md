# AR Science Explorer

A Flutter app for Grade 7 science with two sides in one codebase:

- **Student app (Android)** - lessons by subject (Chemistry, Biology, Physics, Earth Science), quizzes, progress, and an AR lab that shows 3D models when a lesson's printed marker is scanned (Unity embedded via `flutter_embed_unity`).
- **Teacher portal (web)** - manage lessons, quizzes, students, access codes and teacher access. Deployed to Firebase Hosting.

`PROJECT_FLOW.md` is the functional specification and data model.

## Services

| Concern | Where it runs |
| --- | --- |
| Sign-in, database, hosting | Firebase project `ar-science-explorer-57de3` (Auth, Firestore, Hosting) |
| Lesson PDF storage | Supabase Storage, bucket `lesson-content` |
| Student password reset | Supabase Edge Function `set-student-password` |

Firebase Storage and Cloud Functions are not used in production because they require the paid Blaze plan. `functions/` and `storage.rules` are kept only in case the project is upgraded later.

## Setup

1. Install Flutter (Dart SDK `^3.12`) and run `flutter pub get`.
2. Create `supabase.env.json` in the project root (it is git-ignored):

   ```json
   { "SUPABASE_ANON_KEY": "<anon public key of your Supabase project>" }
   ```

3. Set `supabaseUrl` in `lib/core/services/lesson_content_upload_service.dart` to your Supabase project URL.

## Supabase setup (once per project)

1. SQL Editor: run `supabase/setup_storage.sql` (creates the public `lesson-content` bucket, PDF/PPTX only, 25 MB, plus upload policies).
2. Edge Functions: deploy `supabase/functions/set-student-password/index.ts` under the name `set-student-password`.
3. Edge Functions -> Secrets: add `FIREBASE_SERVICE_ACCOUNT` containing the full JSON of a Firebase service-account key (Firebase console -> Project settings -> Service accounts -> Generate new private key). Never commit this key.

## Build and deploy

Always pass the Supabase key file so uploads and password reset work:

```
flutter build apk --release --dart-define-from-file=supabase.env.json
flutter build web --release --dart-define-from-file=supabase.env.json
firebase deploy --only hosting --project ar-science-explorer-57de3
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Tests

```
flutter analyze
flutter test
```

## Notes

- Teacher-added lessons reuse the app's existing 3D models (picked from a list in the lesson form). New models are not uploaded or rendered from the teacher portal.
- Lesson content uploads are PDF only.
- The Earth Science (Q4) voice-over scripts in `lib/core/ar/voice_scripts_data.dart` still need a native-speaker review of the Filipino lines.
