import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api.dart';
import 'core/routes.dart';

void main() {
    DioClient.initialize(); 

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "LimeLightIt",
      routerConfig: AppRouter.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}

