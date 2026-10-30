const express = require('express');
const router = express.Router();

const { 
    checkNotifications, 
    getUserNotifications, 
    markAsSeen, 
    deleteNotification,
    sendNotifications,
    sendSingleUserNotif
} = require('../controllers/notifController');

const { isAuthenticatedUser } = require('../middlewares/auth');


router.route('/notifications/check')
    .post(isAuthenticatedUser, checkNotifications); 

router.route('/notifications')
    .get(isAuthenticatedUser, getUserNotifications);

router.route('/notifications/:id')
    .put(markAsSeen)
    .delete(deleteNotification);

router.route('/notifications/send')
    .post(isAuthenticatedUser, sendNotifications);

router.route('/notifications/send/single')
    .post(isAuthenticatedUser, sendSingleUserNotif);
    


module.exports = router;
