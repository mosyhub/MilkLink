const dotenv = require('dotenv');

dotenv.config({ path: 'config/.env' });

const app = require('./app');
const connectDatabase = require('./config/database');
const cloudinary = require('cloudinary');
const axios = require('axios');

connectDatabase();

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// Health Check Route
app.get("/ping", (req, res) => {
    res.send("Server is alive");
});

// Dynamic Local URL Tracking
const PORT = process.env.PORT || 4000;
const LOCAL_SERVER_URL = `http://localhost:${PORT}`;

const pingSelf = async () => {
    try {
        const response = await axios.get(`${LOCAL_SERVER_URL}/ping`);
        console.log(`Pinging local server: ${response.status} ${response.statusText}`);
    } catch (error) {
        console.error("Local self-ping failed:", error.message);
    }
};

// Start Server
app.listen(PORT, () => {
    console.log(`Server started on PORT : ${PORT} in ${process.env.NODE_ENV} mode`);
    console.log(`Local Address: ${LOCAL_SERVER_URL}`);
});
