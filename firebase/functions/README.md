# Pairing backend (Stage 2)
Callable functions require Firebase Auth and valid Firebase App Check tokens.
Deploy with Firebase CLI after enabling Firestore, Authentication (email/password and anonymous), App Check and Cloud Functions billing/permissions.

Functions: createFamily (parent), requestPairing (anonymous child, eight-digit 10-minute code), approvePairing (authenticated owner), revokeDevice (owner), getPairingStatus (child).
The client must not infer approval from local storage. Firestore rules prevent direct client edits to family ownership and device approval.

**Not deployed.** Code in GitHub does not mean the backend is live. The functions have not been end-to-end tested. Production hardening still requires pairing-code attempt rate limits, stronger abuse protection, identity/provider verification for parent roles, revocation and local-data policy, and automated emulator tests. Do not enable production pairing before these gates pass.
