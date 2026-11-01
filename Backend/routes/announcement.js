const express = require('express');
const router = express.Router();
const upload = require('../utils/multer')

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');
const { allAnnouncements, createAnnouncement, updateAnnouncement, deleteAnnouncement, getAnnouncementDetails, createHTMLAnnouncement, updateHTMLAnnouncement, softDeleteAnnouncement, restoreAnnouncement, archivedAnnouncements } = require('../controllers/announcementController');

//Super Admin Routes
router.route('/announcements')
    .get(allAnnouncements)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), upload.single('file'), createAnnouncement)

router.route('/html-announcement')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), upload.single('image'), createHTMLAnnouncement)
router.route('/html-announcement/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), upload.single('image'), updateHTMLAnnouncement)

router.route('/announcement/:id')
    .get(isAuthenticatedUser, getAnnouncementDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateAnnouncement)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteAnnouncement)

router.route('/announcement/archive/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), softDeleteAnnouncement)

router.route('/announcement/restore/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), restoreAnnouncement)

router.route('/announcements/archived')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), archivedAnnouncements)

module.exports = router;