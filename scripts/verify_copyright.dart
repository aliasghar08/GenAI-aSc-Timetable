import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main() {
  stdout.writeln('================================================================');
  stdout.writeln('   GenAI x aSc Timetable — Cryptographic Copyright Validator   ');
  stdout.writeln('================================================================');

  const expectedAuthor = 'Ali Asghar';
  const expectedGithub = 'aliasghar08';
  const expectedEmail = 'aliasgharinnocent@yahoo.com';
  const expectedRepo = 'https://github.com/aliasghar08/GenAI-aSc-Timetable';
  const expectedHash = 'ef6ea8acc857b9b818cb906c936a6d7ff026b9af9cf2e5a6e0638e37a37e67ea';
  const genesisSecret = '0x9F4C2A7E8B1D6F03E';

  final payload =
      'AUTH:$expectedAuthor<$expectedEmail>|GH:$expectedGithub|REPO:$expectedRepo|PROJECT:GenAI-aSc-Timetable|GENESIS:2026-10-15T18:10:00Z|SECRET:$genesisSecret';

  final bytes = utf8.encode(payload);
  final digest = sha256.convert(bytes);
  final calculatedHash = digest.toString();

  stdout.writeln('Author Verification : $expectedAuthor (@$expectedGithub)');
  stdout.writeln('Registered Contact  : $expectedEmail');
  stdout.writeln('Canonical Repo      : $expectedRepo');
  stdout.writeln('Certificate Digest  : $calculatedHash');

  if (calculatedHash == expectedHash) {
    stdout.writeln('\n[PASSED] ✅ Cryptographic signature matches author genesis record.');
    stdout.writeln('[LEGAL]  ⚖️ Authentic intellectual property of Ali Asghar.');
    exit(0);
  } else {
    stderr.writeln('\n[FAILED] ❌ Signature mismatch! Unauthorized repackaging or tampering detected.');
    exit(1);
  }
}
