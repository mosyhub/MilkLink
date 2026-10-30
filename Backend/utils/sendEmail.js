const nodemailer = require('nodemailer');

const sendEmail = async options => {
  const transport = nodemailer.createTransport({
    service: 'gmail',
    tls: {
      rejectUnauthorized: false // This allows self-signed certificates (not ideal for production)
    },
    auth: {
      user: process.env.SMTP_EMAIL,
      pass: process.env.SMTP_PASSWORD
    }
  });

  const message = {
    from: `${process.env.SMTP_FROM_NAME} <${process.env.SMTP_FROM_EMAIL}>`,
    to: options.email,
    subject: options.subject,
    text: options.message
  }

  await transport.sendMail(message)
}

module.exports = sendEmail;