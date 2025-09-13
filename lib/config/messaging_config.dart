/// Open-Source Messaging Configuration
///
/// This file contains configuration for open-source email and SMS solutions.
/// Choose the option that best fits your needs and infrastructure.

class MessagingConfig {
  // ============================================================================
  // EMAIL CONFIGURATION - Choose one option
  // ============================================================================

  // Option 1: Nodemailer API (Recommended for easy setup)
  // GitHub: https://github.com/nodemailer/nodemailer
  // Deploy a simple Node.js server with this endpoint
  static const String emailApiEndpoint = 'https://your-email-api.vercel.app/send';

  // Option 2: Postal (Full-featured email server)
  // GitHub: https://github.com/postalhq/postal
  // Self-hosted complete email delivery platform
  static const String postalEndpoint = 'https://postal.yourdomain.com/api/v1/send';
  static const String postalApiKey = 'your-postal-api-key';

  // Option 3: Mail-in-a-Box (Complete email solution)
  // GitHub: https://github.com/mail-in-a-box/mailinabox
  // Full email server with webmail, SMTP, IMAP
  static const String mailInABoxSmtp = 'mail.yourdomain.com';
  static const String mailInABoxPort = '587';

  // Option 4: Mailu (Docker-based email server)
  // GitHub: https://github.com/Mailu/Mailu
  // Easy to deploy with Docker
  static const String mailuSmtp = 'mail.yourdomain.com';
  static const String mailuPort = '587';

  // Option 5: Use Appwrite's built-in email (simplest)
  // Already integrated with your Appwrite instance
  static const bool useAppwriteEmail = true;

  // ============================================================================
  // SMS CONFIGURATION - Choose one option
  // ============================================================================

  // Option 1: TextBelt (Easiest - 1 free SMS/day)
  // GitHub: https://github.com/typpo/textbelt
  static const String textbeltEndpoint = 'https://textbelt.com/text';
  static const String textbeltKey = 'textbelt'; // 'textbelt' for free, or your paid key

  // Option 2: Jasmin SMS Gateway (Self-hosted, powerful)
  // GitHub: https://github.com/jookies/jasmin
  // Professional open-source SMS gateway
  static const String jasminEndpoint = 'http://your-jasmin-server:1401/send';
  static const String jasminUsername = 'your-username';
  static const String jasminPassword = 'your-password';

  // Option 3: Kannel (Enterprise-grade gateway)
  // GitHub: https://github.com/isacikgoz/kannel
  // Very robust, used by telecom companies
  static const String kannelEndpoint = 'http://your-kannel-server:13013/cgi-bin/sendsms';
  static const String kannelUsername = 'your-username';
  static const String kannelPassword = 'your-password';

  // Option 4: PlaySMS (Web-based platform)
  // GitHub: https://github.com/playsms/playsms
  // Complete web interface for SMS management
  static const String playsmsEndpoint = 'https://your-playsms.com/api';
  static const String playsmsToken = 'your-api-token';

  // Option 5: Termux (Android-based gateway)
  // GitHub: https://github.com/termux/termux-sms-send
  // Use an Android phone as SMS gateway
  static const String termuxEndpoint = 'http://your-phone-ip:8080/sms';

  // ============================================================================
  // NOTIFICATION OPTIONS
  // ============================================================================

  // Option 1: Gotify (Self-hosted push notifications)
  // GitHub: https://github.com/gotify/server
  static const String gotifyEndpoint = 'https://gotify.yourdomain.com';
  static const String gotifyAppToken = 'your-app-token';

  // Option 2: Novu (Open-source notification infrastructure)
  // GitHub: https://github.com/novuhq/novu
  static const String novuApiKey = 'your-novu-api-key';

  // Option 3: Apprise (Notification library supporting 80+ services)
  // GitHub: https://github.com/caronc/apprise
  static const String appriseEndpoint = 'http://your-apprise-server:8000/notify';

  // ============================================================================
  // SIMPLE SETUP INSTRUCTIONS
  // ============================================================================

  /// Quick Start Guide:
  ///
  /// 1. For Email (easiest setup):
  ///    - Create a free Vercel account
  ///    - Deploy this simple Nodemailer endpoint:
  ///      https://github.com/vercel/examples/tree/main/edge-functions/api-route
  ///    - Update emailApiEndpoint with your URL
  ///
  /// 2. For SMS (free option):
  ///    - TextBelt gives 1 free SMS per day
  ///    - Just use key: 'textbelt'
  ///    - For more, get a key at textbelt.com
  ///
  /// 3. For Production (self-hosted):
  ///    - Deploy Postal for email (Docker: postal/postal)
  ///    - Deploy Jasmin for SMS (Docker: jookies/jasmin)
  ///    - Both are production-ready and well-documented

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static Map<String, String> getEmailConfig() {
    if (useAppwriteEmail) {
      return {
        'provider': 'appwrite',
        'endpoint': 'built-in',
      };
    }
    return {
      'provider': 'nodemailer',
      'endpoint': emailApiEndpoint,
    };
  }

  static Map<String, String> getSmsConfig() {
    return {
      'provider': 'textbelt',
      'endpoint': textbeltEndpoint,
      'key': textbeltKey,
    };
  }
}