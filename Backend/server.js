const app = require('./app');
const connectDatabase = require('./config/database');
const cloudinary = require('cloudinary');
const axios = require('axios');
const dotenv = require('dotenv');

//Setting up config file
dotenv.config({ path: 'config/.env' })

//Connect to database
connectDatabase();

// Setting up cloudinary configuration
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
})
// ✅ Health Check Route
app.get("/ping", (req, res) => {
    res.send("✅ Server is alive");
});


const SERVER_URL = "https://capstone-vpm5.onrender.com";
const pingSelf = async () => {``
    try {
        const response = await axios.get(`${SERVER_URL}/ping`);
        console.log(`🔄 Pinging server: ${response.status} ${response.statusText}`);
    } catch (error) {
        console.error("❌ Self-ping failed:", error.message);
    }
};

app.listen(process.env.PORT, () => {
    console.log(`Server started on PORT : ${process.env.PORT} in ${process.env.NODE_ENV} mode`)
    // Ping itself every 60 seconds
    // setInterval(pingSelf, 60 * 1000);
}) 