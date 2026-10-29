import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Strips DLT routing prefix ("VM-HDFCBK" / "AD-HDFCBK-S" -> "HDFCBK").
String normalizeSender(String sender) {
  var s = sender.trim().toUpperCase();
  final m = RegExp(r'^[A-Z]{2}-([A-Z0-9]{3,})(?:-[A-Z])?$').firstMatch(s);
  if (m != null) s = m.group(1)!;
  return s;
}

/// Masks the variable parts of an SMS so messages built from the same bank
/// template map to the same string.
String normalizeTemplate(String body) {
  var t = body.toLowerCase();
  t = t.replaceAll(
    RegExp(r'https?://\S+|www\.\S+|\b\w+\.(?:in|com|ly|me|it)/\S*'),
    '<url>',
  );
  t = t.replaceAll(RegExp(r'\b[\w.\-]+@[\w]+\b'), '<vpa>');
  t = t.replaceAll(RegExp(r'(?:₹|\brs\.?|\binr)\s*[\d,]+(?:\.\d+)?'), '<amt>');
  t = t.replaceAll(RegExp(r'(?:[x*]{1,}\s?)\d{2,6}\b'), '<acct>');
  t = t.replaceAll(
    RegExp(
      r'\b\d{1,4}[-/.](?:\d{1,2}|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[-/.]\d{2,4}\b',
    ),
    '<date>',
  );
  t = t.replaceAll(
    RegExp(
      r'\b\d{1,2}(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\d{2,4}\b',
    ),
    '<date>',
  );
  t = t.replaceAll(RegExp(r'\d+(?:[.,:]\d+)*'), '<n>');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

String templateKey(String sender, String body) => sha1
    .convert(
      utf8.encode('${normalizeSender(sender)}|${normalizeTemplate(body)}'),
    )
    .toString();
