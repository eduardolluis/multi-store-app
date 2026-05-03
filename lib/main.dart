import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:multi_store_app/auth/auth_wrapper.dart';
import 'package:multi_store_app/auth/change_password_screen.dart';
import 'package:multi_store_app/auth/customer_login.dart';
import 'package:multi_store_app/auth/customer_signup.dart';
import 'package:multi_store_app/auth/forgot_password_screen.dart';
import 'package:multi_store_app/auth/supplier_login.dart';
import 'package:multi_store_app/auth/supplier_signup.dart';
import 'package:multi_store_app/auth/verify_email_screen.dart';
import 'package:multi_store_app/firebase_options.dart';
import 'package:multi_store_app/main_screens/enhanced_customer_home.dart';
import 'package:multi_store_app/main_screens/supplier_home.dart';
import 'package:multi_store_app/main_screens/welcome.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/providers/stripe_id.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
// SQL Providers
import 'package:multi_store_app/sql/sql_cart_provider.dart';
import 'package:multi_store_app/sql/sql_wish_provider.dart';
import 'package:multi_store_app/sql/search_history_provider.dart';
import 'package:multi_store_app/sql/recently_viewed_provider.dart';
import 'package:multi_store_app/sql/product_notes_provider.dart';
import 'package:multi_store_app/notifications/background_message_handler.dart';
import 'package:multi_store_app/notifications/notification_service.dart';
import 'package:multi_store_app/notifications/fcm_token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  Stripe.publishableKey = STRIPE_PUBLISHABLE_KEY;
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await NotificationService().initialize();

  FcmTokenService().listenToTokenRefresh();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => Wish()),
        ChangeNotifierProvider(create: (_) => SqlCartProvider()..loadFromDb()),
        ChangeNotifierProvider(create: (_) => SqlWishProvider()..loadFromDb()),
        ChangeNotifierProvider(create: (_) => SearchHistoryProvider()..loadFromDb()),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider()..loadFromDb()),
        ChangeNotifierProvider(create: (_) => ProductNotesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111827),
          brightness: Brightness.light,
        ),
        fontFamily: 'Acme',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: AuthWrapper(
        onAuthenticated: (User user) {
          FcmTokenService().saveTokenToFirestore();
          return const WelcomeScreen();
        },
        unauthenticatedWidget: const WelcomeScreen(),
      ),
      routes: {
        '/welcome_screen': (context) => const WelcomeScreen(),
        '/customer_home': (context) => const EnhancedCustomerHomeScreen(),
        '/supplier_home': (context) => const SupplierHomeScreen(),
        '/customer_signup': (context) => const CustomerSignup(),
        '/customer_login': (context) => const CustomerLogin(),
        '/supplier_signup': (context) => const SupplierRegister(),
        '/supplier_login': (context) => const SupplierLogin(),
        '/verify_email': (context) => const VerifyEmailScreen(nextRoute: '/customer_home'),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
      },
    );
  }
}
