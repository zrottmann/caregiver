@echo off
echo 🧪 Testing Email Function via Appwrite API...
echo.

curl -X POST ^
  "https://cloud.appwrite.io/v1/functions/68c5c9dc0036c5a66172/executions" ^
  -H "Content-Type: application/json" ^
  -H "X-Appwrite-Project: 689fd36e0032936147b1" ^
  -d "{\"body\": \"{\\\"to\\\": \\\"test@christy-cares.com\\\", \\\"subject\\\": \\\"🧪 Function Test from Claude Code\\\", \\\"content\\\": \\\"Hello!\\n\\nThis is a test email executed directly to verify your GitHub-deployed Appwrite function.\\n\\n✅ Function ID: 68c5c9dc0036c5a66172\\n✅ Repository: zrottmann/christy-cares-functions\\n✅ Branch: master\\n\\nIf you're seeing this with beautiful Christy Cares branding, your function is working perfectly!\\n\\nBest regards,\\nClaude Code Testing System\\\"}\"}"

echo.
echo.
echo ✅ Function execution request sent!
echo Check the response above for success status and preview URL.
pause