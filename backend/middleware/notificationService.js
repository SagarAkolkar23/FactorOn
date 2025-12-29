import admin from "../config/firebase.js";
import User from "../model/userSchema.js";

export const notifySupervisors = async ({ title, body, data = {} }) => {
  try {
    // 1️⃣ Get supervisors with FCM tokens
    const supervisors = await User.find({
      role: "supervisor",
      fcmTokens: { $exists: true, $ne: [] },
    }).select("fcmTokens");

    if (!supervisors.length) {
      console.log("ℹ️ No supervisors with FCM tokens");
      return;
    }

    // 2️⃣ Flatten tokens
    const tokens = supervisors.flatMap((u) => u.fcmTokens).filter(Boolean);

    if (!tokens.length) {
      console.log("ℹ️ Supervisor tokens empty");
      return;
    }

    // 3️⃣ Send push notification
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    });

    console.log(
      `📨 Notifications sent — success: ${response.successCount}, failed: ${response.failureCount}`
    );

    // 4️⃣ OPTIONAL: clean invalid tokens
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        console.warn(
          `⚠️ Invalid FCM token removed: ${tokens[idx]}`,
          resp.error?.message
        );
      }
    });
  } catch (error) {
    console.error("❌ Failed to send notification:", error);
    // Non-blocking by design
  }
};
