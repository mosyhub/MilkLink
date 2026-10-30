const express = require('express');
const cors = require('cors')
const app = express();

const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const fileUpload = require('express-fileupload');
const checkExpiringMilk = require('./notifications/expirationChecker');
const newDonor = require('./notifications/newDonor');
const checkEvents = require('./schedule/eventChecker');
const cookieParser = require('cookie-parser')
const errorMiddleware = require('./middlewares/errors');
const jwt = require('jsonwebtoken');
// Setting up config file
dotenv.config({ path: 'config/.env' });

const corsOptions = {
    origin: ['http://localhost:5173', 'http://localhost:5174', 'http://192.168.7.85', 'http://192.168.5.235:8081', 'http://192.168.5.234:8081', 'https://tchmb-portal.vercel.app'], // Add your frontend's URL here
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));
app.use(cookieParser());
// Middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(fileUpload()); // For handling file uploads

// Route Imports
const user = require('./routes/user');
const event = require('./routes/event');
const patient = require('./routes/patient');
const donor = require('./routes/donor');
const fridge = require('./routes/fridge');
const inventory = require('./routes/inventory');
const request = require('./routes/request');
const equipment = require('./routes/equipment');
const article = require('./routes/article')
const notification = require('./routes/notification');
const schedule = require('./routes/schedule');
const letting = require('./routes/letting');
const collection = require('./routes/collection');
const bag = require('./routes/bag');
const metrics = require('./routes/metrics');
const announcement = require('./routes/announcement');
const sign = require('./routes/signatories');
// API routes
app.use('/api/v1', user);
app.use('/api/v1', event);
app.use('/api/v1', patient);
app.use('/api/v1', donor);
app.use('/api/v1', fridge);
app.use('/api/v1', inventory);
app.use('/api/v1', request);
app.use('/api/v1', equipment);
app.use('/api/v1', article);
app.use('/api/v1', notification);
app.use('/api/v1', schedule);
app.use('/api/v1', letting);
app.use('/api/v1', collection);
app.use('/api/v1', bag);
app.use('/api/v1', metrics)
app.use('/api/v1', announcement);
app.use('/api/v1', sign);
// Example refresh route
app.post('/api/v1/refresh-token', (req, res) => {
    const refreshToken = req.cookies.refreshToken || req.body.refreshToken;
    console.log("Refresh Token:", refreshToken);
    console.log("Called")
    if (!refreshToken) return res.status(401).json({ message: 'No refresh token' });
    console.log("JWT refresh: ", process.env.JWT_REFRESH_SECRET);
    try {
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const newAccessToken = jwt.sign({ id: decoded.id, role: decoded.role }, process.env.JWT_SECRET, {
            expiresIn: '15m'
        });

        res.cookie('accessToken', newAccessToken, {
            httpOnly: true,
            sameSite: 'None',
            secure: true,
            maxAge: 15 * 60 * 1000
        });

        res.status(200).json({ success: true, accessToken: newAccessToken });
    } catch (err) {
        return res.status(403).json({ message: 'Invalid refresh token' });
    }
});

// Middleware to handle errors
app.use(errorMiddleware);

// Notifications
checkExpiringMilk();
newDonor();
// checkEvents();

module.exports = app;
