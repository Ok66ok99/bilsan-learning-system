'use strict';
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const crypto = require('node:crypto');
const security = require('./security');
admin.initializeApp();
const db = admin.firestore();
const region = 'us-central1';
const options = { region, enforceAppCheck: true, maxInstances: 10 };
const geminiKey = defineSecret('BILSAN_GEMINI_API_KEY');

function uidOf(request) {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in required');
  return request.auth.uid;
}
function requireString(value, name, max = 128) {
  if (typeof value !== 'string' || !value.trim() || value.length > max)
    throw new HttpsError('invalid-argument', name + ' is invalid');
  return value.trim();
}
async function parentFamily(uid, familyId) {
  const ref = db.doc('families/' + familyId);
  const snap = await ref.get();
  if (!snap.exists || snap.get('ownerUid') !== uid)
    throw new HttpsError('permission-denied', 'Not family owner');
  return ref;
}

exports.createFamily = onCall(options, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'parent'))
    throw new HttpsError('permission-denied', 'Parent email/password sign-in required');
  const ownerRef = db.doc('parentFamilies/' + uid);
  return db.runTransaction(async tx => {
    const owner = await tx.get(ownerRef);
    if (owner.exists) return { familyId: owner.get('familyId') };
    const familyRef = db.collection('families').doc();
    tx.create(familyRef, { ownerUid: uid, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    tx.create(ownerRef, { familyId: familyRef.id });
    return { familyId: familyRef.id };
  });
});

exports.requestPairing = onCall(options, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'child'))
    throw new HttpsError('permission-denied', 'Child anonymous sign-in required');
  const requestLimitRef = db.doc('pairingIssueLimits/' + uid);
  await db.runTransaction(async tx => {
    const snap = await tx.get(requestLimitRef);
    const now = Date.now();
    const last = snap.exists ? snap.get('windowStartedAt')?.toMillis() ?? 0 : 0;
    const count = now - last < 10 * 60 * 1000 ? snap.get('count') ?? 0 : 0;
    if (count >= 3) throw new HttpsError('resource-exhausted', 'Try again later');
    tx.set(requestLimitRef, { count: count + 1,
      windowStartedAt: admin.firestore.Timestamp.fromMillis(count === 0 ? now : last) });
  });
  const code = crypto.randomInt(10000000, 99999999).toString();
  const hash = security.codeHash(code);
  const existing = await db.collection('pairingRequests').where('deviceUid', '==', uid)
    .where('status', '==', 'pending').limit(20).get();
  const batch = db.batch();
  existing.forEach(doc => batch.update(doc.ref, { status: 'superseded' }));
  const ref = db.collection('pairingRequests').doc(hash);
  batch.create(ref, { deviceUid: uid, status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000) });
  await batch.commit();
  return { code, expiresInSeconds: 600 };
});

exports.approvePairing = onCall(options, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'parent'))
    throw new HttpsError('permission-denied', 'Parent sign-in required');
  const familyId = requireString(request.data?.familyId, 'familyId');
  const code = requireString(request.data?.code, 'code', 8);
  if (!security.validCode(code)) throw new HttpsError('invalid-argument', 'Invalid code');
  const familyRef = await parentFamily(uid, familyId);
  const hash = security.codeHash(code);
  const pairRef = db.doc('pairingRequests/' + hash);
  const attemptsRef = db.doc('pairingAttempts/' + uid);
  // Consume an attempt in a separate committed transaction. Failed codes
  // must still count; a thrown approval transaction would roll back writes.
  await db.runTransaction(async tx => {
    const attempts = await tx.get(attemptsRef);
    const now = Date.now();
    const last = attempts.exists ? attempts.get('windowStartedAt')?.toMillis() ?? 0 : 0;
    const count = now - last < 10 * 60 * 1000 ? attempts.get('count') ?? 0 : 0;
    if (count >= 5) throw new HttpsError('resource-exhausted', 'Try again later');
    tx.set(attemptsRef, { count: count + 1,
      windowStartedAt: admin.firestore.Timestamp.fromMillis(count === 0 ? now : last) });
  });
  return db.runTransaction(async tx => {
    const pair = await tx.get(pairRef);
    if (!pair.exists || !security.pairingValid({
      status: pair.get('status'), expiresAt: pair.get('expiresAt').toMillis(),
      deviceUid: pair.get('deviceUid'),
    }, Date.now()))
      throw new HttpsError('failed-precondition', 'Code expired or already used');
    const deviceUid = pair.get('deviceUid');
    const deviceRef = familyRef.collection('devices').doc(deviceUid);
    const existing = await tx.get(deviceRef);
    if (existing.exists && existing.get('revoked') === false)
      throw new HttpsError('already-exists', 'Device already paired');
    tx.set(deviceRef, { approved: true, revoked: false,
      approvedAt: admin.firestore.FieldValue.serverTimestamp() });
    tx.update(pairRef, { status: 'approved', familyId,
      approvedAt: admin.firestore.FieldValue.serverTimestamp() });
    return { deviceUid };
  });
});

