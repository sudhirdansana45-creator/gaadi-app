import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class VehicleWiseReportScreen extends StatefulWidget {
  final Vehicle? vehicle;
  final VoidCallback onBack;

  const VehicleWiseReportScreen({
    super.key,
    this.vehicle,
    required this.onBack,
  });

  @override
  State<VehicleWiseReportScreen> createState() => _VehicleWiseReportScreenState();
}

class _VehicleWiseReportScreenState extends State<VehicleWiseReportScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _vehicleReports = [];
  double _totalRevenue = 0.0;
  int _totalTrips = 0;
  int _activeRentedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getReportsVehicleWise();
      if (res != null && res['data'] is List && mounted) {
        final list = List<Map<String, dynamic>>.from(res['data']);
        double rev = 0.0;
        int trips = 0;
        int active = 0;

        for (final item in list) {
          rev += (item['total_revenue'] as num?)?.toDouble() ?? 0.0;
          trips += (item['total_trips'] as num?)?.toInt() ?? 0;
          if (item['is_currently_rented'] == true) {
            active++;
          }
        }

        setState(() {
          _vehicleReports = list;
          _totalRevenue = rev;
          _totalTrips = trips;
          _activeRentedCount = active;
        });
      }
    } catch (_) {
      // Graceful offline fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vehicle-Wise Performance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadReport,
          color: AppColors.primaryCyan,
          backgroundColor: AppColors.surfaceCard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(
                      color: AppColors.primaryCyan,
                      backgroundColor: AppColors.canvasLow,
                      minHeight: 2,
                    ),
                  ),

                // Overall Fleet Metric Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _tile('Total Revenue', '₹${_totalRevenue.toInt()}', AppColors.primaryCyan),
                          _tile('Total Trips', '$_totalTrips', AppColors.successGreen),
                          _tile('Currently Rented', '$_activeRentedCount', AppColors.warningAmber),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.borderHairline),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fleet Net Revenue:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text('₹${_totalRevenue.toInt()}', style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w900, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Vehicle Performance Breakdown',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (_vehicleReports.isEmpty && !_isLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textMuted.withAlpha(120)),
                        const SizedBox(height: 12),
                        const Text(
                          'No Vehicle Performance Records Found',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bookings recorded for your fleet vehicles will automatically generate performance analytics here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ..._vehicleReports.map((v) {
                    final isRented = v['is_currently_rented'] == true;
                    final rev = (v['total_revenue'] as num?)?.toDouble() ?? 0.0;
                    final trips = (v['total_trips'] as num?)?.toInt() ?? 0;
                    final completed = (v['completed_trips'] as num?)?.toInt() ?? 0;
                    final partner = v['partner_name']?.toString() ?? 'Self-Owned';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['name']?.toString() ?? 'Vehicle',
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${v['number'] ?? ''} • $partner',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isRented ? AppColors.infoBg : AppColors.successBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isRented ? AppColors.infoBorder : AppColors.successBorder),
                                ),
                                child: Text(
                                  isRented ? 'On Trip' : 'Available',
                                  style: TextStyle(
                                    color: isRented ? AppColors.infoBlue : AppColors.successGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.borderHairline, height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Trips (Completed / Total)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text('$completed / $trips Trips', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Total Revenue', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text('₹${rev.toInt()}', style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w800, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(String title, String val, Color c) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}
