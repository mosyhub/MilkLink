const sendToken = (user, statusCode, req, res) => {
    // Gracefully handle calls like sendToken(user, statusCode, res)
    if (!res && req && req.status) {
        res = req;
        req = null;
    }

    if (!res && req && req.status) {
        res = req;
        req = null;
    }

    const accessToken = user.getAccessToken();
    const refreshToken = user.getRefreshToken();

    const isMobile = req && req.headers && req.headers['x-client-type'] === 'mobile';

    if (isMobile) {
        res.setHeader('Authorization', `Bearer ${accessToken}`);
        return res.status(statusCode).json({
            success: true,
            message: statusCode === 201 ? 'Registered successfully' : 'Login successful',
            token: accessToken,
            refreshToken,
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

        return res.status(statusCode).json({
            success: true,
            message: statusCode === 201 ? 'Registered successfully' : 'Login successful',
            token: accessToken,
            user
        });
    }
};

module.exports = sendToken;
module.exports = sendToken;