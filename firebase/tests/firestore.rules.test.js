const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('node:fs');
const path = require('node:path');
const { serverTimestamp } = require('firebase/firestore');

let env;
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-bilsan-security-test',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('families/family-a').set({ ownerUid: 'parent-a' });
    await db.doc('families/family-b').set({ ownerUid: 'parent-b' });
    await db.doc('families/family-a/devices/child-a').set({ approved: true, revoked: false });
    await db.doc('families/family-a/devices/child-revoked').set({ approved: true, revoked: true });
    await db.doc('families/family-a/lessons/one').set({ title: 'Arabic' });
    await db.doc('families/family-b/lessons/one').set({ title: 'Private' });
  });
});
afterAll(async () => { if (env) await env.cleanup(); });

test('anonymous and unrelated accounts cannot access families', async () => {
  for (const db of [env.unauthenticatedContext().firestore(), env.authenticatedContext('stranger').firestore()]) {
    await assertFails(db.doc('families/family-a').get());
    await assertFails(db.doc('families/family-a/lessons/one').get());
    await assertFails(db.doc('families/family-a/lessons/one').set({ title: 'tamper' }));
  }
});

test('parent reads own family and lessons but cannot grant itself device permissions', async () => {
  const db = env.authenticatedContext('parent-a').firestore();
  await assertSucceeds(db.doc('families/family-a').get());
  await assertSucceeds(db.doc('families/family-a/lessons/one').get());
  await assertSucceeds(db.doc('families/family-a/devices/child-a').get());
  await assertFails(db.doc('families/family-b').get());
  await assertFails(db.doc('families/family-a').update({ ownerUid: 'stranger' }));
  await assertFails(db.doc('families/family-a/devices/stranger').set({ approved: true }));
});

test('approved child only reads assigned family; cannot modify lessons or devices', async () => {
  const db = env.authenticatedContext('child-a').firestore();
  await assertSucceeds(db.doc('families/family-a/lessons/one').get());
  await assertFails(db.doc('families/family-b/lessons/one').get());
  await assertFails(db.doc('families/family-a').get());
  await assertFails(db.doc('families/family-a/devices/child-a').update({ revoked: false }));
  await assertFails(db.doc('families/family-a/lessons/one').set({ title: 'tamper' }));
});

test('unapproved and revoked children are denied', async () => {
  for (const uid of ['child-unapproved', 'child-revoked']) {
    const db = env.authenticatedContext(uid).firestore();
    await assertFails(db.doc('families/family-a/lessons/one').get());
    await assertFails(db.doc('families/family-a/progress/' + uid).set({
      deviceUid: uid, completedCount: 1, updatedAt: serverTimestamp(),
    }));
  }
});

test('approved child may write only own validated progress', async () => {
  const db = env.authenticatedContext('child-a').firestore();
  const own = db.doc('families/family-a/progress/child-a');
  await assertSucceeds(own.set({ deviceUid: 'child-a', completedCount: 1, updatedAt: serverTimestamp() }));
  await assertSucceeds(own.update({ completedCount: 2, updatedAt: serverTimestamp() }));
  await assertFails(own.update({ completedCount: 0, updatedAt: serverTimestamp() }));
  await assertFails(own.update({ completedCount: 3, admin: true, updatedAt: serverTimestamp() }));
  await assertFails(db.doc('families/family-a/progress/another-child').set({
    deviceUid: 'another-child', completedCount: 1, updatedAt: serverTimestamp(),
  }));
  await assertFails(own.delete());
});

test('queued progress is rejected after revocation, and another family cannot receive it', async () => {
  const child = env.authenticatedContext('child-a').firestore();
  const own = child.doc('families/family-a/progress/child-a');
  await assertSucceeds(own.set({
    deviceUid: 'child-a', completedCount: 3, updatedAt: serverTimestamp(),
  }));
  // Offline progress queued locally; no write until connectivity resumes.
  await env.withSecurityRulesDisabled(async context => {
    await context.firestore().doc('families/family-a/devices/child-a')
      .update({ approved: false, revoked: true });
  });
  await assertFails(own.update({
    completedCount: 4, updatedAt: serverTimestamp(),
  }));
  await assertFails(child.doc('families/family-b/progress/child-a').set({
    deviceUid: 'child-a', completedCount: 4, updatedAt: serverTimestamp(),
  }));
  const parent = env.authenticatedContext('parent-a').firestore();
  const persisted = await assertSucceeds(parent.doc('families/family-a/progress/child-a').get());
  expect(persisted.data().completedCount).toBe(3);
});

test('approved child can resume a queued monotonic progress update after reconnect', async () => {
  const child = env.authenticatedContext('child-a').firestore();
  const ref = child.doc('families/family-a/progress/child-a');
  await assertSucceeds(ref.set({
    deviceUid: 'child-a', completedCount: 2, updatedAt: serverTimestamp(),
  }));
  // Simulate a reconnect flush using a new request after the first commit.
  await assertSucceeds(ref.set({
    deviceUid: 'child-a', completedCount: 5, updatedAt: serverTimestamp(),
  }, { merge: true }));
  const parent = env.authenticatedContext('parent-a').firestore();
  const stored = await assertSucceeds(parent.doc('families/family-a/progress/child-a').get());
  expect(stored.data().completedCount).toBe(5);
  await assertFails(ref.set({
    deviceUid: 'child-a', completedCount: 1, updatedAt: serverTimestamp(),
  }, { merge: true }));
});
