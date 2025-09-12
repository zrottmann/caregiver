# Appwrite Setup Guide

This guide will help you set up Appwrite for the Caregiver Platform app.

## 📋 Prerequisites

- Appwrite Cloud account OR self-hosted Appwrite instance
- Basic understanding of databases and collections

## 🚀 Quick Setup

### 1. Create Appwrite Project

1. Go to [Appwrite Cloud](https://cloud.appwrite.io) or your self-hosted Appwrite console
2. Click "Create Project"
3. Enter project name: "Caregiver Platform"
4. Note your Project ID and Endpoint URL

### 2. Configure App Integration

#### Add Platform

1. Go to "Settings" → "Platforms"
2. Click "Add Platform"

**For Flutter (Android):**
- Select "Flutter (Android)"
- Package Name: `com.example.caregiver_platform` (or your custom package)
- SHA1 Certificate Fingerprints: (optional for development)

**For Flutter (iOS):**
- Select "Flutter (iOS)"
- Bundle ID: `com.example.caregiverPlatform` (or your custom bundle ID)

**For Flutter (Web):**
- Select "Flutter (Web)"
- Hostname: `localhost` (for development)

### 3. Enable Services

Go to your project dashboard and ensure these services are enabled:
- ✅ Authentication (Account)
- ✅ Database
- ✅ Storage
- ✅ Realtime
- ⚠️ Functions (optional)

## 🗄️ Database Setup

### Create Database

1. Go to "Database" section
2. Click "Create Database"
3. Database ID: `caregiver-platform`
4. Name: `Caregiver Platform`

### Create Collections

#### 1. User Profiles Collection

**Collection Details:**
- Collection ID: `profiles`
- Name: `User Profiles`
- Permissions: 
  - Read: `role:all`
  - Write: `users`

**Attributes:**
```json
[
  {
    "key": "userId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "name",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "email",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "role",
    "type": "string",
    "size": 50,
    "required": true,
    "array": false
  },
  {
    "key": "bio",
    "type": "string",
    "size": 1000,
    "required": false,
    "array": false
  },
  {
    "key": "location",
    "type": "string",
    "size": 255,
    "required": false,
    "array": false
  },
  {
    "key": "phoneNumber",
    "type": "string",
    "size": 50,
    "required": false,
    "array": false
  },
  {
    "key": "profileImageUrl",
    "type": "string",
    "size": 500,
    "required": false,
    "array": false
  },
  {
    "key": "services",
    "type": "string",
    "size": 100,
    "required": false,
    "array": true
  },
  {
    "key": "hourlyRate",
    "type": "double",
    "required": false,
    "array": false
  },
  {
    "key": "rating",
    "type": "double",
    "required": false,
    "array": false
  },
  {
    "key": "reviewCount",
    "type": "integer",
    "required": false,
    "array": false
  },
  {
    "key": "createdAt",
    "type": "datetime",
    "required": true,
    "array": false
  },
  {
    "key": "updatedAt",
    "type": "datetime",
    "required": true,
    "array": false
  }
]
```

**Indexes:**
- `role` (for filtering caregivers)
- `location` (for location-based search)
- `rating` (for sorting by rating)

#### 2. Bookings Collection

**Collection Details:**
- Collection ID: `bookings`
- Name: `Bookings`
- Permissions: 
  - Read: `users`
  - Write: `users`

**Attributes:**
```json
[
  {
    "key": "patientId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "caregiverId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "patientName",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "caregiverName",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "scheduledDate",
    "type": "datetime",
    "required": true,
    "array": false
  },
  {
    "key": "timeSlot",
    "type": "string",
    "size": 100,
    "required": true,
    "array": false
  },
  {
    "key": "description",
    "type": "string",
    "size": 1000,
    "required": true,
    "array": false
  },
  {
    "key": "services",
    "type": "string",
    "size": 100,
    "required": false,
    "array": true
  },
  {
    "key": "totalAmount",
    "type": "double",
    "required": true,
    "array": false
  },
  {
    "key": "status",
    "type": "string",
    "size": 50,
    "required": true,
    "array": false
  },
  {
    "key": "notes",
    "type": "string",
    "size": 1000,
    "required": false,
    "array": false
  },
  {
    "key": "paymentIntentId",
    "type": "string",
    "size": 255,
    "required": false,
    "array": false
  },
  {
    "key": "createdAt",
    "type": "datetime",
    "required": true,
    "array": false
  },
  {
    "key": "updatedAt",
    "type": "datetime",
    "required": true,
    "array": false
  }
]
```

**Indexes:**
- `patientId` (for patient bookings)
- `caregiverId` (for caregiver bookings)
- `status` (for filtering by status)
- `scheduledDate` (for date-based queries)

#### 3. Chats Collection

**Collection Details:**
- Collection ID: `chats`
- Name: `Chats`
- Permissions: 
  - Read: `users`
  - Write: `users`

**Attributes:**
```json
[
  {
    "key": "bookingId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "patientId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "caregiverId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "patientName",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "caregiverName",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "createdAt",
    "type": "datetime",
    "required": true,
    "array": false
  },
  {
    "key": "updatedAt",
    "type": "datetime",
    "required": true,
    "array": false
  }
]
```

**Indexes:**
- `bookingId` (unique chat per booking)
- `patientId` (for user's chats)
- `caregiverId` (for caregiver's chats)

#### 4. Messages Collection

**Collection Details:**
- Collection ID: `messages`
- Name: `Messages`
- Permissions: 
  - Read: `users`
  - Write: `users`

**Attributes:**
```json
[
  {
    "key": "chatId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "senderId",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "senderName",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false
  },
  {
    "key": "content",
    "type": "string",
    "size": 2000,
    "required": true,
    "array": false
  },
  {
    "key": "type",
    "type": "string",
    "size": 50,
    "required": true,
    "array": false
  },
  {
    "key": "timestamp",
    "type": "datetime",
    "required": true,
    "array": false
  },
  {
    "key": "isRead",
    "type": "boolean",
    "required": false,
    "array": false,
    "default": false
  }
]
```

**Indexes:**
- `chatId` (for chat messages)
- `senderId` (for sender's messages)
- `timestamp` (for chronological order)

## 🗂️ Storage Setup

### Create Storage Bucket

1. Go to "Storage" section
2. Click "Create Bucket"
3. Bucket ID: `profile-images`
4. Name: `Profile Images`
5. Permissions:
   - Read: `role:all` (public read for profile images)
   - Write: `users` (authenticated users can upload)

**Settings:**
- Maximum File Size: 5MB
- Allowed File Extensions: `jpg,jpeg,png,gif`
- Compression: Quality 80%
- Antivirus: Enabled (if available)

## 🔐 Authentication Setup

### Configure Auth Settings

1. Go to "Auth" section
2. Click "Settings"

**Security Settings:**
- Session Length: 365 days
- Password History: 5 passwords
- Password Dictionary: Enabled
- Personal Data: Enabled

**Email Templates:**
Customize the email templates for:
- Email Verification
- Password Reset
- Magic URL

### OAuth Providers (Optional)

Enable OAuth providers as needed:
- Google
- Apple
- Facebook
- GitHub

## 📡 Realtime Setup

### Configure Realtime

1. Go to "Realtime" section
2. Ensure it's enabled for your project

**Channels to Subscribe:**
- `databases.caregiver-platform.collections.messages.documents`
- `databases.caregiver-platform.collections.chats.documents`

## ⚡ Functions Setup (Optional)

For advanced features, you can create Appwrite Functions:

### Payment Processing Function

Create a function to handle Stripe webhooks:

```javascript
const stripe = require('stripe')(req.env.STRIPE_SECRET_KEY);

module.exports = async function (req, res) {
  const sig = req.headers['stripe-signature'];
  
  try {
    const event = stripe.webhooks.constructEvent(
      req.rawBody, 
      sig, 
      req.env.STRIPE_WEBHOOK_SECRET
    );
    
    if (event.type === 'payment_intent.succeeded') {
      // Update booking status in database
      const paymentIntent = event.data.object;
      const bookingId = paymentIntent.metadata.booking_id;
      
      // Update booking status logic here
    }
    
    res.json({ received: true });
  } catch (err) {
    res.status(400).send(`Webhook Error: ${err.message}`);
  }
};
```

## 🔧 Environment Variables

Set these environment variables in your Appwrite Functions:

```bash
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

## ✅ Verification Checklist

Before using the app, verify:

- [ ] Database created with correct ID
- [ ] All 4 collections created with proper attributes
- [ ] Indexes created for better performance
- [ ] Storage bucket created for profile images
- [ ] Permissions set correctly for each collection
- [ ] Realtime enabled for chat functionality
- [ ] Platform configurations added for your target platforms

## 🚨 Security Considerations

### Production Checklist

- [ ] Update all permissions to be more restrictive
- [ ] Enable rate limiting
- [ ] Set up proper CORS policies
- [ ] Configure secure headers
- [ ] Enable audit logs
- [ ] Set up monitoring and alerts

### Recommended Permissions

**For Production:**
```
profiles:
  Read: role:all
  Write: user:{userId}

bookings:
  Read: user:{patientId}, user:{caregiverId}
  Write: user:{patientId}, user:{caregiverId}

chats:
  Read: user:{patientId}, user:{caregiverId}
  Write: user:{patientId}, user:{caregiverId}

messages:
  Read: user:{senderId}
  Write: user:{senderId}
```

## 🔄 Backup Strategy

Set up regular backups:
1. Database exports (weekly)
2. Storage bucket backups (daily)
3. Configuration backups (monthly)

## 📞 Support

If you need help with Appwrite setup:
- [Appwrite Documentation](https://appwrite.io/docs)
- [Appwrite Discord Community](https://appwrite.io/discord)
- [Appwrite GitHub Issues](https://github.com/appwrite/appwrite/issues)