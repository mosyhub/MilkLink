const crypto = require('crypto');
const QRCode = require('qrcode');

// Generates a single-use claim token, its SHA-256 hash, and a black-and-white QR data URL
async function generateClaimCredentials(profileType = 'Donor') {
    // 16-character uppercase hex token (e.g. "C82F01A4B95D7E36")
    const rawToken = crypto.randomBytes(8).toString('hex').toUpperCase();

    // Hash is stored in the database instead of the raw token
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

    // 30-day validity window
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    const payload = JSON.stringify({
        system: 'MILKLINK_PASIG',
        version: '1.0',
        type: profileType.toUpperCase(),
        token: rawToken,
        created: new Date().toISOString()
    });

    const qrCodeData = await QRCode.toDataURL(payload, {
        errorCorrectionLevel: 'M',
        margin: 2,
        color: { dark: '#000000', light: '#FFFFFF' }
    });

    return { rawToken, tokenHash, expiresAt, qrCodeData };
}

module.exports = { generateClaimCredentials };