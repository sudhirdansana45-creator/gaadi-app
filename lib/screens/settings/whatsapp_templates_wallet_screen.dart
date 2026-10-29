import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_bottom_sheet.dart';

class WhatsappTemplatesWalletScreen extends StatefulWidget {
  final VoidCallback onBack;

  const WhatsappTemplatesWalletScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<WhatsappTemplatesWalletScreen> createState() => _WhatsappTemplatesWalletScreenState();
}

class _WhatsappTemplatesWalletScreenState extends State<WhatsappTemplatesWalletScreen> {
  final TextEditingController _templateController = TextEditingController(
    text: 'Hello {customer_name}, your booking for {vehicle} is confirmed! Pickup: {pickup_time}, Return: {return_time}. Pending balance: {amount_due}. Drive safe!',
  );

  final List<String> _variables = [
    '{customer_name}',
    '{vehicle}',
    '{pickup_time}',
    '{return_time}',
    '{amount_due}',
  ];

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  void _insertVariable(String variableText) {
    final currentText = _templateController.text;
    final selection = _templateController.selection;
    final start = selection.start >= 0 ? selection.start : currentText.length;
    final end = selection.end >= 0 ? selection.end : currentText.length;

    final newText = currentText.replaceRange(start, end, variableText);
    _templateController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + variableText.length),
    );
    setState(() {});
  }

  String _getPreviewText() {
    String text = _templateController.text;
    text = text.replaceAll('{customer_name}', 'Rahul Verma');
    text = text.replaceAll('{vehicle}', 'Mahindra Thar 4x4 (DL 01 AB 1234)');
    text = text.replaceAll('{pickup_time}', '10:00 AM, 05 Oct');
    text = text.replaceAll('{return_time}', '06:00 PM, 07 Oct');
    text = text.replaceAll('{amount_due}', '₹7,000');
    return text;
  }

  void _showMessageLogSheet() {
    final logs = [
      {
        'name': 'Rahul Verma',
        'phone': '+91 98765 43210',
        'type': 'Booking Confirmation',
        'time': '10:30 AM Today',
        'status': 'Delivered',
        'color': AppColors.successGreen,
      },
      {
        'name': 'Priya Sharma',
        'phone': '+91 98111 22334',
        'type': 'Vehicle Handover Link',
        'time': '09:15 AM Today',
        'status': 'Sent',
        'color': AppColors.infoBlue,
      },
      {
        'name': 'Vikram Singh',
        'phone': '+91 97654 32109',
        'type': 'Overdue Return Alert',
        'time': 'Yesterday, 06:00 PM',
        'status': 'Failed',
        'color': AppColors.criticalRed,
      },
      {
        'name': 'Amit Patel',
        'phone': '+91 99000 88776',
        'type': 'Payment Receipt',
        'time': '03 Oct, 02:45 PM',
        'status': 'Delivered',
        'color': AppColors.successGreen,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppBottomSheet(
        title: 'WhatsApp Message Dispatch Log',
        subtitle: 'Real-time delivery status for automated messages',
        primaryActionText: 'Close Log',
        onPrimaryAction: () => Navigator.pop(ctx),
        content: Column(
          children: logs.map((log) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryCyan, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log['name']} (${log['phone']})',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${log['type']} • ${log['time']}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (log['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (log['color'] as Color).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      log['status'] as String,
                      style: TextStyle(
                        color: log['color'] as Color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WhatsApp Automation & Wallet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Automated Customer Reminders & Message Templates', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amber Low Balance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Balance low. Messages will stop when it reaches ₹0.',
                    style: TextStyle(color: AppColors.warningAmber, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                CustomButton(
                  text: 'Recharge',
                  variant: ButtonVariant.secondary,
                  height: 32,
                  width: 85,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Balance & Log Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Credits Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('1,420 Credits', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w900, fontSize: 22)),
                      ],
                    ),
                    CustomButton(
                      text: '+ Recharge Wallet',
                      width: 135,
                      height: 40,
                      onPressed: () {},
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderHairline, height: 24),
                InkWell(
                  onTap: _showMessageLogSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.list_alt_rounded, color: AppColors.primaryCyan, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'View Message Log & Delivery History',
                          style: TextStyle(color: AppColors.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryCyan, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Template Editor Section
          const Text('Template Editor & Variable Chips', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Tap chips to insert dynamic placeholders into message', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),

          // Variable Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _variables.map((v) {
              return ActionChip(
                backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.12),
                side: const BorderSide(color: AppColors.primaryCyan, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                avatar: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryCyan, size: 14),
                label: Text(
                  v,
                  style: const TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _insertVariable(v),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Text Field Controller
          TextField(
            controller: _templateController,
            maxLines: 4,
            onChanged: (val) => setState(() {}),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceCard,
              hintText: 'Type your message template here...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Live WhatsApp Preview Bubble
          const Text('Live WhatsApp Message Preview', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B141A), // Dark WhatsApp Chat background color
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF202C33)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'WhatsApp Dispatch Preview',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005C4B), // WhatsApp sent message green
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPreviewText(),
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Spacer(),
                            Text(
                              '10:42 AM',
                              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.done_all_rounded, color: Color(0xFF34B7F1), size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 110),
        ],
      ),
    ),
  );
  }
}

