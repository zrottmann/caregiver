const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Create transporter with your SMTP settings
// This works with ANY email provider or self-hosted server
const transporter = nodemailer.createTransport({
  // Option 1: Gmail (easiest for testing)
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER || 'christina@christycares.com',
    pass: process.env.EMAIL_PASS || 'your-app-password' // Use app-specific password
  }

  // Option 2: Any SMTP server (including self-hosted)
  // host: process.env.SMTP_HOST || 'smtp.yourdomain.com',
  // port: process.env.SMTP_PORT || 587,
  // secure: false, // true for 465, false for other ports
  // auth: {
  //   user: process.env.SMTP_USER,
  //   pass: process.env.SMTP_PASS
  // }

  // Option 3: Self-hosted Postal
  // host: 'postal.yourdomain.com',
  // port: 25,
  // auth: {
  //   user: 'your-postal-username',
  //   pass: 'your-postal-api-key'
  // }

  // Option 4: Self-hosted Mail-in-a-Box
  // host: 'box.yourdomain.com',
  // port: 587,
  // auth: {
  //   user: 'admin@yourdomain.com',
  //   pass: 'your-password'
  // }
});

// Email sending endpoint
app.post('/send', async (req, res) => {
  try {
    const { to, from, subject, text, html } = req.body;

    // Validate required fields
    if (!to || !subject || (!text && !html)) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: to, subject, and either text or html'
      });
    }

    // Send email
    const info = await transporter.sendMail({
      from: from || process.env.EMAIL_FROM || '"Christy Cares" <christina@christycares.com>',
      to: to,
      subject: subject,
      text: text,
      html: html || text
    });

    res.json({
      success: true,
      messageId: info.messageId,
      accepted: info.accepted
    });
  } catch (error) {
    console.error('Email send error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Christy Cares Email Server',
    timestamp: new Date().toISOString()
  });
});

// Verify SMTP connection on startup
transporter.verify((error, success) => {
  if (error) {
    console.error('SMTP connection error:', error);
  } else {
    console.log('✅ SMTP server is ready to send emails');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`📧 Email server running on port ${PORT}`);
  console.log(`Endpoint: http://localhost:${PORT}/send`);
});

// For Vercel deployment, export the app
module.exports = app;