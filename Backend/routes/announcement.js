const express = require('express');
const router = express.Router();
const upload = require('../utils/multer');

const { isAuthenticatedUser, authorizeRoles, optionalAuth } = require('../middlewares/auth');
const {
    allAnnouncements,
    createAnnouncement,
    updateAnnouncement,
    deleteAnnouncement,
    getAnnouncementDetails,
    softDeleteAnnouncement,
    restoreAnnouncement,
    archivedAnnouncements
} = require('../controllers/announcementController');

const adminOnly = [isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin')];

router.route('/announcements')
    .get(optionalAuth, allAnnouncements)
    .post(...adminOnly, upload.single('file'), createAnnouncement);

router.route('/announcement/:id')
    .get(optionalAuth, getAnnouncementDetails)
    .put(...adminOnly, updateAnnouncement)
    .delete(...adminOnly, deleteAnnouncement);

router.route('/announcement/archive/:id')
    .put(...adminOnly, softDeleteAnnouncement);

router.route('/announcement/restore/:id')
    .put(...adminOnly, restoreAnnouncement);

router.route('/announcements/archived')
    .get(...adminOnly, archivedAnnouncements);

module.exports = router;
