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

test('Firebase client queues offline progress and commits it after network returns', async () => {
  const db = env.authenticatedContext('child-a').firestore();
  const ref = db.doc('families/family-a/progress/child-a');
  await db.disableNetwork();
  let acknowledged = false;
  const write = ref.set({
    deviceUid: 'child-a', completedCount: 9, updatedAt: serverTimestamp(),
  }).then(() => { acknowledged = true; });
  // The write must not be acknowledged by the emulator while disconnected.
  await new Promise(resolve => setTimeout(resolve, 200));
  expect(acknowledged).toBe(false);
  await db.enableNetwork();
  await Promise.race([
    write,
    new Promise((_, reject) => setTimeout(
      () => reject(new Error('Firestore offline write did not sync after reconnect')), 8000)),
  ]);
  expect(acknowledged).toBe(true);
  const parent = env.authenticatedContext('parent-a').firestore();
  const saved = await parent.doc('families/family-a/progress/child-a').get();
  expect(saved.data().completedCount).toBe(9);
});

test('offline Firestore client cannot commit queued progress after parent revokes device', async () => {
  const child = env.authenticatedContext('child-a').firestore();
  const progress = child.doc('families/family-a/progress/child-a');
  await assertSucceeds(progress.set({
    deviceUid: 'child-a', completedCount: 2, updatedAt: serverTimestamp(),
  }));
  await child.disableNetwork();
  // Attach both success and rejection handlers immediately: an expected
  // permission-denied response must not become an unhandled rejection.
  let settled = false;
  const pending = progress.set({
    deviceUid: 'child-a', completedCount: 7, updatedAt: serverTimestamp(),
  }).then(
    () => { settled = true; return 'accepted'; },
    (error) => { settled = true; return error.code || 'rejected'; },
  );
  await new Promise(resolve => setTimeout(resolve, 200));
  expect(settled).toBe(false);
  await env.withSecurityRulesDisabled(async context => {
    await context.firestore().doc('families/family-a/devices/child-a')
      .update({ approved: false, revoked: true });
  });
  await child.enableNetwork();
  const outcome = await Promise.race([
    pending,
    new Promise((_, reject) => setTimeout(
      () => reject(new Error('Offline revoked write did not settle')), 8000)),
  ]);
  expect(outcome).not.toBe('accepted');
  expect(outcome).toMatch(/permission-denied/);
  const parent = env.authenticatedContext('parent-a').firestore();
  const saved = await parent.doc('families/family-a/progress/child-a').get();
  expect(saved.data().completedCount).toBe(2);
  await assertFails(child.doc('families/family-b/progress/child-a').set({
    deviceUid: 'child-a', completedCount: 7, updatedAt: serverTimestamp(),
  }));
});

test('approved children cannot read another child progress or list family progress', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await context.firestore().doc('families/family-a/devices/child-b')
      .set({ approved: true, revoked: false });
    await context.firestore().doc('families/family-a/progress/child-b')
      .set({ deviceUid: 'child-b', completedCount: 4, updatedAt: new Date() });
  });
  const child = env.authenticatedContext('child-a').firestore();
  await assertFails(child.doc('families/family-a/progress/child-b').get());
  await assertFails(child.collection('families/family-a/progress').get());
  const parent = env.authenticatedContext('parent-a').firestore();
  await assertSucceeds(parent.doc('families/family-a/progress/child-b').get());
  await assertSucceeds(parent.collection('families/family-a/progress').get());
});

test('child drawing is saved and readable by its own parent, but not other families', async () => {
  const child = env.authenticatedContext('child-a').firestore();
  const drawing = child.doc('families/family-a/drawings/child-a');
  const payload = {
    deviceUid: 'child-a',
    items: [{ id: 'flower-1', createdAt: '2026-11-24T00:00:00Z',
      strokes: [[[0.1, 0.2], [0.3, 0.4]]] }],
    updatedAt: serverTimestamp(),
  };
  await assertSucceeds(drawing.set(payload));
  const parent = env.authenticatedContext('parent-a').firestore();
  const saved = await assertSucceeds(parent.doc('families/family-a/drawings/child-a').get());
  expect(saved.data().items[0].id).toBe('flower-1');
  await assertSucceeds(parent.collection('families/family-a/drawings').get());
  const stranger = env.authenticatedContext('parent-b').firestore();
  await assertFails(stranger.doc('families/family-a/drawings/child-a').get());
  await assertFails(stranger.collection('families/family-a/drawings').get());
});

test('drawing writes cannot impersonate another child or exceed archive limit', async () => {
  const child = env.authenticatedContext('child-a').firestore();
  const base = { deviceUid: 'child-a', items: [], updatedAt: serverTimestamp() };
  await assertFails(child.doc('families/family-a/drawings/child-b').set(base));
  await assertFails(child.doc('families/family-b/drawings/child-a').set(base));
  await assertFails(child.doc('families/family-a/drawings/child-a').set({
    ...base, deviceUid: 'child-b',
  }));
  await assertFails(child.doc('families/family-a/drawings/child-a').set({
    ...base, items: Array.from({ length: 21 }, (_, i) => ({ id: String(i) })),
  }));
  await assertFails(child.doc('families/family-a/drawings/child-a').set({
    ...base, ownerUid: 'parent-a',
  }));
  await assertFails(child.collection('families/family-a/drawings').get());
});

test('revocation prevents drawing upload and access, but parent keeps prior drawing', async () => {
  const child = env.authenticatedContext('child-a').firestore();
  const drawing = child.doc('families/family-a/drawings/child-a');
  await assertSucceeds(drawing.set({
    deviceUid: 'child-a', items: [{ id: 'before-revoke' }],
    updatedAt: serverTimestamp(),
  }));
  await env.withSecurityRulesDisabled(async context => {
    await context.firestore().doc('families/family-a/devices/child-a')
      .update({ approved: false, revoked: true });
  });
  await assertFails(drawing.set({
    deviceUid: 'child-a', items: [{ id: 'after-revoke' }],
    updatedAt: serverTimestamp(),
  }));
  await assertFails(drawing.get());
  const parent = env.authenticatedContext('parent-a').firestore();
  const saved = await assertSucceeds(parent.doc('families/family-a/drawings/child-a').get());
  expect(saved.data().items[0].id).toBe('before-revoke');
});
