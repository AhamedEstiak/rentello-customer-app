import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/customer.dart';

const _storage = FlutterSecureStorage();

class AuthState {
  final bool isLoading;
  final Customer? customer;
  final String? token;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.customer,
    this.token,
    this.error,
  });

  bool get isAuthenticated => token != null && customer != null;

  AuthState copyWith({
    bool? isLoading,
    Customer? customer,
    String? token,
    String? error,
    bool clearError = false,
    bool clearCustomer = false,
    bool clearToken = false,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        customer: clearCustomer ? null : customer ?? this.customer,
        token: clearToken ? null : token ?? this.token,
        error: clearError ? null : error ?? this.error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadFromStorage();
    return const AuthState(isLoading: true);
  }

  Dio get _dio => ref.read(dioProvider);

  Future<void> _loadFromStorage() async {
    try {
      final token = await _storage.read(key: 'customer_token');
      if (token == null) {
        state = const AuthState();
        return;
      }

      final res = await _dio.get(ApiEndpoints.me);
      final customer =
          Customer.fromJson(res.data['customer'] as Map<String, dynamic>);
      state = AuthState(token: token, customer: customer);
    } catch (_) {
      await _storage.delete(key: 'customer_token');
      state = const AuthState();
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post(ApiEndpoints.sendOtp, data: {'phone': phone});
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] as String? ?? 'Failed to send OTP';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp, {String? name}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.post(ApiEndpoints.verifyOtp, data: {
        'phone': phone,
        'otp': otp,
        if (name != null) 'name': name,
      });
      final token = res.data['token'] as String;
      final customer =
          Customer.fromJson(res.data['customer'] as Map<String, dynamic>);
      await _storage.write(key: 'customer_token', value: token);
      state = AuthState(token: token, customer: customer);
      return true;
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] as String? ?? 'Invalid OTP';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.put(ApiEndpoints.me, data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
      });
      final updated =
          Customer.fromJson(res.data['customer'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, customer: updated);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] as String? ?? 'Update failed';
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'customer_token');
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
