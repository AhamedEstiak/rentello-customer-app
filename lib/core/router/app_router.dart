import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/phone_entry_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/vehicle_select_screen.dart';
import '../../features/booking/screens/booking_type_screen.dart';
import '../../features/booking/screens/booking_form_screen.dart';
import '../../features/booking/screens/fare_review_screen.dart';
import '../../features/booking/screens/booking_confirm_screen.dart';
import '../../features/bookings/screens/bookings_list_screen.dart';
import '../../features/bookings/screens/booking_detail_screen.dart';
import '../../features/bookings/screens/booking_invoice_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../shell/main_shell.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late AuthState _authState;

  RouterNotifier(this._ref) {
    _authState = _ref.read(authProvider);
    _ref.listen<AuthState>(authProvider, (_, next) {
      _authState = next;
      notifyListeners();
    });
    // On 401, API client clears token and calls this; we logout so redirect runs.
    onUnauthorized = () => _ref.read(authProvider.notifier).logout();
    onRefreshSession =
        () => _ref.read(authProvider.notifier).refreshSessionFromStorage();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;

    if (_authState.isLoading) {
      return loc == '/splash' ? null : '/splash';
    }

    final isAuthenticated = _authState.isAuthenticated;
    final isOnAuthPage = loc == '/login' || loc == '/otp';

    if (isAuthenticated && isOnAuthPage) return '/home';
    if (isAuthenticated && loc == '/splash') return '/home';

    if (!isAuthenticated && !isOnAuthPage) return '/login';
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerifyScreen(phone: phone);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/vehicles/:type',
            builder: (context, state) => VehicleSelectScreen(
              bookingType: state.pathParameters['type']!,
            ),
          ),
          GoRoute(
            path: '/booking/:vehicleId/form/:type',
            builder: (context, state) => BookingFormScreen(
              vehicleId: state.pathParameters['vehicleId']!,
              bookingType: state.pathParameters['type']!,
            ),
            routes: [
              GoRoute(
                path: 'review',
                builder: (context, state) {
                  final args = state.extra as Map<String, dynamic>?;
                  return FareReviewScreen(args: args ?? {});
                },
                routes: [
                  GoRoute(
                    path: 'confirm',
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>?;
                      return BookingConfirmScreen(args: args ?? {});
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'booking/type/:vehicleId',
                builder: (context, state) => BookingTypeScreen(
                  vehicleId: state.pathParameters['vehicleId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'form/:type',
                    builder: (context, state) => BookingFormScreen(
                      vehicleId: state.pathParameters['vehicleId']!,
                      bookingType: state.pathParameters['type']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'review',
                        builder: (context, state) {
                          final args = state.extra as Map<String, dynamic>?;
                          return FareReviewScreen(args: args ?? {});
                        },
                        routes: [
                          GoRoute(
                            path: 'confirm',
                            builder: (context, state) {
                              final args = state.extra as Map<String, dynamic>?;
                              return BookingConfirmScreen(args: args ?? {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BookingDetailScreen(
                  bookingId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'invoice',
                    builder: (context, state) => BookingInvoiceScreen(
                      bookingId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportScreen(),
          ),
        ],
      ),
    ],
  );
});