exports.revokeDevice = onCall(options, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'parent'))
    throw new HttpsError('permission-denied', 'Parent sign-in required');
  const familyId = requireString(request.data?.familyId, 'familyId');
  const deviceUid = requireString(request.data?.deviceUid, 'deviceUid');
  const familyRef = await parentFamily(uid, familyId);
  const deviceRef = familyRef.collection('devices').doc(deviceUid);
  await db.runTransaction(async tx => {
    const device = await tx.get(deviceRef);
    if (!device.exists) throw new HttpsError('not-found', 'Device not found');
    tx.update(deviceRef, { revoked: true, approved: false,
      revokedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  return { revoked: true };
});

// Child pairing status requires a server-issued family-scoped lookup token.
// Do not implement an unscoped collection-group scan for device UIDs.

exports.getPairingStatus = onCall(options, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'child'))
    throw new HttpsError('permission-denied', 'Child session required');
  const code = requireString(request.data?.code, 'code', 8);
  if (!security.validCode(code)) throw new HttpsError('invalid-argument', 'Invalid code');
  const hash = security.codeHash(code);
  const pair = await db.doc('pairingRequests/' + hash).get();
  if (!pair.exists || pair.get('deviceUid') !== uid)
    throw new HttpsError('permission-denied', 'Not your pairing request');
  if (pair.get('expiresAt').toMillis() <= Date.now() && pair.get('status') === 'pending')
    return { status: 'expired' };
  if (pair.get('status') !== 'approved') return { status: pair.get('status') };
  const familyId = pair.get('familyId');
  const device = await db.doc('families/' + familyId + '/devices/' + uid).get();
  return { status: device.exists && device.get('approved') === true &&
    device.get('revoked') !== true ? 'approved' : 'revoked',
    familyId: device.exists && device.get('approved') === true &&
      device.get('revoked') !== true ? familyId : null };
});

// A device must revalidate its approval on every launch; local preferences
// never grant access. Offline validation fails closed.
exports.verifyDeviceAccess = onCall(options, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'child'))
    throw new HttpsError('permission-denied', 'Child session required');
  const familyId = requireString(request.data?.familyId, 'familyId');
  const device = await db.doc('families/' + familyId + '/devices/' + uid).get();
  return { approved: device.exists && security.approvedDevice(device.data()) };
});

exports.setLearningHintsEnabled = onCall(options, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'parent'))
    throw new HttpsError('permission-denied', 'Parent sign-in required');
  const familyId = requireString(request.data?.familyId, 'familyId');
  if (typeof request.data?.enabled !== 'boolean')
    throw new HttpsError('invalid-argument', 'enabled must be boolean');
  const familyRef = await parentFamily(uid, familyId);
  await familyRef.set({ learningHintsEnabled: request.data.enabled }, { merge: true });
  return { enabled: request.data.enabled };
});

exports.childLearningHint = onCall({
  ...options, secrets: [geminiKey], timeoutSeconds: 20,
}, async request => {
  const uid = uidOf(request);
  if (!security.providerAllowed(request.auth, 'child'))
    throw new HttpsError('permission-denied', 'Child session required');
  const familyId = requireString(request.data?.familyId, 'familyId');
  const topic = requireString(request.data?.topic, 'topic', 16);
  if (!['letters', 'numbers', 'colors'].includes(topic))
    throw new HttpsError('invalid-argument', 'Unsupported learning topic');
  const device = await db.doc('families/' + familyId + '/devices/' + uid).get();
  if (!device.exists || !security.approvedDevice(device.data()))
    throw new HttpsError('permission-denied', 'Parent approval required');
  const family = await db.doc('families/' + familyId).get();
  if (!family.exists || family.get('learningHintsEnabled') !== true)
    throw new HttpsError('permission-denied', 'Learning hints disabled by parent');
  const limitRef = db.doc('learningHintLimits/' + uid);
  await db.runTransaction(async tx => {
    const snap = await tx.get(limitRef);
    const now = Date.now();
    const last = snap.exists ? snap.get('windowStartedAt')?.toMillis() ?? 0 : 0;
    const count = now - last < 60 * 60 * 1000 ? snap.get('count') ?? 0 : 0;
    if (count >= 12) throw new HttpsError('resource-exhausted', 'Learning hint limit reached');
    tx.set(limitRef, { count: count + 1,
      windowStartedAt: admin.firestore.Timestamp.fromMillis(count === 0 ? now : last) });
  });
  const key = geminiKey.value();
  if (!key) throw new HttpsError('failed-precondition', 'Gemini is not configured');
  // No free-form prompts or identifying child data are forwarded to Gemini.
  const prompt = security.topicPrompt(topic);
  const response = await fetch(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    { method: 'POST', headers: { 'Content-Type': 'application/json',
        'x-goog-api-key': key },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 80, temperature: 0.3 } }),
      signal: AbortSignal.timeout(12000) });
  if (!response.ok) throw new HttpsError('unavailable', 'Learning helper unavailable');
  const data = await response.json();
  const hint = security.safeHint(data);
  if (!hint) throw new HttpsError('unavailable', 'No learning hint available');
  return { hint };
});
