import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;
import 'features/speaking_practice/presentation/bloc/speaking_bloc.dart';
import 'features/speaking_practice/presentation/bloc/mock_test_bloc.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for clean light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load .env environment variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // If .env is not present, fall back to --dart-define or local defaults
  }

  // Initialize Clean Architecture dependency injection
  await di.init();

  // Initialize local notifications
  await di.sl<NotificationService>().init();

  runApp(const IeltsSpeakyApp());
}

class IeltsSpeakyApp extends StatelessWidget {
  const IeltsSpeakyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SpeakingBloc>(
          create: (_) => di.sl<SpeakingBloc>()..add(const LoadSpeakingDataEvent()),
        ),
        BlocProvider<MockTestBloc>(
          create: (_) => di.sl<MockTestBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'IELTS Speaky',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}
