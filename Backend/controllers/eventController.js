const Event = require('../models/event')
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const Letting = require('../models/letting')

exports.getUpcomingEvents = catchAsyncErrors(async (req, res, next) => {
    try{
        const events = await Event.find({
            'eventDetails.start': {
                $gte: new Date()
            }
        }).sort('eventDetails.start');

        return res.status(200).json({
            success: true,
            count: events.length,
            events
        })
    }
    catch(error){
        res.status(500).json({
            success: false,
            message: error.message
        })
    }
})

// Get All Events => /api/v1/events
exports.allEvents = catchAsyncErrors(async (req, res, next) => {
    const events = await Event.find();

        const count = await Event.countDocuments();

        res.status(200).json({
            success: true,
            count,
            events
        })

})

// Create Event => /api/v1/events
exports.createEvent = catchAsyncErrors(async (req, res, next) => {

    console.log('request: ', req.body);
    console.log("start: ", req.body.start);
    const eventDetails = {
        start: new Date(req.body.start),  // This stores in UTC
        end: new Date(req.body.end)       // This stores in UTC
    };
    const eventStatus = req.body.status.trim();

    const event = await Event.create({
        title: req.body.title,
        description: req.body.description,
        eventDetails,
        eventStatus,
        eventType: req.body.type,
        user: req.body.user
    });
    const letting = await Letting.create({
        activity: req.body.title,
        venue: req.body.description,
        status: eventStatus,
        actDetails: eventDetails,
        admin: req.body.user
    }) 
    res.status(201).json({
        success: true,
        event,
        letting
    });
})

// Get specific event details => /api/v1/event/:id
exports.getEventDetails = catchAsyncErrors(async (req, res, next) => {
    const event = await Event.findById(req.params.id);

    if (!event) {
        return next(new ErrorHandler(`Event is not found with this id: ${req.params.id}`))
    }

    res.status(200).json({
        success: true,
        event
    })
})

// Update event => /api/v1/event/:id
exports.updateEvent = catchAsyncErrors(async (req, res, next) => {
    const eventDetails = {
        start: req.body.start,
        end: req.body.end
    }

    const eventStatus = req.body.status.trim();

    const newEventData = {
        title: req.body.title,
        description: req.body.description,
        eventDetails: eventDetails,
        eventStatus: eventStatus,
        eventType: req.body.type,
        user: req.body.user
    }

    const event = await Event.findByIdAndUpdate(req.params.id, newEventData, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    res.status(200).json({
        success: true,
        event
    })

})

// Delete event => /api/v1/event/:id
exports.deleteEvent = catchAsyncErrors(async (req, res, next) => {
    const event = await Event.findById(req.params.id);

    if (!event) {
        return next(new ErrorHandler(`Event is not found with this id: ${req.params.id}`))
    }

    // Remove pictures from cloudinary
    // const image_id = event.avatar.public_id;
    // await cloudinary.v2.uploader.destroy(image_id);

    await event.deleteOne();

    res.status(200).json({
        success: true,
        message: "Event Deleted"
    })
})