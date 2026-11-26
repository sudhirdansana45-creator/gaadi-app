import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MaintenanceScreen extends StatefulWidget {
  final String? maintenanceUntil;
  final String? maintenanceMessage;
  final VoidCallback onMaintenanceEnded;

  const MaintenanceScreen({
    super.key,
    this.maintenanceUntil,
    this.maintenanceMessage,
    required this.onMaintenanceEnded,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isChecking = false;
  DateTime? _targetTime;

  @override
  void initState() {
    super.initState();
    _parseTargetTime();
    _startCountdown();
  }

  void _parseTargetTime() {
    if (widget.maintenanceUntil != null && widget.maintenanceUntil!.isNotEmpty) {
      try {
        _targetTime = DateTime.parse(widget.maintenanceUntil!);
      } catch (_) {
        _targetTime = DateTime.now().add(const Duration(hours: 2));
      }
    } else {
      _targetTime = DateTime.now().add(const Duration(hours: 2));
    }
    _calculateRemaining();
  }

  void _calculateRemaining() {
    if (_targetTime == null) return;
    final now = DateTime.now();
    if (_targetTime!.isAfter(now)) {
      setState(() {
        _remaining = _targetTime!.difference(now);
      });
    } else {
      setState(() {
        _remaining = Duration.zero;
      });
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      _calculateRemaining();
      if (_remaining.inSeconds <= 0) {
        // Auto check if maintenance ended
        _checkServerStatus(autoCheck: true);
      }
    });
  }

  Future<void> _checkServerStatus({bool autoCheck = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final res = await ApiService().getAppSettings();
      if (res != null && res['data'] != null) {
        final data = res['data'];
        final bool isMaintenance = data['maintenance_mode'] == true;
        if (!isMaintenance && mounted) {
          _timer?.cancel();
          widget.onMaintenanceEnded();
          return;
        }
      }
      if (!autoCheck && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance is still in progress. Please check back shortly.'),
            backgroundColor: Color(0xFFD97706),
          ),
        );
      }
    } catch (_) {
      // offline or server down
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final msg = widget.maintenanceMessage?.isNotEmpty == true
        ? widget.maintenanceMessage!
        : 'Our platform infrastructure is undergoing scheduled upgrades for higher speed and reliability.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C101A),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated / Glowing Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.build_circle_rounded, color: Color(0xFFF59E0B), size: 52),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  const Text(
                    'System Maintenance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'TEMPORARILY UNAVAILABLE',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message Description
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Live Countdown Timer Display
                  const Text(
                    'ESTIMATED TIME REMAINING',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (days > 0) ...[
                        _buildTimeBlock(days.toString().padLeft(2, '0'), 'DAYS'),
                        _buildColon(),
                      ],
                      _buildTimeBlock(hours.toString().padLeft(2, '0'), 'HOURS'),
                      _buildColon(),
                      _buildTimeBlock(minutes.toString().padLeft(2, '0'), 'MINS'),
                      _buildColon(),
                      _buildTimeBlock(seconds.toString().padLeft(2, '0'), 'SECS'),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Check Status Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF451A03),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _isChecking ? null : () => _checkServerStatus(),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF451A03)),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _isChecking ? 'Checking System Status...' : 'Check Status Now',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'All user data and ongoing rentals are safe and secure.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String value, String label) {
    return Column(
      children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2638),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        ':',
        style: TextStyle(
          color: Color(0xFFF59E0B),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
