'use strict';
// Integration tests run against the Firestore emulator, never production.
const test = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const fft = require('firebase-functions-test')({projectId:'demo-bilsan-security-test'});
const fn = require('../index');
const db = admin.firestore();
const parent = {auth:{uid:'parent-a',token:{firebase:{sign_in_provider:'password'}}}};
const other = {auth:{uid:'parent-b',token:{firebase:{sign_in_provider:'password'}}}};
const child = {auth:{uid:'child-a',token:{firebase:{sign_in_provider:'anonymous'}}}};
const call = (name, data, identity) => fft.wrap(fn[name])({data,...identity});

test('complete pairing, unauthorized parent, revocation, and Gemini disabled', async () => {
  const family = await call('createFamily',{},parent);
  assert.ok(family.familyId);
  const foreign = await call('createFamily',{},other);
  assert.notEqual(family.familyId,foreign.familyId);
  await assert.rejects(call('setLearningHintsEnabled',
    {familyId:family.familyId,enabled:true},other), /permission-denied|Not family owner/);
  const issued = await call('requestPairing',{},child);
  assert.match(issued.code,/^\d{8}$/);
  const before = await call('verifyDeviceAccess',{familyId:family.familyId},child);
  assert.equal(before.approved,false);
  await assert.rejects(call('approvePairing',
    {familyId:family.familyId,code:'00000000'},parent));
  const attempt = await db.doc('pairingAttempts/parent-a').get();
  assert.equal(attempt.get('count'),1,'invalid code must consume attempt');
  await assert.rejects(call('approvePairing',
    {familyId:foreign.familyId,code:issued.code},parent));
  await call('approvePairing',{familyId:family.familyId,code:issued.code},parent);
  const after = await call('verifyDeviceAccess',{familyId:family.familyId},child);
  assert.equal(after.approved,true);
  const status = await call('getPairingStatus',{code:issued.code},child);
  assert.equal(status.status,'approved');
  assert.equal(status.familyId,family.familyId);
  await assert.rejects(call('childLearningHint',
    {familyId:family.familyId,topic:'letters'},child), /permission-denied|disabled/);
  await call('setLearningHintsEnabled',{familyId:family.familyId,enabled:true},parent);
  await call('setLearningHintsEnabled',{familyId:family.familyId,enabled:false},parent);
  await assert.rejects(call('childLearningHint',
    {familyId:family.familyId,topic:'letters'},child), /permission-denied|disabled/);
  await call('revokeDevice',{familyId:family.familyId,deviceUid:'child-a'},parent);
  const revoked = await call('verifyDeviceAccess',{familyId:family.familyId},child);
  assert.equal(revoked.approved,false);
  const revokedStatus = await call('getPairingStatus',{code:issued.code},child);
  assert.equal(revokedStatus.status,'revoked');
  await assert.rejects(call('childLearningHint',
    {familyId:family.familyId,topic:'letters'},child), /permission-denied|approval/);
  await assert.rejects(call('revokeDevice',
    {familyId:family.familyId,deviceUid:'child-a'},other));
});
test.after(() => fft.cleanup());
