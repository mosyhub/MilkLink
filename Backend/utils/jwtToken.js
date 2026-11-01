const sendToken = (user, statusCode, req, res, extra = {}) => {
    // Gracefully handle calls like sendToken(user, statusCode, res) or sendToken(user, statusCode, res, extra)
    if (req && typeof req.status === 'function' && (!res || typeof res.status !== 'function')) {
        extra = res || {};
        res = req;
        req = null;
    }

    const accessToken = user.getAccessToken();
    const refreshToken = user.getRefreshToken();

    const isMobile = req && req.headers && req.headers['x-client-type'] === 'mobile';

    const responsePayload = {
        success: true,
        message: statusCode === 201 ? 'Registered successfully' : 'Login successful',
        token: accessToken,
        refreshToken,
        user,
        ...extra
    };

    if (isMobile) {
        res.setHeader('Authorization', `Bearer ${accessToken}`);
        return res.status(statusCode).json(responsePayload);
    } else {
        res.cookie('accessToken', accessToken, {
            httpOnly: true,
            maxAge: 15 * 60 * 1000, // 15 mins
            sameSite: 'None',
            secure: true
        });

        res.cookie('refreshToken', refreshToken, {
            httpOnly: true,
            maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
            sameSite: 'None',
            secure: true
        });

        return res.status(statusCode).json(responsePayload);
    }
};

module.exports = sendToken;
