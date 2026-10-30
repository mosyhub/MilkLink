const express = require('express');
const router = express.Router();

const { 
    allEvents,
    createEvent,
    getEventDetails,
    updateEvent,
    deleteEvent,
    getUpcomingEvents
} = require('../controllers/eventController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

router.get('/events/upcoming', getUpcomingEvents);


// Super Admin Routes
router.route('/events')
    .get(isAuthenticatedUser, allEvents)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin'), createEvent);
router.route('/event/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin'), getEventDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin'), updateEvent)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin'), deleteEvent);


module.exports = router;