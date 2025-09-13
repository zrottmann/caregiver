# 🧪 Email Function Test Guide

Your email function is deployed with ID: `68c5c9dc0036c5a66172`

## 🚀 Manual Test (Recommended)

### Step 1: Go to Function Console
Open: https://cloud.appwrite.io/console/project-christy-cares-app/functions/68c5c9dc0036c5a66172

### Step 2: Test Execution
1. Click the **"Execute"** tab
2. Paste this test payload:

```json
{
  "to": "test@christy-cares.com",
  "subject": "Test Email from Christy Cares Platform",
  "content": "Hello!\n\nThis is a test email from your deployed Appwrite function.\n\n✅ Function ID: 68c5c9dc0036c5a66172\n✅ Project ID: christy-cares-app\n\nIf you can see this, the email function is working correctly!\n\nBest regards,\nThe Christy Cares Team"
}
```

3. Click **"Execute Function"**

### Step 3: Check Results
Look for:
- ✅ **Success Response**: `{"success": true, "messageId": "...", "previewUrl": "..."}`
- ✅ **Preview URL**: A link like `https://ethereal.email/message/xxx`
- ✅ **Function Logs**: Check the logs tab for any output

### Step 4: View the Email
1. Copy the `previewUrl` from the response
2. Open it in your browser
3. You should see the formatted email!

## 📧 Expected Success Response

```json
{
  "success": true,
  "messageId": "some-unique-message-id",
  "previewUrl": "https://ethereal.email/message/xxxxx"
}
```

## 🔍 Troubleshooting

### If Function Fails:
1. Check the **"Logs"** tab in the function console
2. Look for error messages in stderr/stdout
3. Verify the function is "Active" and "Enabled"

### If No Preview URL:
1. Check function logs for the preview URL
2. The URL should be logged to stdout like: `Preview URL: https://ethereal.email/message/xxx`

### Common Issues:
- **Timeout**: Function takes too long (increase timeout in settings)
- **Dependencies**: Missing node modules (redeploy the function)
- **Payload**: Invalid JSON format

## 🎯 Your Function is Working If:
- ✅ Function executes without errors
- ✅ Returns success: true
- ✅ Provides a preview URL
- ✅ Email appears in Ethereal Email preview

## 🔗 Quick Links:
- **Function Console**: https://cloud.appwrite.io/console/project-christy-cares-app/functions/68c5c9dc0036c5a66172
- **Functions List**: https://cloud.appwrite.io/console/project-christy-cares-app/functions
- **Project Dashboard**: https://cloud.appwrite.io/console/project-christy-cares-app