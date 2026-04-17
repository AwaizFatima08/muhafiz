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

    const workerId = data.workerId;
    const employerId = data.employerId;
    const eventType = data.event_type;

    if (!workerId || !employerId) {
      console.log("Missing workerId or employerId — skipping notification");
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
      const workerName =
        worker.worker_name || worker.name || "Unknown Worker";
      const cardNumber = worker.card_number || "";

      // ── Fetch employer FCM token ───────────────────────────────────────
      const employerDoc = await db
        .collection("employers")
        .doc(employerId)
        .get();
      if (!employerDoc.exists) {
        console.log(`Employer ${employerId} not found`);
        return null;
      }
      const employer = employerDoc.data();
      const fcmToken = employer.fcm_token;

      if (!fcmToken) {
        console.log(
          `No FCM token for employer ${employerId} — skipping`
        );
        return null;
      }

      // ── Build notification ─────────────────────────────────────────────
      const isEntry = eventType === "entry";
      const timeStr = new Date().toLocaleTimeString("en-PK", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
        timeZone: "Asia/Karachi",
      });

      const title = isEntry
        ? `✅ Worker Entered — ${workerName}`
        : `🚪 Worker Exited — ${workerName}`;

      const body = isEntry
        ? `${workerName} (${cardNumber}) entered FFL Township at ${timeStr}`
        : `${workerName} (${cardNumber}) exited FFL Township at ${timeStr}`;

      // ── Send FCM message ───────────────────────────────────────────────
      const message = {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          event_type: eventType,
          worker_id: workerId,
          worker_name: workerName,
          card_number: cardNumber,
          employer_id: employerId,
          time: timeStr,
        },
        android: {
          notification: {
            channel_id: "muhafiz_gate_events",
            priority: "high",
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
      console.log(
        `Notification sent to employer ${employerId}: ${response}`
      );

      // ── Store notification in Firestore for in-app inbox ───────────────
      await db.collection("notifications").add({
        recipient_user_id: employerId,
        title,
        body,
        event_type: eventType,
        worker_id: workerId,
        worker_name: workerName,
        card_number: cardNumber,
        is_read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  }
);
