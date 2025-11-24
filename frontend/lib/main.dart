import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'data/services/storage_service.dart';
import 'data/services/api_service.dart';
import 'data/services/budget_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/category_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/budget_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/notifications/notification_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/budget/budget_list_screen.dart';
import 'presentation/screens/budget/budget_detail_screen.dart';
import 'presentation/screens/budget/add_edit_budget_screen.dart';
import 'presentation/screens/transactions/add_edit_transaction_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/change_password_screen.dart';
import 'presentation/screens/settings/notification_settings_screen.dart';
import 'data/models/budget_model.dart';
import 'data/models/transaction_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  await storageService.init();
  final apiService = ApiService();
  final authRepository = AuthRepository(
    apiService: apiService,
    storageService: storageService,
  );
  final transactionRepository = TransactionRepository(
    apiService: apiService,
  );
  final categoryRepository = CategoryRepository(
    apiService: apiService,
  );
  
  runApp(MyApp(
    storageService: storageService,
    apiService: apiService,
    authRepository: authRepository,
    transactionRepository: transactionRepository,
    categoryRepository: categoryRepository,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final AuthRepository authRepository;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  
  const MyApp({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.authRepository,
    required this.transactionRepository,
    required this.categoryRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(
          value: apiService,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: authRepository,
            storageService: storageService,
            apiService: apiService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(
            transactionRepository: transactionRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(
            categoryRepository: categoryRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(
            budgetService: BudgetService(apiService),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            apiService: apiService,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: AppStrings.appName, 
            debugShowCheckedModeBanner: false, 
            theme: AppTheme.lightTheme,
            routes: {
              '/budgets': (context) => const BudgetListScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/settings/change-password': (context) => const ChangePasswordScreen(),
              '/settings/notifications': (context) => const NotificationSettingsScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle routes with parameters
              if (settings.name == '/budgets/detail') {
                final budgetId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => BudgetDetailScreen(budgetId: budgetId),
                );
              }
              if (settings.name == '/budgets/edit') {
                final budget = settings.arguments as BudgetModel?;
                return MaterialPageRoute(
                  builder: (context) => AddEditBudgetScreen(budget: budget),
                );
              }
              if (settings.name == '/budgets/add') {
                return MaterialPageRoute(
                  builder: (context) => const AddEditBudgetScreen(),
                );
              }
              if (settings.name == '/transactions/edit') {
                final transaction = settings.arguments as TransactionModel?;
                return MaterialPageRoute(
                  builder: (context) => AddEditTransactionScreen(transaction: transaction),
                );
              }
              if (settings.name == '/transactions/add') {
                final initialType = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (context) => AddEditTransactionScreen(initialType: initialType),
                );
              }
              return null;
            },
            home: authProvider.isLoading 
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : (authProvider.isAuthenticated && authProvider.user != null)
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
