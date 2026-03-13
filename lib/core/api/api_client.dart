import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.0.106:3000/api/customer',
);

const _storage = FlutterSecureStorage();

/// Optional callback when a 401 response is received. Set from app bootstrap
/// (e.g. [registerUnauthorizedCallback]) to clear session and redirect to login.
void Function()? onUnauthorized;

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'customer_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await _storage.delete(key: 'customer_token');
        onUnauthorized?.call();
      }
      handler.next(error);
    },
  ));

  return dio;
});

class ApiEndpoints {
  static const sendOtp = '/auth/send-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const me = '/auth/me';
  static const vehicles = '/vehicles';
  static const routes = '/routes';
  static const bookings = '/bookings';
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
