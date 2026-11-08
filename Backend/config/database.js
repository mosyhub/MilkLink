const mongoose = require('mongoose');

const connectDatabase = () => {
    mongoose.connect(process.env.MONGODB_URI)
        .then(async con => {
            console.log(`MongoDB Database connected with HOST: ${con.connection.host}`);
            try {
                // Ensure legacy collection validator on 'schedules' does not fail validation
                await con.connection.db.command({
                    collMod: 'schedules',
                    validator: {},
                    validationLevel: 'off'
                });
            } catch (collErr) {
                // Ignore if collection doesn't exist or command not permitted
            }
        })
        .catch(err => {
            console.error(`Database connection error: ${err.message}`);
        });
};

module.exports = connectDatabase;
