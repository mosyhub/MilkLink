const cron = require("node-cron");
const Notification = require("../models/notification");
const User = require("../models/user");
const Donor = require("../models/donor");
const { sendPushNotification } = require("../utils/sendPushNotification");

const newDonor = async () => {
  try {
    const now = new Date();
    const oneMinuteAgo = new Date(now.getTime() - 60000); // 1 minute ago

    const newDonors = await Donor.find({
      createdAt: { $gte: oneMinuteAgo },
    }).populate("user");

    if (newDonors.length === 0) return;

    const users = await User.find({ role: { $in: ["Admin", "SuperAdmin"] } });
    const notifications = await Notification.find({
      user: { $in: users.map((u) => u._id) },
    });

    const notificationsMap = new Map();
    notifications.forEach((n) => notificationsMap.set(n.user.toString(), n));

    const pushTasks = [];

    for (const donor of newDonors) {
      const fullName = `${donor.user?.name?.first || ""} ${
        donor.user?.name?.last || ""
      }`.trim();
      const title = "New Donor Applied";
      const body = `A new donor (${fullName}) has been added. Check the portal for details.`;

      for (const user of users) {
        const notifDoc = notificationsMap.get(user._id.toString());
        if (notifDoc && notifDoc.expoTokens.length > 0) {
          const alreadyNotified = notifDoc.notifications.some(
            (n) => n.body === body
          );

          if (!alreadyNotified) {
            for (const token of notifDoc.expoTokens) {
              pushTasks.push(sendPushNotification(token, title, body));
            }

            notifDoc.notifications.push({
              title,
              body,
              seen: false,
              notifiedAt: new Date(),
            });
          }
        }
      }
    }

    await Promise.all(pushTasks);
    await Promise.all([...notificationsMap.values()].map((n) => n.save()));

    console.log("New donor notifications sent successfully.");
  } catch (error) {
    console.error("Error sending new donor notification:", error);
  }
};

// Run every minute
cron.schedule("* * * * *", newDonor);

module.exports = newDonor;
