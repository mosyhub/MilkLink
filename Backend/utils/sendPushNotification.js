const sendPushNotification = async (token, title, body) => {
    try {
        const fetch = (await import("node-fetch")).default;

        if (!token || !title || !body) {
            throw new Error("Token, Title, and Body are required");
        }

        const messages = {
            to: token,
            sound: "default",
            title,
            body,
        };

        const response = await fetch("https://exp.host/--/api/v2/push/send", {
            method: "POST",
            headers: {
                Accept: "application/json",
                "Content-Type": "application/json",
            },
            body: JSON.stringify(messages),
        });

        if (!response.ok) {
            throw new Error(`Push notification failed with status: ${response.status}`);
        }

        const jsonResponse = await response.json();
        return jsonResponse;
    } catch (error) {
        console.error("Error Sending Push Notification:", error);
        return { error: error.message };
    }
};

module.exports = { sendPushNotification };