import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'splash_screen.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'device_page.dart';
import 'chat_screen.dart';
import 'landing_page.dart';
import 'device_detail_page.dart';
import 'admin_users_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/landing',
      builder: (BuildContext context, GoRouterState state) => const LandingPage(),
    ),
    GoRoute(
      path: '/signin',
      builder: (BuildContext context, GoRouterState state) => const SignInPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/devices',
      builder: (BuildContext context, GoRouterState state) => const DevicePage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final deviceId = state.pathParameters['id']!;
            return DeviceDetailScreen(deviceId: deviceId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/chatbot',
      builder: (BuildContext context, GoRouterState state) {
        final deviceId = state.uri.queryParameters['deviceId'];
        return ChatScreen(initialDeviceId: deviceId);
      },
    ),
    GoRoute(
      path: '/admin/users',
      builder: (BuildContext context, GoRouterState state) => const AdminUsersPage(),
    ),
  ],
);
