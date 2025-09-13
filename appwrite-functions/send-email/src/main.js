import nodemailer from 'nodemailer';

// Appwrite Function for sending emails
// Deploy this to Appwrite Functions
export default async ({ req, res, log, error }) => {
  try {
    // Parse request body
    const { to, from, senderName, subject, content } = JSON.parse(req.body);

    // Create transporter using environment variables
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER || 'christina@christycares.com',
        pass: process.env.EMAIL_PASS // App-specific password
      }
    });

    // Send email
    const info = await transporter.sendMail({
      from: `"${senderName}" <${from}>`,
      to: to,
      subject: subject,
      text: content,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2196F3;">Christy Cares Message</h2>
          <p><strong>From:</strong> ${senderName}</p>
          <p><strong>Subject:</strong> ${subject}</p>
          <hr style="border: 1px solid #eee;">
          <p>${content.replace(/\n/g, '<br>')}</p>
          <hr style="border: 1px solid #eee;">
          <p style="font-size: 12px; color: #666;">
            This message was sent through Christy Cares platform.
            Reply directly to this email or log in to the platform to respond.
          </p>
        </div>
      `
    });

    log(`Email sent successfully to ${to}`);

    return res.json({
      success: true,
      messageId: info.messageId
    });
  } catch (err) {
    error(`Error sending email: ${err.message}`);
    return res.json({
      success: false,
      error: err.message
    }, 500);
  }
};