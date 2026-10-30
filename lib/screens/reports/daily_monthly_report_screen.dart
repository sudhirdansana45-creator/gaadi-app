import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class DailyMonthlyReportScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DailyMonthlyReportScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<DailyMonthlyReportScreen> createState() => _DailyMonthlyReportScreenState();
}

class _DailyMonthlyReportScreenState extends State<DailyMonthlyReportScreen> {
  String _reportType = 'Daily'; // 'Daily' or 'Monthly'
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  double _grossRevenue = 0.0;
  double _advanceCollected = 0.0;
  double _netIncome = 0.0;
  int _totalBookings = 0;
  int _completedBookings = 0;

  List<Booking> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final period = _reportType == 'Daily' ? 'today' : 'month';

    try {
      final summaryRes = await ApiService().getReportsSummary(period: period);
      if (summaryRes != null && summaryRes['data'] != null && mounted) {
        final summary = summaryRes['data']['summary'];
        if (summary is Map) {
          _grossRevenue = (summary['gross_revenue'] as num?)?.toDouble() ?? 0.0;
          _advanceCollected = (summary['advance_collected'] as num?)?.toDouble() ?? 0.0;
          _netIncome = (summary['net_income'] as num?)?.toDouble() ?? 0.0;
          _totalBookings = (summary['total_bookings'] as num?)?.toInt() ?? 0;
          _completedBookings = (summary['completed_bookings'] as num?)?.toInt() ?? 0;
        }
      }

      final bookingsRes = await ApiService().getBookings();
      if (bookingsRes != null && bookingsRes['data'] is List && mounted) {
        final list = (bookingsRes['data'] as List)
            .map((item) => Booking.fromJson(item as Map<String, dynamic>))
            .toList();
        _transactions = list;
      }
    } catch (_) {
      // Graceful offline fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              surface: AppColors.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily & Monthly Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadReportData,
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

                // Segmented Toggle & Date Picker Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_reportType != 'Daily') {
                                  setState(() => _reportType = 'Daily');
                                  _loadReportData();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _reportType == 'Daily'
                                      ? AppColors.primaryCyan.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _reportType == 'Daily' ? AppColors.primaryCyan : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Daily Report',
                                  style: TextStyle(
                                    color: _reportType == 'Daily' ? AppColors.primaryCyan : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_reportType != 'Monthly') {
                                  setState(() => _reportType = 'Monthly');
                                  _loadReportData();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _reportType == 'Monthly'
                                      ? AppColors.primaryCyan.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _reportType == 'Monthly' ? AppColors.primaryCyan : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Monthly Report',
                                  style: TextStyle(
                                    color: _reportType == 'Monthly' ? AppColors.primaryCyan : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.canvasLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: AppColors.primaryCyan, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _reportType == 'Daily'
                                        ? 'Selected Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                                        : 'Selected Month: ${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total Summary & PDF Download Card
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
                          _item('Gross Revenue', '₹${_grossRevenue.toInt()}', AppColors.primaryCyan),
                          _item('Advance Paid', '₹${_advanceCollected.toInt()}', AppColors.successGreen),
                          _item('Net Income', '₹${_netIncome.toInt()}', AppColors.warningAmber),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Download PDF',
                              variant: ButtonVariant.secondary,
                              icon: Icons.picture_as_pdf_rounded,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Downloading PDF Report...')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Export Excel',
                              variant: ButtonVariant.outline,
                              icon: Icons.download_rounded,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exporting CSV Ledger Statement...')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bookings Overview Stats
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Bookings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$_totalBookings', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Container(height: 30, width: 1, color: AppColors.borderHairline),
                      Column(
                        children: [
                          const Text('Completed Trips', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$_completedBookings', style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transaction Log
                Text(
                  _reportType == 'Daily' ? "Today's Transaction Log" : "Recent Billing Log",
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (_transactions.isEmpty && !_isLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted.withAlpha(120)),
                        const SizedBox(height: 12),
                        const Text(
                          'No Transactions Found',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bookings and customer invoices for this period will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: _transactions.take(10).map((b) {
                        return Column(
                          children: [
                            _txRow(
                              b.id,
                              b.customerName,
                              b.vehicleName,
                              b.status.name.toUpperCase(),
                              '₹${b.totalAmount.toInt()}',
                              '${b.startDate.day}/${b.startDate.month}/${b.startDate.year}',
                            ),
                            const Divider(color: AppColors.borderHairline, height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(String title, String val, Color c) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }

  Widget _txRow(String id, String name, String vehicle, String mode, String amount, String time) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$id • $name', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$vehicle • $mode ($time)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
