'use strict';
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const crypto = require('node:crypto');
admin.initializeApp();
const db = admin.firestore();
const region = 'us-central1';
const options = { region, enforceAppCheck: true, maxInstances: 10 };

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
  if (request.auth.token.firebase?.sign_in_provider !== 'password')
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
  if (!request.auth.token.firebase?.sign_in_provider ||
      request.auth.token.firebase.sign_in_provider !== 'anonymous')
    throw new HttpsError('permission-denied', 'Child anonymous sign-in required');
  const code = crypto.randomInt(10000000, 99999999).toString();
  const hash = crypto.createHash('sha256').update(code).digest('hex');
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
  if (request.auth.token.firebase?.sign_in_provider !== 'password')
    throw new HttpsError('permission-denied', 'Parent sign-in required');
  const familyId = requireString(request.data?.familyId, 'familyId');
  const code = requireString(request.data?.code, 'code', 8);
  if (!/^\d{8}$/.test(code)) throw new HttpsError('invalid-argument', 'Invalid code');
  const familyRef = await parentFamily(uid, familyId);
  const hash = crypto.createHash('sha256').update(code).digest('hex');
  const pairRef = db.doc('pairingRequests/' + hash);
  const attemptsRef = db.doc('pairingAttempts/' + uid);
  return db.runTransaction(async tx => {
    const attempts = await tx.get(attemptsRef);
    const now = Date.now();
    const last = attempts.exists ? attempts.get('windowStartedAt')?.toMillis() ?? 0 : 0;
    const count = now - last < 10 * 60 * 1000 ? attempts.get('count') ?? 0 : 0;
    if (count >= 5) throw new HttpsError('resource-exhausted', 'Try again later');
    const pair = await tx.get(pairRef);
    tx.set(attemptsRef, { count: count + 1,
      windowStartedAt: admin.firestore.Timestamp.fromMillis(
        count === 0 ? now : last) });
    if (!pair.exists || pair.get('status') !== 'pending' ||
        pair.get('expiresAt').toMillis() <= Date.now())
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
  if (request.auth.token.firebase?.sign_in_provider !== 'password')
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
  if (request.auth.token.firebase?.sign_in_provider !== 'anonymous')
    throw new HttpsError('permission-denied', 'Child session required');
  const code = requireString(request.data?.code, 'code', 8);
  if (!/^\d{8}$/.test(code)) throw new HttpsError('invalid-argument', 'Invalid code');
  const hash = crypto.createHash('sha256').update(code).digest('hex');
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
