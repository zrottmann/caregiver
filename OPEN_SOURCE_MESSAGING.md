# Open-Source Messaging Setup Guide

This guide explains how to set up completely open-source email and SMS messaging for Christy Cares.

## 📧 Email Options (All Open-Source)

### Option 1: Nodemailer Server (Easiest - 5 min setup)
```bash
# Deploy included email server
cd email-server
npm install
npm start

# Or deploy to Vercel (free):
vercel deploy
```

### Option 2: Postal (Professional email server)
```bash
# Docker deployment
docker run -d \
  --name postal \
  -p 25:25 \
  -p 80:80 \
  -p 443:443 \
  postal/postal:latest

# Visit https://github.com/postalhq/postal for full setup
```

### Option 3: Mail-in-a-Box (Complete email solution)
```bash
# One-command setup on Ubuntu
curl -s https://mailinabox.email/setup.sh | sudo bash

# Provides email, webmail, calendar, contacts
# Visit https://github.com/mail-in-a-box/mailinabox
```

### Option 4: Mailu (Docker-based)
```bash
# Docker Compose setup
docker-compose up -d

# Full email stack with web interface
# Visit https://github.com/Mailu/Mailu
```

### Option 5: MailHog (Development/Testing)
```bash
# For local development
docker run -p 1025:1025 -p 8025:8025 mailhog/mailhog

# Catches all emails for testing
# Visit https://github.com/mailhog/MailHog
```

## 📱 SMS Options (All Open-Source)

### Option 1: TextBelt (Free tier available)
- **GitHub**: https://github.com/typpo/textbelt
- **Free**: 1 SMS per day per IP
- **Setup**: Just use key `'textbelt'` in the code
- **Paid**: Buy credits at textbelt.com

### Option 2: Jasmin SMS Gateway (Self-hosted)
```bash
# Docker deployment
docker run -d \
  -p 2775:2775 \
  -p 1401:1401 \
  -p 8990:8990 \
  jookies/jasmin:latest

# Professional SMS gateway
# Visit https://github.com/jookies/jasmin
```

### Option 3: Kannel (Enterprise-grade)
```bash
# Install on Ubuntu
sudo apt-get install kannel

# Configure with your SMS provider
# Visit https://github.com/isacikgoz/kannel
```

### Option 4: PlaySMS (Web platform)
```bash
# Docker deployment
docker run -d \
  -p 80:80 \
  playsms/playsms:latest

# Full web interface for SMS management
# Visit https://github.com/playsms/playsms
```

### Option 5: Android Phone as Gateway
Using Termux on Android:
```bash
# Install Termux app
# Install termux-api
pkg install termux-api

# Send SMS from your server to phone
# Visit https://github.com/termux/termux-sms-send
```

## 🔔 Push Notifications (Bonus)

### Gotify (Self-hosted push server)
```bash
docker run -p 80:80 -v /var/gotify/data:/app/data gotify/server

# Visit https://github.com/gotify/server
```

### Novu (Notification infrastructure)
```bash
npm install @novu/node

# Visit https://github.com/novuhq/novu
```

### Apprise (80+ notification services)
```bash
pip install apprise

# Visit https://github.com/caronc/apprise
```

## 🚀 Quick Start (5 Minutes)

### 1. Email Setup (Using Nodemailer)
```bash
# Navigate to email server
cd caregiver_platform/email-server

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your Gmail app password
# (Get app password: Google Account → Security → 2FA → App passwords)

# Start server
npm start

# Your email endpoint is ready at http://localhost:3000/send
```

### 2. SMS Setup (Using TextBelt)
```javascript
// Already configured in messaging_service.dart
// Uses free tier (1 SMS/day) with key: 'textbelt'
// No additional setup needed!
```

### 3. Deploy to Production

#### Email (Vercel - Free)
```bash
cd email-server
npm i -g vercel
vercel

# Follow prompts, get your URL
# Update messaging_config.dart with your URL
```

#### SMS (TextBelt)
- Free tier: Keep using 'textbelt' key
- Paid: Buy credits at https://textbelt.com
- Self-hosted: Deploy TextBelt server from GitHub

## 💰 Cost Comparison

| Service | Proprietary | Open-Source |
|---------|-------------|-------------|
| **Email** | | |
| SendGrid | $15-20/mo | - |
| Mailgun | $15-35/mo | - |
| **Our Options** | | |
| Nodemailer + Gmail | - | Free |
| Postal (self-hosted) | - | $5/mo VPS |
| Mail-in-a-Box | - | $10/mo VPS |
| **SMS** | | |
| Twilio | $0.0075/SMS | - |
| Vonage | $0.0058/SMS | - |
| **Our Options** | | |
| TextBelt | - | Free (1/day) or $0.03/SMS |
| Jasmin (self-hosted) | - | $10/mo VPS + carrier rates |
| Android Gateway | - | Your phone plan |

## 🔒 Privacy Benefits

Using open-source solutions means:
- ✅ No vendor lock-in
- ✅ Complete data control
- ✅ No tracking or analytics
- ✅ Can audit the code
- ✅ Self-host in any country
- ✅ HIPAA compliant (with proper setup)

## 📝 Configuration

Update `lib/config/messaging_config.dart`:
```dart
// For email
static const String emailApiEndpoint = 'YOUR_VERCEL_URL/send';

// For SMS (already configured)
static const String textbeltKey = 'textbelt'; // or your paid key
```

## 🧪 Testing

1. **Email Test**:
```bash
curl -X POST http://localhost:3000/send \
  -H "Content-Type: application/json" \
  -d '{
    "to": "test@example.com",
    "subject": "Test Email",
    "text": "Hello from Christy Cares!"
  }'
```

2. **SMS Test**:
```bash
curl -X POST https://textbelt.com/text \
  -d phone=+1234567890 \
  -d message="Test SMS" \
  -d key=textbelt
```

## 🆘 Support

- **Nodemailer**: https://nodemailer.com/about/
- **TextBelt**: https://github.com/typpo/textbelt/issues
- **Postal**: https://docs.postalserver.io/
- **Mail-in-a-Box**: https://discourse.mailinabox.email/

Choose the option that best fits your needs. All are production-ready and actively maintained! 🚀