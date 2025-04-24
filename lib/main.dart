import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/trip_provider.dart';
import 'services/auth_service.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  // Get the Supabase client instance *after* initialization
  final SupabaseClient supabaseClient = Supabase.instance.client;

  // Instantiate AuthService, injecting the client
  final AuthService authService = AuthServiceImpl(supabaseClient);

  // Create AuthProvider instance, injecting the service
  final AuthProvider authProvider = AuthProvider(authService);

  // Create the router instance, passing the AuthProvider
  final GoRouter appRouter = AppRouter.createRouter(authProvider);

  runApp(MyApp(authProvider: authProvider, appRouter: appRouter));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GoRouter appRouter;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide AuthProvider and potentially others
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider), // Provide existing instance
        // TODO: Instantiate and provide other providers if needed
        // ChangeNotifierProvider(create: (_) => BookingProvider()),
        // ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      // Use MaterialApp.router
      child: MaterialApp.router(
        title: 'SamaBus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0057E7),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0057E7),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('fr', ''), // French
        ],
        // Pass the router configuration
        routerConfig: appRouter,
      ),
    );
  }
}
