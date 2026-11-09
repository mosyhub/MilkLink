const mongoose = require('mongoose');

const connectDatabase = () => {
    mongoose.connect(process.env.MONGODB_URI)
        .then(async con => {
            console.log(`MongoDB Database connected with HOST: ${con.connection.host}`);
            for (const collectionName of ['schedules', 'patients', 'requests']) {
                try {
                    await con.connection.db.command({
                        collMod: collectionName,
                        validator: {},
                        validationLevel: 'off'
                    });
                } catch (collErr) {
                    // Ignore if collection doesn't exist or command not permitted
                }
            }

            try {
                // Backfill status: 'Active' on existing users missing the field
                const User = require('../models/user');
                await User.updateMany(
                    { status: { $exists: false } },
                    { $set: { status: 'Active' } }
                );
            } catch (userErr) {
                // Ignore if error
            }
        })
        .catch(err => {
            console.error(`Database connection error: ${err.message}`);
        });
};

module.exports = connectDatabase;
