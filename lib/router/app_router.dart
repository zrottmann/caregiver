import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/services/service_selection_screen.dart';
import '../screens/booking/booking_form_screen.dart';
import '../screens/booking/enhanced_booking_form_screen.dart';
import '../screens/booking/booking_details_screen.dart';
import '../screens/booking/booking_confirmation_screen.dart';
import '../screens/booking/booking_history_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/chat/broadcast_chat_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/payment/enhanced_payment_screen.dart';
import '../screens/appointments/calendar_screen.dart';
import '../screens/appointments/book_appointment_screen.dart';
import '../screens/appointments/appointment_details_screen.dart';
import '../screens/appointments/appointment_history_screen.dart';
import '../screens/appointments/availability_management_screen.dart';
import '../models/service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = authStateAsync.value;
      final isAuthenticated = authState?.isAuthenticated ?? false;
      final isLoading = authStateAsync.isLoading || (authState?.isLoading ?? true);
      final currentPath = state.uri.path;
      
      // Show splash screen while loading
      if (isLoading && currentPath != '/splash') {
        return '/splash';
      }
      
      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isLoading) {
        final publicRoutes = ['/login', '/register', '/forgot-password', '/splash'];
        if (!publicRoutes.contains(currentPath)) {
          return '/login';
        }
      }
      
      // Redirect to home if authenticated and trying to access auth routes
      if (isAuthenticated && !isLoading) {
        final authRoutes = ['/login', '/register', '/forgot-password', '/splash'];
        if (authRoutes.contains(currentPath) || currentPath == '/') {
          return '/home';
        }
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main App Routes
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Profile Routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      
      // Search Routes
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Service Selection
      GoRoute(
        path: '/services/:caregiverId',
        name: 'service-selection',
        builder: (context, state) {
          final caregiverId = state.pathParameters['caregiverId']!;
          return ServiceSelectionScreen(caregiverId: caregiverId);
        },
      ),
      
      // Booking Routes
      GoRoute(
        path: '/booking/:caregiverId',
        name: 'booking-form',
        builder: (context, state) {
          final caregiverId = state.pathParameters['caregiverId']!;
          final preSelectedServices = state.extra as List<BookingService>?;
          return EnhancedBookingFormScreen(
            caregiverId: caregiverId,
            preSelectedServices: preSelectedServices,
          );
        },
      ),
      GoRoute(
        path: '/booking-details/:bookingId',
        name: 'booking-details',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingDetailsScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/booking-confirmation/:bookingId',
        name: 'booking-confirmation',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingConfirmationScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/bookings',
        name: 'booking-history',
        builder: (context, state) => const BookingHistoryScreen(),
      ),
      
      // Chat Routes
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatRoomScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/broadcast-chat',
        name: 'broadcast-chat',
        builder: (context, state) => const BroadcastChatScreen(),
      ),
      
      // Payment Routes
      GoRoute(
        path: '/payment/:bookingId',
        name: 'payment',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return EnhancedPaymentScreen(bookingId: bookingId);
        },
      ),

      // Appointment Routes
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/book-appointment',
        name: 'book-appointment',
        builder: (context, state) {
          final caregiverId = state.uri.queryParameters['caregiverId'];
          return BookAppointmentScreen(caregiverId: caregiverId);
        },
      ),
      GoRoute(
        path: '/appointment-details/:appointmentId',
        name: 'appointment-details',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId']!;
          return AppointmentDetailsScreen(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: '/appointment-history',
        name: 'appointment-history',
        builder: (context, state) => const AppointmentHistoryScreen(),
      ),
      GoRoute(
        path: '/availability',
        name: 'availability-management',
        builder: (context, state) => const AvailabilityManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(
        child: Text('Page not found'),
      ),
    ),
  );
});