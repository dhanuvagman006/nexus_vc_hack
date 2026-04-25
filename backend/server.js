const express = require('express');
const cors = require('cors');
const os = require('os');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3005;

app.use(cors());
app.use(express.json());

// ─── In-Memory Data Store ─────────────────────────────────────────────────────
// No hardcoded seed users — all users are auto-created on first transaction.
const users = {};
const transactions = [];          // All processed transactions
const processedTxnIds = new Set(); // For O(1) idempotency lookup (capped at 10k)
const logs = [];                  // Structured log entries (capped at 500)

// ─── Logging Utility ──────────────────────────────────────────────────────────
function log(action, details, result) {
  const entry = {
    timestamp: new Date().toISOString(),
    action,
    details,
    result,
  };
  if (logs.length >= 500) logs.shift(); // rolling cap
  logs.push(entry);
  console.log(`[${entry.timestamp}] ${action} | ${JSON.stringify(details)} → ${result}`);
}

// ─── Auto-create or fetch user ────────────────────────────────────────────────
function getOrCreateUser(userId, displayName) {
  if (!users[userId]) {
    // If displayName is missing or is just the userId, fallback to "Trader" or "BluePay User"
    // as per user request to avoid numbers-as-names.
    let name = (displayName && displayName !== userId) ? displayName : 'Trader';
    
    users[userId] = {
      userId,
      name,
      balance: 1000.00,
      createdAt: new Date().toISOString(),
    };
    log('AUTO_CREATE_USER', { userId, name: users[userId].name }, 'CREATED');
  }
  return users[userId];
}

// ─── Idempotency Set Cap ──────────────────────────────────────────────────────
function addProcessedTxn(txnId) {
  if (processedTxnIds.size >= 10000) {
    // Remove the oldest entry (Sets preserve insertion order)
    const oldest = processedTxnIds.values().next().value;
    processedTxnIds.delete(oldest);
  }
  processedTxnIds.add(txnId);
}

