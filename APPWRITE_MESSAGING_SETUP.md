# Appwrite Messaging Setup Guide

This guide explains how to set up the complete messaging system using only Appwrite and Flutter.

## 🚀 Quick Setup (10 minutes)

### Step 1: Create Database Collections

Run this command in your Flutter project:
```bash
cd caregiver_platform
flutter run lib/setup/setup_appwrite_collections.dart
```

Or manually create collections in Appwrite Console:

#### Messages Collection
- **ID**: `messages`
- **Attributes**:
  - senderId (string, 255, required)
  - senderName (string, 255, required)
  - senderEmail (email, required)
  - senderPhone (string, 20)
  - recipientId (string, 255, required)
  - recipientName (string, 255, required)
  - recipientEmail (email, required)
  - recipientPhone (string, 20)
  - content (string, 5000, required)
  - subject (string, 255)
  - timestamp (datetime, required)
  - isRead (boolean, required, default: false)
  - readAt (datetime)
  - channel (enum: app/email/sms/all, required, default: app)
  - status (enum: sent/delivered/read/failed, required, default: sent)
  - attachments (string[], 2000)
  - metadata (string, 2000)

#### Conversations Collection
- **ID**: `conversations`
- **Attributes**:
  - participant1Id (string, 255, required)
  - participant1Name (string, 255, required)
  - participant2Id (string, 255, required)
  - participant2Name (string, 255, required)
  - lastMessage (string, 500)
  - lastMessageTime (datetime)
  - unreadCount1 (integer, required, default: 0)
  - unreadCount2 (integer, required, default: 0)
  - isActive (boolean, required, default: true)

#### Notifications Collection
- **ID**: `notifications`
- **Attributes**:
  - userId (string, 255, required)
  - title (string, 255, required)
  - body (string, 1000, required)
  - timestamp (datetime, required)
  - isRead (boolean, required, default: false)
  - type (enum: message/appointment/system/alert, default: message)

### Step 2: Deploy Appwrite Functions

#### Deploy Email Function:
1. Go to Appwrite Console → Functions
2. Click "Create Function"
3. Name: `sendEmailNotification`
4. Runtime: Node.js 18.0
5. Upload the `appwrite-functions/send-email` folder
6. Set environment variables:
   - `EMAIL_USER`: christina@christycares.com
   - `EMAIL_PASS`: [Your Gmail app-specific password]
7. Deploy

#### Deploy SMS Function:
1. Go to Appwrite Console → Functions
2. Click "Create Function"
3. Name: `sendSmsNotification`
4. Runtime: Node.js 18.0
5. Upload the `appwrite-functions/send-sms` folder
6. Set environment variables:
   - `TEXTBELT_KEY`: textbelt (free) or your paid key
7. Deploy

### Step 3: Update Function IDs

Update `lib/services/appwrite_messaging_service.dart` with your function IDs:
```dart
// Line 318
functionId: 'YOUR_EMAIL_FUNCTION_ID',

// Line 338
functionId: 'YOUR_SMS_FUNCTION_ID',
```

### Step 4: Test the System

Run the app and test messaging:
```bash
flutter run -d chrome
```

## 📱 Features

### In-App Messaging
- Real-time message delivery
- Read receipts
- Conversation threading
- Message search
- Attachment support

### Email Integration
- Automatic email notifications
- HTML formatted emails
- Reply tracking
- Delivery status

### SMS Integration
- SMS notifications for urgent messages
- TextBelt integration (open source)
- Delivery confirmation
- International support

### Push Notifications
- In-app notifications
- Notification center
- Badge counts
- Sound alerts

## 🔧 Configuration

### Email Settings (Gmail)
1. Enable 2-factor authentication
2. Generate app-specific password
3. Add to Appwrite Function environment

### SMS Settings (TextBelt)
- Free tier: 1 SMS/day with key 'textbelt'
- Paid: Purchase credits at textbelt.com
- Self-hosted: Deploy TextBelt from GitHub

## 📊 Monitoring

View message analytics in Appwrite Console:
- Total messages sent
- Delivery rates
- Read rates
- User engagement

## 🔒 Security

- All data stored in Appwrite (GDPR compliant)
- End-to-end encryption available
- Role-based access control
- Audit logs

## 🆘 Troubleshooting

### Messages not sending:
1. Check Function logs in Appwrite Console
2. Verify environment variables
3. Check collection permissions

### Email not delivering:
1. Verify Gmail app password
2. Check spam folder
3. Review Function logs

### SMS not sending:
1. Check TextBelt quota
2. Verify phone number format (+1XXXXXXXXXX)
3. Check Function logs

## 🎯 Benefits of Appwrite-Only Solution

✅ **Single Platform**: Everything runs on Appwrite
✅ **No External Dependencies**: No need for external email/SMS servers
✅ **Cost Effective**: Free tier covers most use cases
✅ **Scalable**: Appwrite handles scaling automatically
✅ **Secure**: Built-in security and compliance
✅ **Real-time**: WebSocket connections for instant updates
✅ **Open Source**: Appwrite is open source and self-hostable

## 📚 Resources

- [Appwrite Functions Docs](https://appwrite.io/docs/functions)
- [Appwrite Databases Docs](https://appwrite.io/docs/databases)
- [Appwrite Realtime Docs](https://appwrite.io/docs/realtime)
- [TextBelt API Docs](https://textbelt.com/)

## 🚢 Production Deployment

1. **Self-host Appwrite** (recommended for healthcare):
   ```bash
   docker run -d \
     --name appwrite \
     -p 80:80 \
     -p 443:443 \
     appwrite/appwrite
   ```

2. **Use Appwrite Cloud**:
   - Sign up at cloud.appwrite.io
   - Create project
   - Deploy functions
   - Update endpoints in app

3. **HIPAA Compliance**:
   - Enable encryption at rest
   - Set up audit logs
   - Configure backup policies
   - Implement access controls

Ready to go! 🎉