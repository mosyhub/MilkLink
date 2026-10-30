const cron = require("node-cron");
const mongoose = require("mongoose");

const Letting = require('../models/letting')

const checkEvents = async () => {
    console.log("Checking for events to update...");

    const now = new Date(); // Get the current date and time

    try {
        // Find events that are "Not-Due" but should now be "Ongoing"
        const OnGoingEvents = await Letting.find({
            "actDetails.date": { $lte: now },
            status: "Not-Due",
        });
        if (OnGoingEvents.length > 0) {
            await Letting.updateMany(
                { _id: { $in: OnGoingEvents.map(event => event._id) } },
                { $set: { status: "On-Going" } }
            );
            console.log(`Updated ${OnGoingEvents.length} event(s) to Ongoing.`);
        }
        else {
            console.log("No events to update.");
        }
        
    } catch (error) {
        console.error("Error updating event statuses:", error);
    }
}
// Run the job every minute
cron.schedule("* * * * *", checkEvents);

module.exports = checkEvents;