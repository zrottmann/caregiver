// Appwrite Function for sending SMS using TextBelt
// Deploy this to Appwrite Functions
export default async ({ req, res, log, error }) => {
  try {
    // Parse request body
    const { to, from, content } = JSON.parse(req.body);

    // Use TextBelt API (open source SMS service)
    const response = await fetch('https://textbelt.com/text', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        phone: to,
        message: `${from}: ${content}`,
        key: process.env.TEXTBELT_KEY || 'textbelt' // 'textbelt' = free tier (1 SMS/day)
      })
    });

    const result = await response.json();

    if (result.success) {
      log(`SMS sent successfully to ${to}`);
      return res.json({
        success: true,
        textId: result.textId,
        quotaRemaining: result.quotaRemaining
      });
    } else {
      throw new Error(result.error || 'Failed to send SMS');
    }
  } catch (err) {
    error(`Error sending SMS: ${err.message}`);
    return res.json({
      success: false,
      error: err.message
    }, 500);
  }
};