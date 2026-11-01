const mongoose = require('mongoose');

const connectDatabase = () => {
    mongoose.connect(process.env.MONGODB_URI)
        .then(con => {
            console.log(`MongoDB Database connected with HOST: ${con.connection.host}`);
        })
        .catch(err => {
            console.error(`Database connection error: ${err.message}`);
        });
};

module.exports = connectDatabase;
