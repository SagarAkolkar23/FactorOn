import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/supervisor/providers/supervisorProvider.dart';
import 'package:frontend/supervisor/models/downtimeModel.dart';
import 'package:frontend/supervisor/models/dashboardStatsModel.dart';
import 'package:frontend/supervisor/services/supervisorService.dart';
import 'package:frontend/widgets/offline_indicator.dart';
import 'package:frontend/core/fcm_service.dart';
import 'dart:io';

class HomescreenS extends ConsumerStatefulWidget {
  const HomescreenS({super.key});

  @override
  ConsumerState<HomescreenS> createState() => _HomescreenSState();
}

class _HomescreenSState extends ConsumerState<HomescreenS> {
  Timer? _refreshTimer;
  bool _isDownloading = false;
  final SupervisorService _supervisorService = SupervisorService();

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds to get latest downtime updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(dashboardStatsProvider.notifier).refresh();
      }
    });
    
    // Listen for FCM notifications and refresh dashboard
    FCMService.onNotificationReceived = (RemoteMessage message) {
      if (mounted) {
        // Refresh dashboard when downtime notification is received
        ref.read(dashboardStatsProvider.notifier).refresh();
        
        // Show a snackbar to notify user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.title ?? "New downtime update"),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    };
    
    // Also refresh immediately when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardStatsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _downloadReport() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final filePath = await _supervisorService.downloadDowntimeReport();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Platform.isAndroid
                  ? "Report downloaded to Downloads folder"
                  : "Report downloaded to: $filePath",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: "OK",
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to download report: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Supervisor Dashboard"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade900,
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            tooltip: "Download Downtime Report",
            onPressed: _isDownloading ? null : _downloadReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardStatsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(dashboardStatsProvider.notifier).refresh();
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
              data: (stats) {
                if (stats == null) {
                  return const Center(
                    child: Text("No data available"),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(dashboardStatsProvider.notifier).refresh();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Cards
                        _StatsGrid(stats: stats),
                        const SizedBox(height: 24),

                        // Active Downtimes Section
                        if (stats.activeDowntimes.isNotEmpty) ...[
                          _SectionTitle(
                            title: "Active Downtimes",
                            count: stats.activeDowntimes.length,
                          ),
                          const SizedBox(height: 12),
                          ...stats.activeDowntimes.map(
                            (downtime) => _DowntimeCard(
                              downtime: downtime,
                              isActive: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Recent Downtimes Section
                        _SectionTitle(
                          title: "Recent Downtimes",
                          count: stats.recentDowntimes.length,
                        ),
                        const SizedBox(height: 12),
                        if (stats.recentDowntimes.isEmpty)
                          const _EmptyState(
                            message: "No recent downtimes",
                            icon: Icons.check_circle_outline,
                          )
                        else
                          ...stats.recentDowntimes.map(
                            (downtime) => _DowntimeCard(
                              downtime: downtime,
                              isActive: downtime.isActive,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStatsModel stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: "Total Machines",
          value: stats.totalMachines.toString(),
          icon: Icons.precision_manufacturing,
          color: Colors.blue,
        ),
        _StatCard(
          title: "Active Downtimes",
          value: stats.activeDowntimesCount.toString(),
          icon: Icons.warning,
          color: Colors.red,
        ),
        _StatCard(
          title: "Today's Downtimes",
          value: stats.todayDowntimes.toString(),
          icon: Icons.today,
          color: Colors.orange,
        ),
        _StatCard(
          title: "Downtime Today",
          value: _formatMinutes(stats.totalDowntimeMinutesToday),
          icon: Icons.timer,
          color: Colors.purple,
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return "${minutes}m";
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return "${hours}h ${mins}m";
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DowntimeCard extends StatelessWidget {
  final DowntimeModel downtime;
  final bool isActive;

  const _DowntimeCard({
    required this.downtime,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.red.shade200 : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.warning : Icons.check_circle,
                    color: isActive ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        downtime.machineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "ID: ${downtime.machineId}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "ACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.category,
                  label: downtime.machineType ?? "N/A",
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.label,
                  label: downtime.reason["categoryCode"] ?? "N/A",
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  "Started: ${DateFormat("MMM dd, HH:mm").format(downtime.startTime)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  downtime.durationFormatted,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            if (downtime.endTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    "Ended: ${DateFormat("MMM dd, HH:mm").format(downtime.endTime!)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            if (downtime.photoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  downtime.photoUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
