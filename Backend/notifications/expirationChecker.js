const cron = require("node-cron");
const Notification = require("../models/notification");
const User = require("../models/user");
const Inventory = require("../models/inventory");
const { sendPushNotification } = require("../utils/sendPushNotification");

const checkExpiringMilk = async () => {
  try {
    const today = new Date();
    const oneWeekLater = new Date();
    oneWeekLater.setDate(today.getDate() + 7);

    const expiringMilk = await Inventory.find({
      $or: [
        {
          "pasteurizedDetails.expiration": { $gte: today, $lte: oneWeekLater },
        },
        {
          "unpasteurizedDetails.expiration": {
            $gte: today,
            $lte: oneWeekLater,
          },
        },
      ],
      status: "Available",
    }).populate("fridge");

    if (expiringMilk.length === 0) return;

    const users = await User.find({ role: { $in: ["Admin", "SuperAdmin"] } });
    const notifications = await Notification.find({
      user: { $in: users.map((u) => u._id) },
    });

    const notificationsMap = new Map();
    notifications.forEach((n) => notificationsMap.set(n.user.toString(), n));

    const pushTasks = [];

    for (const milk of expiringMilk) {
      const expirationDate =
        milk.pasteurizedDetails?.expiration ||
        milk.unpasteurizedDetails?.expiration;
      const fridgeType = milk.fridge?.fridgeType || "Unknown";

      const title = `${fridgeType} Milk Expiration`;
      const body = `Milk ID: ${milk._id} will expire on ${
        expirationDate.toISOString().split("T")[0]
      }. Please take necessary actions.`;

      for (const user of users) {
        const notifDoc = notificationsMap.get(user._id.toString());
        if (notifDoc && notifDoc.expoTokens.length > 0) {
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
    }

    await Promise.all(pushTasks);

    // Save all updated notification documents
    await Promise.all([...notificationsMap.values()].map((n) => n.save()));

    console.log("Expiration notifications sent successfully.");
  } catch (error) {
    console.error("Error checking expiring milk:", error);
  }
};

// Schedule the task to run every day at midnight
cron.schedule("0 0 * * *", checkExpiringMilk);

module.exports = checkExpiringMilk;
