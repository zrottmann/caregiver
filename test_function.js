const https = require('https');

// Test the email function directly
async function testEmailFunction() {
  console.log('🧪 Testing GitHub-deployed Email Function...\n');

  const functionId = '68c5c9dc0036c5a66172';
  const projectId = '689fd36e0032936147b1';

  const testPayload = {
    to: 'test@christy-cares.com',
    subject: '🧪 Function Test from Claude Code',
    content: `Hello!

This is a test email executed directly to verify your GitHub-deployed Appwrite function.

✅ Function ID: ${functionId}
✅ Repository: zrottmann/christy-cares-functions
✅ Branch: master
✅ Deployment: GitHub integration

If you're seeing this with beautiful Christy Cares branding, your function is working perfectly!

Features to check:
- Professional gradient header
- Christy Cares logo and branding
- Clean white content box
- Professional footer
- Preview URL in response

Best regards,
Claude Code Testing System`
  };

  const payload = JSON.stringify({ body: JSON.stringify(testPayload) });

  const options = {
    hostname: 'cloud.appwrite.io',
    port: 443,
    path: `/v1/functions/${functionId}/executions`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'Content-Length': Buffer.byteLength(payload)
    }
  };

  console.log('📧 Test Payload:');
  console.log(JSON.stringify(testPayload, null, 2));
  console.log('\n🚀 Executing function...\n');

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log(`📊 Response Status: ${res.statusCode}`);
        console.log('📨 Response Headers:', res.headers);
        console.log('\n📋 Response Body:');

        try {
          const response = JSON.parse(data);
          console.log(JSON.stringify(response, null, 2));

          if (response.$id) {
            console.log(`\n✅ Execution Created: ${response.$id}`);
            console.log(`📊 Status: ${response.status || 'pending'}`);

            if (response.responseBody) {
              console.log('\n📧 Function Response:');
              try {
                const functionResponse = JSON.parse(response.responseBody);
                console.log(JSON.stringify(functionResponse, null, 2));

                if (functionResponse.success) {
                  console.log('\n🎉 SUCCESS! Function executed successfully!');
                  if (functionResponse.previewUrl) {
                    console.log(`\n🔗 Preview URL: ${functionResponse.previewUrl}`);
                    console.log('   👆 Click this URL to see the formatted email!');
                  }
                } else {
                  console.log('\n❌ Function returned error:', functionResponse.error);
                }
              } catch (e) {
                console.log(response.responseBody);
              }
            }

            if (response.stdout) {
              console.log('\n📝 Function Logs (stdout):');
              console.log(response.stdout);
            }

            if (response.stderr) {
              console.log('\n⚠️  Function Logs (stderr):');
              console.log(response.stderr);
            }
          } else {
            console.log('\n❌ Unexpected response format');
          }

        } catch (e) {
          console.log('Raw response:', data);
          console.log('Parse error:', e.message);
        }

        resolve(data);
      });
    });

    req.on('error', (e) => {
      console.error('\n❌ Request Error:', e.message);

      if (e.message.includes('ENOTFOUND')) {
        console.log('\n🔧 Troubleshooting:');
        console.log('- Check your internet connection');
        console.log('- Verify the Appwrite endpoint is correct');
      }

      reject(e);
    });

    req.write(payload);
    req.end();
  });
}

// Run the test
console.log('🎯 Testing your GitHub-deployed Appwrite function...');
console.log('='.repeat(60));

testEmailFunction().catch(error => {
  console.error('\n💥 Test failed:', error.message);

  console.log('\n🔧 Alternative Testing Methods:');
  console.log('1. Use Appwrite Console: https://cloud.appwrite.io/console/project-christy-cares-app/functions/68c5c9dc0036c5a66172');
  console.log('2. Test via Flutter app once it\'s running');
  console.log('3. Check function logs in Appwrite Console');
});