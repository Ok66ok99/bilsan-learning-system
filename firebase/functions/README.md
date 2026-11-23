# Pairing backend (Stage 2)
Callable functions require Firebase Auth and valid Firebase App Check tokens.
Deploy with Firebase CLI after enabling Firestore, Authentication (email/password and anonymous), App Check and Cloud Functions billing/permissions.

Functions: createFamily (email/password parent), requestPairing (anonymous child, eight-digit 10-minute code), approvePairing (authenticated owner), revokeDevice (owner). Child status lookup is implemented with the child's original code and authenticated UID.
The client must not infer approval from local storage. Firestore rules prevent direct client edits to family ownership and device approval.

**Not deployed.** Code in GitHub does not mean the backend is live. The functions have not been end-to-end tested. Initial per-account rate limits are present; production hardening still requires adversarial emulator tests, global/IP-level abuse controls, parent identity verification policy, revocation and cached local-data policy. Do not enable production pairing before these gates pass.

Deployment instructions: [DEPLOY_WHEN_APPROVED.md](../DEPLOY_WHEN_APPROVED.md). No automatic publishing is configured.
