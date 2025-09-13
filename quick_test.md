# 🚀 Quick Function Test

## Test Your GitHub-Deployed Email Function

### Method 1: Appwrite Console (Easiest)

1. **Open Function Console:**
   https://cloud.appwrite.io/console/project-christy-cares-app/functions/68c5c9dc0036c5a66172

2. **Click "Execute" tab**

3. **Paste this payload:**
```json
{
  "to": "test@christy-cares.com",
  "subject": "🎉 GitHub Function Test",
  "content": "Success! Your GitHub-deployed function is working!\n\nThis email has:\n✅ Professional Christy Cares branding\n✅ Gradient header design\n✅ Clean content layout\n✅ Contact footer\n\nFunction ID: 68c5c9dc0036c5a66172\nRepository: zrottmann/christy-cares-functions"
}
```

4. **Click "Execute Function"**

5. **Look for:**
   - ✅ Status: Success
   - ✅ Response with `"success": true`
   - ✅ `previewUrl` in the response
   - ✅ Click the preview URL to see the formatted email

### Expected Success Response:
```json
{
  "success": true,
  "messageId": "unique-message-id",
  "previewUrl": "https://ethereal.email/message/xxxxx"
}
```

### Method 2: Function Logs
- Check the "Logs" tab to see console output
- Look for "Preview URL: https://ethereal.email/message/..."

## 🎯 What Success Looks Like:

**In the email preview, you should see:**
- 🎨 Beautiful gradient header (teal to purple)
- 🏢 "Christy Cares" branding
- 📝 Your message in a clean white box
- 📞 Professional footer with contact info

## ❌ If It Fails:
- Check the "Logs" tab for errors
- Verify the GitHub deployment completed
- Ensure the function is "Active" and "Enabled"

Try it now and let me know what response you get! 🚀