import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api.dart';
import 'package:frontend/core/connectivity_service.dart';
import 'package:frontend/core/sync_service.dart';
import 'package:frontend/core/fcm_service.dart';
import 'package:frontend/operator/services/machineService.dart';
import 'package:frontend/operator/services/downtimeService.dart';
import 'core/routes.dart';
import 'package:firebase_core/firebase_core.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  DioClient.initialize();
  
  await FCMService.initialize();
  
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
  
  final machineService = MachineService();
  final downtimeService = DowntimeService();
  final syncService = SyncService();
  await syncService.initialize(
    machineService: machineService,
    downtimeService: downtimeService,
  );
  
  final isOnline = await connectivityService.checkConnectivity();
  if (isOnline) {
    Future.delayed(const Duration(seconds: 2), () {
      syncService.syncPendingOperations(
        machineService: machineService,
        downtimeService: downtimeService,
      );
    });
  }

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

