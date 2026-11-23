# Firebase deployment runbook — intentionally NOT deployed

Project: `kids-learning-system-bc024`. Deploy only with explicit approval after phase gates.

## Preflight
1. Enable Firebase Authentication providers **Email/Password** (parent) and **Anonymous** (child).
2. Enable Cloud Firestore and Cloud Functions, and confirm the required Firebase billing plan and permissions.
3. Register both Android package IDs in Firebase App Check with Play Integrity and their actual signing certificate fingerprints. Use debug App Check only for authorized test builds.
4. Configure each Flutter app with its own Firebase Android app ID and restricted client API key through secure build settings. Never use the parent app ID for the child app.
5. Configure the secret in Firebase Secret Manager: `firebase functions:secrets:set BILSAN_GEMINI_API_KEY --project kids-learning-system-bc024`. Do not commit keys.
6. Verify the Gemini model and endpoint available for the project; model names can change. Keep AI disabled if the provider is unavailable.
7. Run GitHub CI checks for Firestore rules, Functions syntax/dependencies and Flutter analysis/tests.

## Deployment commands (manual, only when approved)
From the `firebase/` directory:
```sh
npm --prefix functions ci
firebase login
firebase use kids-learning-system-bc024
firebase deploy --only firestore:rules,functions --project kids-learning-system-bc024
```

## Production verification
- Parent sign-in; family creation; child anonymous sign-in; App Check enforcement.
- Short-lived pairing request; parent approval; child status check; device list; revocation.
- Rejected unapproved child; rejected cross-family access; rejected repeated bad codes.
- Child progress and parent live view; network loss and recovery; phone/tablet.
- Restricted Gemini hint; unavailable secret and model failure; no direct Gemini key in APK.

## Important
This repository workflow **validates only** and does not deploy. Firebase services and
Gemini are not live until manual deployment and device verification succeed.
