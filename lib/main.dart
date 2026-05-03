import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:intl/date_symbol_data_local.dart';

import 'core/utils/app_theme.dart';
import 'data/repositories/ai_tip_repository.dart';
import 'data/repositories/firebase_auth_repository_impl.dart';
import 'data/repositories/firebase_loan_repository_impl.dart';
import 'data/repositories/firebase_transaction_repository_impl.dart';
import 'presentation/blocs/ai_tip_cubit.dart';
import 'firebase_options.dart';
import 'presentation/blocs/auth_cubit.dart';
import 'presentation/blocs/auth_state.dart';
import 'presentation/blocs/category_cubit.dart';
import 'presentation/blocs/loan_cubit.dart';
import 'presentation/blocs/theme_cubit.dart';
import 'presentation/blocs/transaction_cubit.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_PE', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    GoogleFonts.config.allowRuntimeFetching = true;

    final db = FirebaseFirestore.instance;
    db.settings = const Settings(persistenceEnabled: false);
    runApp(const MyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Error de inicialización: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => FirebaseAuthRepositoryImpl()),
        RepositoryProvider(create: (_) => FirebaseTransactionRepositoryImpl()),
        RepositoryProvider(create: (_) => FirebaseLoanRepositoryImpl()),
        RepositoryProvider(create: (_) => AiTipRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<AuthCubit>(
            create: (context) =>
                AuthCubit(context.read<FirebaseAuthRepositoryImpl>()),
          ),
          BlocProvider<TransactionCubit>(
            create: (context) => TransactionCubit(
              context.read<FirebaseTransactionRepositoryImpl>(),
            ),
          ),
          BlocProvider<CategoryCubit>(
            create: (context) => CategoryCubit(
              context.read<FirebaseTransactionRepositoryImpl>(),
            ),
          ),
          BlocProvider<LoanCubit>(
            create: (context) =>
                LoanCubit(context.read<FirebaseLoanRepositoryImpl>()),
          ),
          BlocProvider<AiTipCubit>(
            create: (context) => AiTipCubit(context.read<AiTipRepository>()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, bool>(
          builder: (context, isDark) {
            return MaterialApp(
              title: 'Finance App 2.0',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('es', 'PE'), Locale('es', '')],
              locale: const Locale('es', 'PE'),
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext methodContext) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current is Authenticated &&
          (previous is! Authenticated || previous.user.id != current.user.id),
      listener: (context, state) {
        if (state is Authenticated) {
          final repo = context.read<FirebaseTransactionRepositoryImpl>();
          final transactionCubit = context.read<TransactionCubit>();
          final categoryCubit = context.read<CategoryCubit>();
          final loanCubit = context.read<LoanCubit>();
          final aiTipCubit = context.read<AiTipCubit>();
          final userId = state.user.id;
          repo.seedDefaultCategoriesIfEmpty().then((_) {
            transactionCubit.loadTransactions(userId);
            transactionCubit.loadCategories();
            categoryCubit.loadCategories();
            loanCubit.loadLoans(userId);
            Future.delayed(const Duration(seconds: 2), () {
              aiTipCubit.loadTip(
                userId,
                transactionCubit.allTransactions,
                transactionCubit.allCategories,
              );
            });
          });
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainShell();
        }
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const LoginPage();
      },
    );
  }
}
