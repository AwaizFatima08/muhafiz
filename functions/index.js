const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── Trigger: new gate_events document created ────────────────────────────────

exports.onGateEvent = onDocumentCreated(
  "gate_events/{eventId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const data = snap.data();

    // Only notify on entry and exit — skip auto-exit batch events
    if (!["entry", "exit"].includes(data.event_type)) return null;
    if (data.is_auto_exit === true) return null;

    // V2: snake_case field names
    const workerId   = data.worker_id   || data.workerId;
    const residentId = data.resident_id || data.employerId;
    const eventType  = data.event_type;

    if (!workerId || !residentId) {
      console.log("Missing worker_id or resident_id — skipping notification");
      return null;
    }

    try {
      // ── Fetch worker name ──────────────────────────────────────────────
      const workerDoc = await db.collection("workers").doc(workerId).get();
      if (!workerDoc.exists) {
        console.log(`Worker ${workerId} not found`);
        return null;
      }
      const worker = workerDoc.data();
      const workerName  = worker.worker_name || worker.name || "Unknown Worker";
      const cardNumber  = worker.card_number || "";

      // ── Fetch resident FCM token + notification prefs ──────────────────
      const residentDoc = await db.collection("residents").doc(residentId).get();
      if (!residentDoc.exists) {
        console.log(`Resident ${residentId} not found`);
        return null;
      }
      const resident  = residentDoc.data();
      const fcmToken  = resident.fcm_token;
      const prefs     = resident.notification_pref || {};

      // Respect notification preferences
      const wantsEntry = prefs.worker_entry !== false;   // default true
      const wantsExit  = prefs.worker_exit  !== false;   // default true

      if (eventType === "entry" && !wantsEntry) {
        console.log(`Resident ${residentId} has worker_entry notifications off`);
        return null;
      }
      if (eventType === "exit" && !wantsExit) {
        console.log(`Resident ${residentId} has worker_exit notifications off`);
        return null;
      }

      if (!fcmToken) {
        console.log(`No FCM token for resident ${residentId} — storing in-app only`);
      }

      // ── Build notification ─────────────────────────────────────────────
      const isEntry = eventType === "entry";
      const timeStr = new Date().toLocaleTimeString("en-PK", {
        hour:     "2-digit",
        minute:   "2-digit",
        hour12:   true,
        timeZone: "Asia/Karachi",
      });

      const title = isEntry
        ? `Worker Entered — ${workerName}`
        : `Worker Exited — ${workerName}`;

      const body = isEntry
        ? `${workerName} (${cardNumber}) entered FFL Township at ${timeStr}`
        : `${workerName} (${cardNumber}) exited FFL Township at ${timeStr}`;

      // ── Send FCM push (only if token present) ─────────────────────────
      if (fcmToken) {
        const message = {
          token: fcmToken,
          notification: { title, body },
          data: {
            event_type:  eventType,
            worker_id:   workerId,
            worker_name: workerName,
            card_number: cardNumber,
            resident_id: residentId,
            time:        timeStr,
          },
          android: {
            notification: {
              channel_id:    "muhafiz_gate_events",
              priority:      "high",
              default_sound: true,
            },
            priority: "high",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await messaging.send(message);
        console.log(`FCM sent to resident ${residentId}: ${response}`);
      }

      // ── Store notification in Firestore for in-app inbox ───────────────
      await db.collection("notifications").add({
        recipient_user_id:     residentId,
        recipient_resident_id: residentId,
        title,
        body,
        type:        isEntry ? "entry" : "exit",
        worker_id:   workerId,
        worker_name: workerName,
        card_number: cardNumber,
        is_read:     false,
        channel:     "fcm",
        created_at:  admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error("Error in onGateEvent:", error);
      return null;
    }
  }
);


// ─── Trigger: daily card expiry check (runs at 8am PKT = 3am UTC) ────────────

exports.dailyCardExpiryCheck = require('firebase-functions/v2/scheduler')
  .onSchedule('0 3 * * *', async () => {
    const now   = new Date();
    const in30  = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const snap = await db.collection('workers')
      .where('status', 'in', ['active', 'pendingApproval'])
      .where('card_expiry_date', '<=', in30)
      .where('card_expiry_notified', '==', '')
      .get();

    if (snap.empty) return null;

    const batch = db.batch();

    for (const doc of snap.docs) {
      const w       = doc.data();
      const expiry  = w.card_expiry_date?.toDate();
      if (!expiry) continue;

      const daysLeft = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));

      // Write in-app notification for security managers
      const managersSnap = await db.collection('users')
        .where('role', '==', 'securityManager')
        .where('is_active', '==', true)
        .get();

      for (const mgr of managersSnap.docs) {
        await db.collection('notifications').add({
          recipient_user_id:     mgr.id,
          recipient_resident_id: '',
          title:  `Card Expiry Alert — ${w.worker_name}`,
          body:   `Card ${w.card_number} expires in ${daysLeft} day(s) on ` +
                  `${expiry.toLocaleDateString('en-PK')}.`,
          type:      'cardExpiry',
          worker_id: doc.id,
          is_read:   false,
          channel:   'inApp',
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send FCM if token present
        const token = mgr.data().fcm_token;
        if (token) {
          await messaging.send({
            token,
            notification: {
              title: `Card Expiry — ${w.worker_name}`,
              body:  `Card expires in ${daysLeft} day(s)`,
            },
          }).catch(() => {});
        }
      }

      // Mark as notified
      batch.update(db.collection('workers').doc(doc.id), {
        card_expiry_notified: now.toISOString(),
      });
    }

    await batch.commit();
    console.log(`Card expiry check: notified for ${snap.size} worker(s)`);
    return null;
  });
