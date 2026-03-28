import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_storage.dart';
import '../../../core/auth/jwt_access.dart';
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
  /// Ensures concurrent [build] invocations share one load and never parallelize
  /// `GET /auth/me` via [_hydrateFromMe].
  Future<void>? _loadFromStorageInFlight;

  @override
  AuthState build() {
    ref.keepAlive();
    _loadFromStorage();
    return const AuthState(isLoading: true);
  }

  Dio get _dio => ref.read(dioProvider);

  /// Writes [AuthStorageKeys.customerSnapshot] so cold start can skip `GET /auth/me`
  /// when the access JWT is still valid. Call after every successful login, refresh,
  /// hydrate-from-me, and profile update.
  Future<void> _persistCustomerSnapshot(Customer customer) async {
    await _storage.write(
      key: AuthStorageKeys.customerSnapshot,
      value: jsonEncode(customer.toJson()),
    );
  }

  Customer? _tryParseSnapshot(String? snapshotJson) {
    if (snapshotJson == null) return null;
    try {
      final map = jsonDecode(snapshotJson) as Map<String, dynamic>;
      return Customer.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _hydrateFromMe(String accessToken) async {
    final res = await _dio.get(ApiEndpoints.me);
    final customer =
        Customer.fromJson(res.data['customer'] as Map<String, dynamic>);
    await _persistCustomerSnapshot(customer);
    state = AuthState(
      isLoading: false,
      token: accessToken,
      customer: customer,
    );
  }

  /// Used by the Dio 401 interceptor: rotate tokens and update state, then retry the request.
  Future<bool> refreshSessionFromStorage() async {
    final refresh = await _storage.read(key: AuthStorageKeys.refreshToken);
    if (refresh == null) return false;
    return _tryRefresh(refresh);
  }

  /// Returns true if session was restored from the refresh response.
  Future<bool> _tryRefresh(String refreshToken) async {
    try {
      final res = await postAuthRefresh(_dio, refreshToken);
      final data = res.data;
      if (data == null) return false;
      final token = data[CustomerAuthJsonKeys.token] as String?;
      final customerJson = data[CustomerAuthJsonKeys.customer];
      if (token == null || customerJson is! Map<String, dynamic>) {
        return false;
      }
      final customer = Customer.fromJson(customerJson);
      await _storage.write(key: AuthStorageKeys.accessToken, value: token);
      final newRefresh = data[CustomerAuthJsonKeys.refreshToken] as String?;
      if (newRefresh != null) {
        await _storage.write(
          key: AuthStorageKeys.refreshToken,
          value: newRefresh,
        );
      }
      await _persistCustomerSnapshot(customer);
      state = AuthState(
        isLoading: false,
        token: token,
        customer: customer,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Restores session from secure storage without redundant `GET /auth/me` when
  /// the access token is a non-expired JWT and a customer snapshot exists.
  ///
  /// Branches: no access → logged out; JWT valid + snapshot → memory only;
  /// JWT expired + refresh → `POST /auth/refresh`; opaque/unknown expiry or
  /// missing/bad snapshot → one `GET /auth/me`; refresh failure or expired JWT
  /// without refresh → clear storage and logged out.
  void _loadFromStorage() {
    _loadFromStorageInFlight ??= _loadFromStorageImpl().whenComplete(() {
      _loadFromStorageInFlight = null;
    });
  }

  Future<void> _loadFromStorageImpl() async {
    try {
      final access = await _storage.read(key: AuthStorageKeys.accessToken);
      if (access == null) {
        state = const AuthState(isLoading: false);
        return;
      }

      final refresh = await _storage.read(key: AuthStorageKeys.refreshToken);
      final snapshotJson =
          await _storage.read(key: AuthStorageKeys.customerSnapshot);

      final canCheckJwt = JwtAccess.canCheckExpiryLocally(access);

      if (canCheckJwt) {
        if (JwtAccess.isAccessStillValid(access)) {
          final cached = _tryParseSnapshot(snapshotJson);
          if (cached != null) {
            state = AuthState(
              isLoading: false,
              token: access,
              customer: cached,
            );
            return;
          }
          await _hydrateFromMe(access);
          return;
        }

        if (refresh != null) {
          final ok = await _tryRefresh(refresh);
          if (ok) return;
        }
        await clearAuthStorage(_storage);
        state = const AuthState(isLoading: false);
        return;
      }

      // Opaque token or JWT without usable `exp`: cannot skip `/me` without a
      // local validity signal; one GET migrates snapshot when possible.
      await _hydrateFromMe(access);
    } catch (_) {
      await clearAuthStorage(_storage);
      state = const AuthState(isLoading: false);
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
      final data = res.data as Map<String, dynamic>;
      final token = data[CustomerAuthJsonKeys.token] as String;
      final newRefresh = data[CustomerAuthJsonKeys.refreshToken] as String?;
      final customer = Customer.fromJson(
        data[CustomerAuthJsonKeys.customer] as Map<String, dynamic>,
      );
      await _storage.write(key: AuthStorageKeys.accessToken, value: token);
      if (newRefresh != null) {
        await _storage.write(
          key: AuthStorageKeys.refreshToken,
          value: newRefresh,
        );
      } else {
        await _storage.delete(key: AuthStorageKeys.refreshToken);
      }
      await _persistCustomerSnapshot(customer);
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
      await _persistCustomerSnapshot(updated);
      state = state.copyWith(isLoading: false, customer: updated);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] as String? ?? 'Update failed';
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> logout() async {
    await clearAuthStorage(_storage);
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