// ─── Core Transaction Processor ───────────────────────────────────────────────
// Shared by /transaction, /sync, and /sms endpoints
function processTransaction(txn) {
  const { txn_id, senderId, senderName, receiverId, receiverName, amount } = txn;

  // 1. Idempotency — reject duplicate txn_id
  if (processedTxnIds.has(txn_id)) {
    log('TRANSACTION', { txn_id }, 'DUPLICATE');
    return {
      statusCode: 200,
      body: {
        status: 'duplicate',
        txn_id,
        message: 'Transaction already processed',
      },
    };
  }

  // 2. Auto-create sender and receiver if not found
  const sender = getOrCreateUser(senderId, senderName);
  const receiver = getOrCreateUser(receiverId, receiverName);

  // 3. Validate amount
  if (typeof amount !== 'number' || isNaN(amount) || amount <= 0) {
    log('TRANSACTION', { txn_id, amount }, 'FAILED — invalid amount');
    return {
      statusCode: 400,
      body: {
        status: 'failed',
        txn_id,
        message: 'Amount must be a positive number',
      },
    };
  }

  // 4. Insufficient funds check
  if (sender.balance < amount) {
    log('TRANSACTION', { txn_id, senderId, balance: sender.balance, amount }, 'FAILED — insufficient funds');
    return {
      statusCode: 400,
      body: {
        status: 'failed',
        txn_id,
        message: `Insufficient funds. ${sender.name} has ₹${sender.balance.toFixed(2)} but tried to send ₹${amount.toFixed(2)}`,
        senderBalance: sender.balance,
      },
    };
  }

  // 5. Process — deduct from sender, credit receiver
  sender.balance = parseFloat((sender.balance - amount).toFixed(2));
  receiver.balance = parseFloat((receiver.balance + amount).toFixed(2));

  // 6. Record
  const record = {
    txn_id,
    senderId,
    senderName: sender.name,
    receiverId,
    receiverName: receiver.name,
    amount,
    timestamp: new Date().toISOString(),
    status: 'success',
  };
  transactions.push(record);
  addProcessedTxn(txn_id);

  log('TRANSACTION', { txn_id, senderId, receiverId, amount }, 'SUCCESS');

  return {
    statusCode: 200,
    body: {
      status: 'success',
      txn_id,
      senderId,
      senderName: sender.name,
      receiverId,
      receiverName: receiver.name,
      amount,
      senderBalance: sender.balance,
      receiverBalance: receiver.balance,
      timestamp: record.timestamp,
    },
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ENDPOINTS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── GET /users ───────────────────────────────────────────────────────────────
app.get('/users', (_req, res) => {
  log('GET_USERS', {}, 'OK');
  res.json({ count: Object.keys(users).length, users: Object.values(users) });
});

// ─── GET /users/:userId ───────────────────────────────────────────────────────
app.get('/users/:userId', (req, res) => {
  const user = users[req.params.userId];
  if (!user) {
    log('GET_USER', { userId: req.params.userId }, 'NOT FOUND');
    return res.status(404).json({ status: 'failed', message: 'User not found' });
  }
  log('GET_USER', { userId: req.params.userId }, 'OK');
  res.json({ user });
});

// ─── POST /transaction ───────────────────────────────────────────────────────
app.post('/transaction', (req, res) => {
  const { txn_id, senderId, senderName, receiverId, receiverName, amount } = req.body;

  if (!txn_id || !senderId || !receiverId || amount === undefined) {
    log('TRANSACTION', req.body, 'FAILED — missing fields');
    return res.status(400).json({
      status: 'failed',
      message: 'Missing required fields: txn_id, senderId, receiverId, amount',
    });
  }

  const result = processTransaction({ txn_id, senderId, senderName, receiverId, receiverName, amount });
  res.status(result.statusCode).json(result.body);
});

// ─── GET /transactions ────────────────────────────────────────────────────────
// All transactions, sorted newest-first
app.get('/transactions', (_req, res) => {
  log('GET_ALL_TRANSACTIONS', {}, 'OK');
  res.json({
    count: transactions.length,
    transactions: [...transactions].reverse(),
  });
});

// ─── GET /transactions/:userId ────────────────────────────────────────────────
app.get('/transactions/:userId', (req, res) => {
  const { userId } = req.params;
  const userTxns = transactions.filter(
    (t) => t.senderId === userId || t.receiverId === userId
  );
  // auto-create so we always return something useful even if user isn't loaded yet
  const user = getOrCreateUser(userId);
  log('GET_HISTORY', { userId, count: userTxns.length }, 'OK');
  res.json({
    userId,
    name: user.name,
    balance: user.balance,
    transactions: [...userTxns].reverse(),
  });
});

// ─── POST /sync ───────────────────────────────────────────────────────────────
// Batch process an array of transactions (from offline queue)
app.post('/sync', (req, res) => {
  const { transactions: txnBatch } = req.body;

  if (!Array.isArray(txnBatch)) {
    log('SYNC', {}, 'FAILED — invalid input');
    return res.status(400).json({
      status: 'failed',
      message: 'Expected { "transactions": [...] }',
    });
  }

  if (txnBatch.length === 0) {
    log('SYNC', {}, 'EMPTY BATCH');
    return res.json({ status: 'success', results: [], message: 'No transactions to process' });
  }

  log('SYNC', { count: txnBatch.length }, 'PROCESSING');

  const results = txnBatch.map((txn, index) => {
    if (!txn.txn_id || !txn.senderId || !txn.receiverId || txn.amount === undefined) {
      log('SYNC_ITEM', { index }, 'FAILED — missing fields');
      return { index, txn_id: txn.txn_id || null, status: 'failed', message: 'Missing required fields' };
    }
    const result = processTransaction(txn);
    return { index, ...result.body };
  });

  const successCount = results.filter((r) => r.status === 'success').length;
  const failedCount = results.filter((r) => r.status === 'failed').length;
  const duplicateCount = results.filter((r) => r.status === 'duplicate').length;

  log('SYNC', { total: txnBatch.length, successCount, failedCount, duplicateCount }, 'COMPLETE');

  res.json({
    status: 'success',
    summary: { total: txnBatch.length, successful: successCount, failed: failedCount, duplicates: duplicateCount },
    results,
  });
});

// ─── POST /sms ────────────────────────────────────────────────────────────────
// Real SMS format from the Flutter app:
//   PAY <amount> <senderId> <receiverId> <txn_id>
//
// senderId / receiverId may contain spaces (e.g. "Alexey G.").
// Strategy: the txn_id is ALWAYS the last token (no spaces), amount is always
// the first numeric token after "PAY", and the two IDs are everything in between.
// We identify the txn_id (last word), amount (word index 1), then split the
// middle into senderId and receiverId using the separator " " after trimming.
//
// Format enforced by Flutter: "PAY {amount} {senderId} {receiverId} {txnId}"
// where senderId and receiverId are single words (usernames trimmed by the app).
app.post('/sms', (req, res) => {
  const { message } = req.body;

  if (!message || typeof message !== 'string') {
    log('SMS', {}, 'FAILED — no message');
    return res.status(400).json({
      status: 'failed',
      message: 'Expected { "message": "PAY <amount> <senderId> <receiverId> <txn_id>" }',
    });
  }

  const raw = message.trim();
  const parts = raw.split(/\s+/);

  // Minimum: PAY + amount + senderId + receiverId + txnId = 5 tokens
  if (parts.length < 5 || parts[0].toUpperCase() !== 'PAY') {
    log('SMS', { message: raw }, 'FAILED — invalid format');
    return res.status(400).json({
      status: 'failed',
      message: 'Invalid SMS format. Expected: "PAY <amount> <senderId> <receiverId> <txn_id>"',
      received: raw,
    });
  }

  const amount = parseFloat(parts[1]);
  const txn_id = parts[parts.length - 1];         // last token
  const senderId = parts[2];                         // 3rd token
  // Everything between senderId and txn_id is the receiverId (handles spaces)
  const receiverId = parts.slice(3, parts.length - 1).join(' ');

  if (isNaN(amount) || amount <= 0) {
    log('SMS', { message: raw }, 'FAILED — invalid amount');
    return res.status(400).json({
      status: 'failed',
      message: `Invalid amount '${parts[1]}' in SMS`,
    });
  }

  if (!receiverId) {
    log('SMS', { message: raw }, 'FAILED — missing receiverId');
    return res.status(400).json({
      status: 'failed',
      message: 'Could not parse receiverId from SMS',
      received: raw,
    });
  }

  const txn = { txn_id, senderId, receiverId, amount };
  log('SMS', { parsed: txn }, 'PARSED');

  const result = processTransaction(txn);
  res.status(result.statusCode).json({ ...result.body, parsedFrom: raw });
});

// ─── POST /relay ──────────────────────────────────────────────────────────────
// Called by the Android relay app on phone 6360139965.
// The app receives an SMS whose body is a JSON string, parses it, and POSTs
// the exact same JSON to this endpoint.
//
// Expected body (same shape as /transaction):
//   {
//     "txn_id":    "TXN17430...",
//     "senderId":  "9876543210",   ← always sender's phone number
//     "senderName": "Alexey G.",  ← optional display name
//     "receiverId": "6360139965",  ← always receiver's phone number
//     "amount":    500
//   }
//
// Optional senderName / receiverName fields are used to set display names.
app.post('/relay', (req, res) => {
  const { txn_id, senderId, senderName, receiverId, receiverName, amount } = req.body;

  // Validate required fields
  if (!txn_id || !senderId || !receiverId || amount === undefined) {
    log('RELAY', req.body, 'FAILED — missing fields');
    return res.status(400).json({
      status: 'failed',
      message: 'Missing required fields: txn_id, senderId, receiverId, amount',
      expected: { txn_id: 'string', senderId: 'string', receiverId: 'string', amount: 'number' },
    });
  }

  const parsedAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
  if (isNaN(parsedAmount) || parsedAmount <= 0) {
    log('RELAY', req.body, 'FAILED — invalid amount');
    return res.status(400).json({
      status: 'failed',
      message: `Invalid amount: ${amount}`,
    });
  }

  log('RELAY', { txn_id, senderId, receiverId, amount: parsedAmount }, 'RECEIVED FROM RELAY APP');

  const result = processTransaction({
    txn_id,
    senderId,
    senderName: senderName || senderId,
    receiverId,
    receiverName: receiverName || receiverId,
    amount: parsedAmount,
  });

  res.status(result.statusCode).json({ ...result.body, relayedAt: new Date().toISOString() });
});

// ─── POST /reset ──────────────────────────────────────────────────────────────
// Demo helper — wipe all users, transactions and logs for a clean run
app.post('/reset', (_req, res) => {
  Object.keys(users).forEach((k) => delete users[k]);
  transactions.length = 0;
  processedTxnIds.clear();
  logs.length = 0;
  log('RESET', {}, 'ALL DATA CLEARED');
  console.log('\n🔄  Server state reset — fresh start\n');
  res.json({ status: 'success', message: 'All data cleared. Ready for a fresh demo.' });
});

// ─── GET /logs ────────────────────────────────────────────────────────────────
app.get('/logs', (_req, res) => {
  res.json({ count: logs.length, logs: [...logs].reverse() });
});

// ─── GET /status ──────────────────────────────────────────────────────────────
app.get('/status', (_req, res) => {
  res.json({
    uptime: process.uptime(),
    users: Object.keys(users).length,
    transactions: transactions.length,
    pendingTxnIds: processedTxnIds.size,
    logs: logs.length,
  });
});

// ─── Global Error Handler ─────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  log('ERROR', { message: err.message }, 'INTERNAL SERVER ERROR');
  res.status(500).json({ status: 'error', message: 'Internal server error' });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  const nets = os.networkInterfaces();
  const localIPs = [];
  for (const iface of Object.values(nets)) {
    for (const net of iface) {
      if (net.family === 'IPv4' && !net.internal) localIPs.push(net.address);
    }
  }

  console.log(`\n🏦  BluePay Backend  →  http://localhost:${PORT}`);
  if (localIPs.length > 0) {
    console.log(`\n🌐  Network access (phones / other devices):`);
    localIPs.forEach((ip) => console.log(`   ➜  http://${ip}:${PORT}`));
  }

  console.log(`\n📋  Endpoints:`);
  console.log(`   GET    /status                 — Server health`);
  console.log(`   GET    /users                  — All users`);
  console.log(`   GET    /users/:id              — Single user`);
  console.log(`   POST   /transaction            — Process transaction`);
  console.log(`   GET    /transactions           — All transactions`);
  console.log(`   GET    /transactions/:userId   — User history`);
  console.log(`   POST   /sync                   — Batch sync`);
  console.log(`   POST   /relay                  — ✅ Android relay app POSTs here (JSON SMS)`);
  console.log(`   POST   /sms                    — SMS text simulation (legacy)`);
  console.log(`   POST   /reset                  — ⚠ Reset all data (demo only)`);
  console.log(`   GET    /logs                   — Server logs`);
  console.log(`\n✨  No seeded users — all users auto-created on first transaction.\n`);
});
