const Notification = require("../models/notification");
const User = require("../models/user");
const ErrorHandler = require("../utils/errorHandler");
const catchAsyncErrors = require("../middlewares/catchAsyncErrors");
const { sendPushNotification } = require("../utils/sendPushNotification");

// Check notification record for a user
exports.checkNotifications = catchAsyncErrors(async (req, res, next) => {
  const { userId, expoToken } = req.body;

  if (!expoToken || !userId) {
    return next(new ErrorHandler("Missing expoToken or userId", 400));
  }

  // Remove this token from any other user's record
  await Notification.updateMany(
    { user: { $ne: userId }, expoTokens: expoToken },
    { $pull: { expoTokens: expoToken } }
  );

  // Add the token to current user if it doesn't exist
  let notification = await Notification.findOneAndUpdate(
    { user: userId },
    { $addToSet: { expoTokens: expoToken } },
    { new: true, upsert: true }
  );

  res.status(200).json({
    success: true,
    notification,
  });
});

// Get all notifications for the logged-in user
exports.getUserNotifications = catchAsyncErrors(async (req, res, next) => {
  const userId = req.user.id;

  const notificationDoc = await Notification.findOne({ user: userId });

  if (!notificationDoc) {
    return res.status(200).json({
      success: true,
      count: 0,
      unseen: 0,
      notifications: [],
    });
  }

  const { notifications } = notificationDoc;
  const count = notifications.length;
  const unseen = notifications.filter((n) => !n.seen).length;

  res.status(200).json({
    success: true,
    count,
    unseen,
    notifications,
  });
});

// Mark a single notification as seen
exports.markAsSeen = catchAsyncErrors(async (req, res, next) => {
  const userId = req.user.id;
  const notificationId = req.params.id;

  const notificationDoc = await Notification.findOne({ user: userId });

  if (!notificationDoc) {
    return next(new ErrorHandler("Notification details not found", 404));
  }

  const notification = notificationDoc.notifications.id(notificationId);

  if (!notification) {
    return next(new ErrorHandler("Notification item not found", 404));
  }

  notification.seen = true;
  await notificationDoc.save();

  res.status(200).json({
    success: true,
    message: "Notification marked as seen",
  });
});

// Delete a single notification
exports.deleteNotification = catchAsyncErrors(async (req, res, next) => {
  const userId = req.user.id;
  const notificationId = req.params.id;

  const notificationDoc = await Notification.findOne({ user: userId });

  if (!notificationDoc) {
    return next(new ErrorHandler("Notification details not found", 404));
  }

  notificationDoc.notifications = notificationDoc.notifications.filter(
    (n) => n._id.toString() !== notificationId
  );
  await notificationDoc.save();

  res.status(200).json({
    success: true,
    message: "Notification deleted successfully",
  });
});

// Send and save push notifications
exports.sendNotifications = catchAsyncErrors(async (req, res, next) => {
  const { role, title, body } = req.body;

  if (!role || !title || !body) {
    return next(new ErrorHandler("Role, title, and body are required", 400));
  }

  const users = await User.find({ role });
  if (users.length === 0) {
    return next(new ErrorHandler("No users found with this role", 404));
  }

  const notificationDocs = await Notification.find({
    user: { $in: users.map((u) => u._id) },
  });

  for (let notifDoc of notificationDocs) {
    for (let token of notifDoc.expoTokens) {
        console.log(token)
      await sendPushNotification(token, title, body);
    }
    notifDoc.notifications.push({ title, body });
    await notifDoc.save();
  }

  res.status(200).json({
    success: true,
    message: "Notifications sent and saved",
  });
});


// Send a single user notification
exports.sendSingleUserNotif = catchAsyncErrors(async (req, res, next) => {
  const { userId, title, body } = req.body;
console.log(req.body)
  if (!userId || !title || !body) {
    return next(new ErrorHandler("userId, title, and body are required", 400));
  }

  const notifDoc = await Notification.findOne({ user: userId });
  console.log(notifDoc)
  for (let token of notifDoc.expoTokens) {
    const response = await sendPushNotification(token, title, body);
  }
  notifDoc.notifications.push({ title, body });
  await notifDoc.save();

  res.status(200).json({
    success: true,
    message: "Notification sent",
  });
});