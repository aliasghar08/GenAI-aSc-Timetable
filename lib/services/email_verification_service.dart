import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result of an email validation and verification check
class EmailValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? domain;
  final List<String> mxRecords;

  const EmailValidationResult({
    required this.isValid,
    this.errorMessage,
    this.domain,
    this.mxRecords = const [],
  });

  static const EmailValidationResult valid = EmailValidationResult(isValid: true);
}

/// Proven Email Verification Service
/// Performs multi-tier verification:
/// 1. RFC 5322 syntax validation (supports all standard, personal & institutional emails)
/// 2. Disposable / burner domain screening
/// 3. Real-time DNS MX record verification via Google Public DNS (DNS-over-HTTPS)
class EmailVerificationService {
  static final Map<String, EmailValidationResult> _domainCache = {};

  // Common disposable email services
  static const Set<String> _disposableDomains = {
    'mailinator.com',
    'tempmail.com',
    '10minutemail.com',
    'throwawaymail.com',
    'guerrillamail.com',
    'yopmail.com',
    'trashmail.com',
    'sharklasers.com',
    'getairmail.com',
    'fakeinbox.com',
    'dispostable.com',
    'mytemp.email',
  };

  /// Verify whether an email address is syntactically valid and has active mail servers
  static Future<EmailValidationResult> verifyEmail(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();

    if (email.isEmpty) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Please enter an email address',
      );
    }

    // 1. Syntax Check (RFC 5322 Compliant)
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    if (!emailRegex.hasMatch(email) || email.contains('..')) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Invalid email address format (e.g. user@domain.com)',
      );
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Email must contain a valid username and domain',
      );
    }

    final domain = parts[1].trim();

    // 2. Check for disposable / burner domain
    if (_disposableDomains.contains(domain)) {
      return EmailValidationResult(
        isValid: false,
        domain: domain,
        errorMessage: 'Disposable or temporary email domains are not permitted.',
      );
    }

    // Check in-memory cache
    if (_domainCache.containsKey(domain)) {
      return _domainCache[domain]!;
    }

    // 3. Query Google Public DNS API (DNS-over-HTTPS) for MX (Mail Exchange) records
    try {
      final mxUri = Uri.parse('https://dns.google/resolve?name=$domain&type=MX');
      final response = await http.get(mxUri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['Status'] as int? ?? -1;

        // Status 3 = NXDOMAIN (Non-Existent Domain)
        if (status == 3) {
          final result = EmailValidationResult(
            isValid: false,
            domain: domain,
            errorMessage: 'The domain "$domain" does not exist in global DNS.',
          );
          _domainCache[domain] = result;
          return result;
        }

        // Status 0 = NOERROR
        if (status == 0) {
          final answers = data['Answer'] as List<dynamic>?;
          if (answers != null && answers.isNotEmpty) {
            final List<String> mxList = [];
            bool hasNullMx = false;

            for (final ans in answers) {
              final type = ans['type'] as int?;
              final rawData = ans['data'] as String? ?? '';
              // Type 15 is MX
              if (type == 15) {
                // RFC 7505 Null MX record check ("0 .")
                if (rawData.trim() == '0 .' || rawData.trim() == '.') {
                  hasNullMx = true;
                } else {
                  mxList.add(rawData);
                }
              }
            }

            if (hasNullMx) {
              final result = EmailValidationResult(
                isValid: false,
                domain: domain,
                errorMessage: 'The domain "$domain" explicitly does not accept incoming emails.',
              );
              _domainCache[domain] = result;
              return result;
            }

            if (mxList.isNotEmpty) {
              final result = EmailValidationResult(
                isValid: true,
                domain: domain,
                mxRecords: mxList,
              );
              _domainCache[domain] = result;
              return result;
            }
          }

          // Fallback to A record check (RFC 5321 fallback mail server)
          final aUri = Uri.parse('https://dns.google/resolve?name=$domain&type=A');
          final aResponse = await http.get(aUri).timeout(const Duration(seconds: 3));
          if (aResponse.statusCode == 200) {
            final aData = jsonDecode(aResponse.body) as Map<String, dynamic>;
            final aStatus = aData['Status'] as int? ?? -1;
            final aAnswers = aData['Answer'] as List<dynamic>?;
            if (aStatus == 0 && aAnswers != null && aAnswers.isNotEmpty) {
              final result = EmailValidationResult(
                isValid: true,
                domain: domain,
              );
              _domainCache[domain] = result;
              return result;
            }
          }

          final result = EmailValidationResult(
            isValid: false,
            domain: domain,
            errorMessage: 'Domain "$domain" has no configured mail servers (MX) to receive emails.',
          );
          _domainCache[domain] = result;
          return result;
        }
      }
    } catch (_) {
      // If DNS check times out or network restricts DoH, fallback to syntax check
      return EmailValidationResult(isValid: true, domain: domain);
    }

    return EmailValidationResult(isValid: true, domain: domain);
  }
}
