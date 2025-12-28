import 'package:frontend/common/screens/RegisterScreen.dart';
import 'package:frontend/common/screens/loginScreen.dart';
import 'package:frontend/common/screens/splashScreen.dart';
import 'package:frontend/operator/screens/homeScreen.dart';
import 'package:frontend/supervisor/screens/homeScreen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter routes = GoRouter(
    initialLocation: "/",
    routes: [
      GoRoute(path: "/", builder: (context, state) => SplashScreen()),
      GoRoute(path: "/login", builder: (context, state) => LoginScreen()),
      GoRoute(path: "/register", builder: (context, state) => RegisterScreen()),
      GoRoute(path: "/operatorHome", builder: (context, state) => OperatorHomeScreen()),
      GoRoute(path: "/supervisorHome", builder: (context, state) => HomescreenS()),


    ]
  );
}


