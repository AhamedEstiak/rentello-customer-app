import 'package:jwt_decoder/jwt_decoder.dart';

/// Reads JWT `exp` without verifying the signature (enough for client-side expiry checks).
///
/// Uses [JwtDecoder] for base64url payload decoding. [isOpaqueToken] and [tryExpiryUtc]
/// cover the non-JWT case: opaque strings are not parsed as JWTs, and callers should
/// use a network fallback (e.g. `GET /me`) instead of local expiry.
class JwtAccess {
  JwtAccess._();

  static const _skew = Duration(seconds: 60);

  /// True when [token] is not a JWT (invalid shape or undecodable payload).
  static bool isOpaqueToken(String token) =>
      JwtDecoder.tryDecode(token) == null;

  /// True when [token] is a JWT with a decodable payload, regardless of `exp`.
  static bool isLikelyJwt(String token) => !isOpaqueToken(token);

  /// True when the payload has a numeric `exp` claim so local expiry checks apply.
  static bool canCheckExpiryLocally(String token) => tryExpiryUtc(token) != null;

  /// JWT `exp` as UTC when present; otherwise `null` (opaque token or missing `exp`).
  static DateTime? tryExpiryUtc(String token) {
    final payload = JwtDecoder.tryDecode(token);
    if (payload == null) return null;
    final exp = payload['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch((exp * 1000).round(), isUtc: true);
  }

  /// True while the access token is not past `exp`, minus [_skew] (refresh a bit early).
  ///
  /// False when opaque, missing `exp`, or expired.
  static bool isAccessStillValid(String token) {
    final expiryUtc = tryExpiryUtc(token);
    if (expiryUtc == null) return false;
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.isBefore(expiryUtc.subtract(_skew));
  }
}
