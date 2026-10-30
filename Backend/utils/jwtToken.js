const sendToken = (user, statusCode, req, res) => {
    const accessToken = user.getAccessToken();
    const refreshToken = user.getRefreshToken();

    const isMobile = req.headers['x-client-type'] === 'mobile';

    if (isMobile) {
        res.setHeader('Authorization', `Bearer ${accessToken}`);
        res.status(statusCode).json({
            success: true,
            token: accessToken,
            refreshToken, // Optional: only if mobile needs to store/refresh manually
            user
        });
    } else {
        res.cookie('accessToken', accessToken, {
            httpOnly: true,
            maxAge: 15 * 60 * 1000, // 15 mins
            sameSite: 'None',
            secure: true // set to true in production
        });

        res.cookie('refreshToken', refreshToken, {
            httpOnly: true,
            maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
            sameSite: 'None',
            secure: true
        });

        res.status(statusCode).json({
            success: true,
            user
        });
    }
};


module.exports = sendToken