const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3005;

app.use(cors());
app.use(express.json());

// ─── In-Memory Data Store ─────────────────────────────────────────────────────
const users = {
  user1: { userId: 'dhanush', name: 'Alexey G.', balance: 1000 },
  user2: { userId: 'allen', name: 'Priya S.', balance: 1000 },
  user3: { userId: 'karthik', name: 'Jordan K.', balance: 1000 },
};

const transactions = [];         // All processed transactions
const processedTxnIds = new Set(); // For O(1) idempotency lookup
const logs = [];                  // Structured log entries

// ─── Logging Utility ──────────────────────────────────────────────────────────
function log(action, details, result) {
  const entry = {
    timestamp: new Date().toISOString(),
    action,
    details,
    result,
  };
  logs.push(entry);
  console.log(`[${entry.timestamp}] ${action} | ${JSON.stringify(details)} → ${result}`);
}

// ─── Core Transaction Processor ───────────────────────────────────────────────
// Shared by /transaction, /sync, and /sms endpoints
function processTransaction(txn) {
  const { txn_id, senderId, receiverId, amount } = txn;

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

  // 2. Validate sender exists
  if (!users[senderId]) {
    log('TRANSACTION', { txn_id, senderId }, 'FAILED — sender not found');
    return {
      statusCode: 404,
      body: {
        status: 'failed',
        txn_id,
        message: `Sender '${senderId}' not found`,
      },
    };
  }

  // 3. Validate receiver exists
  if (!users[receiverId]) {
    log('TRANSACTION', { txn_id, receiverId }, 'FAILED — receiver not found');
    return {
      statusCode: 404,
      body: {
        status: 'failed',
        txn_id,
        message: `Receiver '${receiverId}' not found`,
      },
    };
  }

  // 4. Validate amount
  if (typeof amount !== 'number' || amount <= 0) {
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

  // 5. ★ Insufficient funds — DON'T allow the transaction ★
  if (users[senderId].balance < amount) {
    log('TRANSACTION', { txn_id, senderId, balance: users[senderId].balance, amount }, 'FAILED — insufficient funds');
    return {
      statusCode: 400,
      body: {
        status: 'failed',
        txn_id,
        message: `Insufficient funds. ${users[senderId].name} has ₹${users[senderId].balance.toFixed(2)} but tried to send ₹${amount.toFixed(2)}`,
        senderBalance: users[senderId].balance,
      },
    };
  }

  // 6. Process — deduct from sender, add to receiver
  users[senderId].balance -= amount;
  users[receiverId].balance += amount;

  // 7. Record the transaction
  const record = {
    txn_id,
    senderId,
    senderName: users[senderId].name,
    receiverId,
    receiverName: users[receiverId].name,
    amount,
    timestamp: new Date().toISOString(),
    status: 'success',
  };
  transactions.push(record);
  processedTxnIds.add(txn_id);

  log('TRANSACTION', { txn_id, senderId, receiverId, amount }, 'SUCCESS');

  return {
    statusCode: 200,
    body: {
      status: 'success',
      txn_id,
      senderId,
      receiverId,
      amount,
      senderBalance: users[senderId].balance,
      receiverBalance: users[receiverId].balance,
      timestamp: record.timestamp,
    },
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ENDPOINTS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── GET /users ───────────────────────────────────────────────────────────────
// List all users and balances
app.get('/users', (_req, res) => {
  log('GET_USERS', {}, 'OK');
  res.json({ users: Object.values(users) });
});

// ─── GET /users/:userId ───────────────────────────────────────────────────────
// Get single user details
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
// Process a single transaction (idempotent)
app.post('/transaction', (req, res) => {
  const { txn_id, senderId, receiverId, amount } = req.body;

  // Request validation
  if (!txn_id || !senderId || !receiverId || amount === undefined) {
    log('TRANSACTION', req.body, 'FAILED — missing fields');
    return res.status(400).json({
      status: 'failed',
      message: 'Missing required fields: txn_id, senderId, receiverId, amount',
    });
  }

  const result = processTransaction({ txn_id, senderId, receiverId, amount });
  res.status(result.statusCode).json(result.body);
});

// ─── GET /transactions/:userId ────────────────────────────────────────────────
// Transaction history for a specific user (as sender or receiver)
app.get('/transactions/:userId', (req, res) => {
  const { userId } = req.params;

  if (!users[userId]) {
    log('GET_HISTORY', { userId }, 'NOT FOUND');
    return res.status(404).json({ status: 'failed', message: 'User not found' });
  }

  const userTxns = transactions.filter(
    (t) => t.senderId === userId || t.receiverId === userId
  );

  log('GET_HISTORY', { userId, count: userTxns.length }, 'OK');
  res.json({
    userId,
    balance: users[userId].balance,
    transactions: userTxns,
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

  // Process each transaction sequentially
  const results = txnBatch.map((txn, index) => {
    // Validate each item has required fields
    if (!txn.txn_id || !txn.senderId || !txn.receiverId || txn.amount === undefined) {
      log('SYNC_ITEM', { index }, 'FAILED — missing fields');
      return {
        index,
        txn_id: txn.txn_id || null,
        status: 'failed',
        message: 'Missing required fields',
      };
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
    summary: {
      total: txnBatch.length,
      successful: successCount,
      failed: failedCount,
      duplicates: duplicateCount,
    },
    results,
  });
});

// ─── POST /sms ────────────────────────────────────────────────────────────────
// SMS simulation — parse "PAY <amount> <senderId> <receiverId> <txn_id>"
app.post('/sms', (req, res) => {
  const { message } = req.body;

  if (!message || typeof message !== 'string') {
    log('SMS', {}, 'FAILED — no message');
    return res.status(400).json({
      status: 'failed',
      message: 'Expected { "message": "PAY <amount> <senderId> <receiverId> <txn_id>" }',
    });
  }

  // Parse the SMS format: PAY 500 user1 user2 TXN123
  const parts = message.trim().split(/\s+/);

  if (parts.length !== 5 || parts[0].toUpperCase() !== 'PAY') {
    log('SMS', { message }, 'FAILED — invalid format');
    return res.status(400).json({
      status: 'failed',
      message: 'Invalid SMS format. Expected: "PAY <amount> <senderId> <receiverId> <txn_id>"',
      example: 'PAY 500 user1 user2 TXN123',
    });
  }

  const amount = parseFloat(parts[1]);
  if (isNaN(amount)) {
    log('SMS', { message }, 'FAILED — invalid amount in SMS');
    return res.status(400).json({
      status: 'failed',
      message: `Invalid amount '${parts[1]}' in SMS`,
    });
  }

  const txn = {
    txn_id: parts[4],
    senderId: parts[2],
    receiverId: parts[3],
    amount,
  };

  log('SMS', { parsed: txn }, 'PARSED');

  const result = processTransaction(txn);
  res.status(result.statusCode).json({
    ...result.body,
    parsedFrom: message,
  });
});

// ─── GET /logs ────────────────────────────────────────────────────────────────
// View server logs (for debugging)
app.get('/logs', (_req, res) => {
  res.json({ count: logs.length, logs: logs.slice(-50) }); // Last 50 entries
});

// ─── Global Error Handler ─────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  log('ERROR', { message: err.message }, 'INTERNAL SERVER ERROR');
  res.status(500).json({
    status: 'error',
    message: 'Internal server error',
  });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🏦 BluePay Fake Bank Backend running on http://localhost:${PORT}`);
  console.log(`\n📋 Available Endpoints:`);
  console.log(`   GET    /users                 — List all users`);
  console.log(`   GET    /users/:userId          — Get user details`);
  console.log(`   POST   /transaction            — Process single transaction`);
  console.log(`   GET    /transactions/:userId   — Transaction history`);
  console.log(`   POST   /sync                   — Batch sync transactions`);
  console.log(`   POST   /sms                    — SMS simulation`);
  console.log(`   GET    /logs                   — View server logs`);
  console.log(`\n👥 Seeded users: ${Object.keys(users).join(', ')}`);
  console.log(`   Each starts with ₹1000.00\n`);
});
