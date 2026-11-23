'use strict';

const crypto = require('node:crypto');

const topics = Object.freeze({
  letters: 'الحروف العربية',
  numbers: 'الجمع والعد من 0 إلى 20',
  colors: 'الألوان الأساسية',
});

function providerAllowed(auth, role) {
  return Boolean(auth?.uid && auth.token?.firebase?.sign_in_provider ===
    (role === 'parent' ? 'password' : 'anonymous'));
}
function validCode(code) {
  return typeof code === 'string' && /^\d{8}$/.test(code);
}
function codeHash(code) {
  if (!validCode(code)) throw new Error('Invalid pairing code');
  return crypto.createHash('sha256').update(code).digest('hex');
}
function attemptWindow(previous, now, windowMs, limit) {
  const last = previous?.windowStartedAt ?? 0;
  const count = now - last >= 0 && now - last < windowMs ? previous.count ?? 0 : 0;
  return { allowed: count < limit, count: count + 1,
    windowStartedAt: count === 0 ? now : last };
}
function pairingValid(pair, now) {
  return Boolean(pair && pair.status === 'pending' && pair.expiresAt > now &&
    typeof pair.deviceUid === 'string' && pair.deviceUid.length > 0);
}
function approvedDevice(device) {
  return Boolean(device && device.approved === true && device.revoked !== true);
}
function topicPrompt(topic) {
  if (!Object.hasOwn(topics, topic)) throw new Error('Unsupported topic');
  return 'اكتب تلميحاً تعليمياً واحداً بالعربية الفصحى لطفل عمره 6 سنوات عن ' +
    topics[topic] + '. بحد أقصى 18 كلمة، بدون روابط أو أسئلة شخصية.';
}
function safeHint(data) {
  const hint = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof hint !== 'string' || !hint.trim()) return null;
  const clean = hint.replace(/https?:\/\/\S+/gi, '').replace(/\s+/g, ' ').trim();
  return clean ? clean.slice(0, 160) : null;
}
module.exports = { providerAllowed, validCode, codeHash, attemptWindow,
  pairingValid, approvedDevice, topicPrompt, safeHint };
