import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> validatePinnedCertificate(String domain, int port) async {
  try {
    final certBytes = await rootBundle.load('assets/certificates/certificate.der');
    final pinnedCertDer = certBytes.buffer.asUint8List();
    final pinnedSha256 = sha256.convert(pinnedCertDer).bytes;

    final socket = await SecureSocket.connect(
      domain,
      port,
      timeout: Duration(seconds: 5),
      onBadCertificate: (X509Certificate cert) {
        final serverCertSha256 = sha256.convert(cert.der).bytes;

        debugPrint("Pinned SHA256: ${base64.encode(pinnedSha256)}");
        debugPrint("Server SHA256: ${base64.encode(serverCertSha256)}");

        final isValid = _bytesEqual(serverCertSha256, pinnedSha256);
        print(isValid ? "Pinned certificate matched." : "Pinned certificate did NOT match.");
        return isValid; 
      },
    );

    // If no bad cert, manually check anyway
    final serverCertSha256 = sha256.convert(socket.peerCertificate!.der).bytes;

    print("Pinned SHA256 (manual): ${base64.encode(pinnedSha256)}");
    print("Server SHA256 (manual): ${base64.encode(serverCertSha256)}");

    final isValid = _bytesEqual(serverCertSha256, pinnedSha256);
    await socket.close();

    return isValid;
  } catch (e) {
    print("Certificate validation failed: $e");
    return false;
  }
}


bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
