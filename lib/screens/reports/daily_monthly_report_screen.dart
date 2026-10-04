import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

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

  // Dummy Chart Data for Daily (Hourly) & Monthly (Weekly)
  final List<Map<String, dynamic>> _dailyChartData = [
    {'time': '08 AM', 'amount': 1500.0, 'label': '1.5k'},
    {'time': '11 AM', 'amount': 4200.0, 'label': '4.2k'},
    {'time': '02 PM', 'amount': 8800.0, 'label': '8.8k'},
    {'time': '05 PM', 'amount': 12500.0, 'label': '12.5k'},
    {'time': '08 PM', 'amount': 9400.0, 'label': '9.4k'},
    {'time': '11 PM', 'amount': 3100.0, 'label': '3.1k'},
  ];

  final List<Map<String, dynamic>> _monthlyChartData = [
    {'time': 'Week 1', 'amount': 38000.0, 'label': '38k'},
    {'time': 'Week 2', 'amount': 54000.0, 'label': '54k'},
    {'time': 'Week 3', 'amount': 46000.0, 'label': '46k'},
    {'time': 'Week 4', 'amount': 62000.0, 'label': '62k'},
  ];

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _reportType == 'Daily' ? _dailyChartData : _monthlyChartData;
    final maxAmount = chartData.map((e) => e['amount'] as double).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        onTap: () => setState(() => _reportType = 'Daily'),
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
                        onTap: () => setState(() => _reportType = 'Monthly'),
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
                                  : 'Selected Month: October 2026',
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
                    _item('Gross Revenue', _reportType == 'Daily' ? '₹39,500' : '₹2,00,000', AppColors.primaryCyan),
                    _item('UPI / Online', _reportType == 'Daily' ? '₹28,000' : '₹1,45,000', AppColors.successGreen),
                    _item('Cash Collected', _reportType == 'Daily' ? '₹11,500' : '₹55,000', AppColors.warningAmber),
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
                        text: 'Export Excel (CSV)',
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

          // Dark Theme Earnings Bar Chart Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _reportType == 'Daily' ? 'Hourly Revenue Breakdown' : 'Weekly Collection Overview',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Icon(Icons.show_chart_rounded, color: AppColors.primaryCyan, size: 20),
                  ],
                ),
                const SizedBox(height: 24),

                // Bar Chart Visual Container
                SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chartData.map((item) {
                      final double heightFactor = (item['amount'] as double) / maxAmount;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '₹${item['label']}',
                            style: const TextStyle(color: AppColors.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: _reportType == 'Daily' ? 24 : 36,
                            height: (100 * heightFactor).clamp(16.0, 110.0),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['time'] as String,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Transaction Log
          Text(
            _reportType == 'Daily' ? "Today's Transaction Log" : "Monthly Billing Log",
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _txRow('BK-1089', 'Rahul Verma', 'Mahindra Thar', 'UPI', '₹3,500', '11:45 AM'),
                const Divider(color: AppColors.borderHairline, height: 1),
                _txRow('BK-1088', 'Priya Sharma', 'RE Classic 350', 'Cash', '₹1,200', '10:15 AM'),
                const Divider(color: AppColors.borderHairline, height: 1),
                _txRow('BK-1087', 'Amit Patel', 'Creta SX', 'Card', '₹5,600', '09:30 AM'),
              ],
            ),
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$id • $name', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$vehicle • $mode ($time)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          Text(amount, style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
