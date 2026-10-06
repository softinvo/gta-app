import 'package:url_launcher/url_launcher.dart';

class CustomerSupport {
  const CustomerSupport._();

  static const String phoneDisplay = '+91 9922330399';
  static const String phoneDial = '+919922330399';
  static const String email = 'admin@globaltextileaxis.com';

  static Future<bool> call() => _open(Uri(scheme: 'tel', path: phoneDial));

  static Future<bool> sendEmail() => _open(Uri(scheme: 'mailto', path: email));

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
