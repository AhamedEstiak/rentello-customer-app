import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_storage.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.0.101:3000/api/customer',
);

const _storage = FlutterSecureStorage();

/// Optional callback when a 401 response is received. Set from app bootstrap
/// (e.g. [registerUnauthorizedCallback]) to clear session and redirect to login.
void Function()? onUnauthorized;

/// Set on [RequestOptions.extra] to skip attaching the Bearer access token
/// (e.g. [ApiEndpoints.authRefresh] uses body `refreshToken` instead).
const kDioSkipAuth = 'skipAuth';

/// Logs HTTP request and response for server API calls.
class _ApiLogInterceptor extends Interceptor {
  static const _logName = 'ApiClient';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = '<redacted>';
    }
    developer.log(
      '→ ${options.method} ${options.uri}\n'
      '  Headers: $headers\n'
      '  Body: ${options.data ?? ''}',
      name: _logName,
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.uri}\n'
      '  Data: ${response.data}',
      name: _logName,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '← ERROR ${err.requestOptions.method} ${err.requestOptions.uri}\n'
      '  ${err.type}: ${err.message}\n'
      '  Response: ${err.response?.data ?? err.response?.statusCode}',
      name: _logName,
    );
    handler.next(err);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra[kDioSkipAuth] == true) {
          handler.next(options);
          return;
        }
        final token = await _storage.read(key: AuthStorageKeys.accessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          if (path.endsWith(ApiEndpoints.authRefresh)) {
            handler.next(error);
            return;
          }
          await clearAuthStorage(_storage);
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );

  dio.interceptors.add(_ApiLogInterceptor());

  return dio;
});

/// JSON keys for customer auth responses (`verify-otp`, `auth/refresh`) and the refresh request body.
///
/// Backend contract: OTP verify and refresh return `{ token, refreshToken?, customer }`;
/// refresh accepts `{ refreshToken }` and does not use the access `Authorization` header.
abstract final class CustomerAuthJsonKeys {
  static const String token = 'token';
  static const String refreshToken = 'refreshToken';
  static const String customer = 'customer';
}

/// `POST` [ApiEndpoints.authRefresh] with [refreshToken] in the body, without Bearer access token.
Future<Response<Map<String, dynamic>>> postAuthRefresh(
  Dio dio,
  String refreshToken,
) {
  return dio.post<Map<String, dynamic>>(
    ApiEndpoints.authRefresh,
    data: {CustomerAuthJsonKeys.refreshToken: refreshToken},
    options: Options(extra: const {kDioSkipAuth: true}),
  );
}

class ApiEndpoints {
  static const sendOtp = '/auth/send-otp';
  static const verifyOtp = '/auth/verify-otp';
  /// `POST` body: `{ [CustomerAuthJsonKeys.refreshToken] }` → `{ [CustomerAuthJsonKeys.token], … }`.
  static const authRefresh = '/auth/refresh';
  static const me = '/auth/me';
  static const vehicles = '/vehicles';
  static const routes = '/routes';
  static const bookings = '/bookings';
  static const locations = '/locations';
  static const fareEstimate = '/fare-estimate';
  static const promoValidate = '/promo/validate';

  // Bookings (id-based)
  static String bookingDetail(String id) => '/bookings/$id';
  static String bookingCancel(String id) => '/bookings/$id/cancel';
  static String bookingPayments(String id) => '/bookings/$id/payments';
  static String bookingInvoice(String id) => '/bookings/$id/invoice';
  static String bookingReviews(String id) => '/bookings/$id/reviews';
  static String bookingPaymentsInitiate(String id) =>
      '/bookings/$id/payments/initiate';

  // Notifications
  static const notifications = '/notifications';
  static String notificationAck(String id) => '/notifications/$id/ack';
  static const notificationsDeviceToken = '/notifications/device-token';

  // Support
  static const supportTickets = '/support/tickets';
}
