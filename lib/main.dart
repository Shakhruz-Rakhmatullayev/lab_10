import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/shell.dart';
import 'services/product_service.dart';
import 'state/app_state.dart';
import 'state/cart_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  runApp(HabitflowApp(state: AppState(prefs: prefs)));
}

class HabitflowApp extends StatelessWidget {
  const HabitflowApp({super.key, required this.state, this.productService});

  final AppState state;

  /// Injected in tests with a mock HTTP client; the real API otherwise.
  final ProductService? productService;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: MultiProvider(
        providers: [
          Provider<ProductService>(
            create: (_) => productService ?? ProductService(),
          ),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) => MaterialApp(
            title: 'Habitflow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.themeMode,
            home: const AppShell(),
          ),
        ),
      ),
    );
  }
}
