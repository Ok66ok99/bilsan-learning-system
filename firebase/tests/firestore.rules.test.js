const { initializeTestEnvironment, assertFails } = require('@firebase/rules-unit-testing');
const fs = require('node:fs');
const path = require('node:path');

let env;
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-bilsan-security-test',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
  });
});
afterAll(async () => { if (env) await env.cleanup(); });

test('unauthenticated clients cannot read or write', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(db.doc('families/private/children/bilsan').get());
  await assertFails(db.doc('families/private/children/bilsan').set({ name: 'test' }));
});

test('authenticated parent cannot bypass fail-closed rules', async () => {
  const db = env.authenticatedContext('parent-one').firestore();
  await assertFails(db.doc('families/one').get());
  await assertFails(db.doc('families/one').set({ owner: 'parent-one' }));
});

test('another family and unapproved child cannot read or write', async () => {
  for (const uid of ['foreign-parent', 'unapproved-child']) {
    const db = env.authenticatedContext(uid).firestore();
    await assertFails(db.doc('families/one/lessons/lesson-1').get());
    await assertFails(db.doc('families/one/lessons/lesson-1').set({ enabled: true }));
  }
});
