const dotenv = require('dotenv');
dotenv.config({ path: 'config/.env' });

const app = require('./app');
const connectDatabase = require('./config/database');
const cloudinary = require('cloudinary');

const PORT = process.env.PORT || 4000;

connectDatabase();

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

app.get('/ping', (req, res) => {
    res.status(200).send('Server is alive');
});

app.listen(PORT, () => {
    console.log(`Server started on PORT: ${PORT} in ${process.env.NODE_ENV} mode`);
    console.log(`Local Address: http://localhost:${PORT}`);
});
