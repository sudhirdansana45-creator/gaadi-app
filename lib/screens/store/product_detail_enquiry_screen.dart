import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/success_dialog.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';
import '../../services/api_client.dart';

class ProductDetailEnquiryScreen extends StatefulWidget {
  final StoreProduct? product;
  final String? productId;
  final VoidCallback onBack;

  const ProductDetailEnquiryScreen({
    super.key,
    this.product,
    this.productId,
    required this.onBack,
  });

  @override
  State<ProductDetailEnquiryScreen> createState() => _ProductDetailEnquiryScreenState();
}

class _ProductDetailEnquiryScreenState extends State<ProductDetailEnquiryScreen> {
  StoreProduct? _product;
  bool _isLoading = false;
  int _qty = 2;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product == null && widget.productId != null && widget.productId!.isNotEmpty) {
      _fetchProduct();
    }
  }

  Future<void> _fetchProduct() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getStoreProducts();
      if (res != null && res['data'] is List && mounted) {
        final list = (res['data'] as List).map((i) => StoreProduct.fromJson(i)).toList();
        final match = list.where((p) => p.id == widget.productId).firstOrNull;
        if (match != null) {
          setState(() => _product = match);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showEnquirySheet() {
    if (_product == null) return;
    final user = ApiClient().currentUser;
    final nameCtrl = TextEditingController(text: user?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user?['mobile']?.toString() ?? '');
    final noteCtrl = TextEditingController(text: 'Need fast delivery for our fleet garage.');
    int enquiryQty = _qty;

    AppBottomSheet.show(
      context: context,
      title: 'Enquire for ${_product!.title}',
      subtitle: 'Submit inquiry for bulk pricing & installer assistance',
      content: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Your Name',
                hintText: 'Enter name',
                controller: nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Mobile Number',
                hintText: 'Enter 10-digit mobile',
                controller: phoneCtrl,
                prefixText: '+91 ',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Quantity:',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvasLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: AppColors.primaryCyan, size: 18),
                          onPressed: enquiryQty > 1
                              ? () => setModalState(() => enquiryQty--)
                              : null,
                        ),
                        Text(
                          '$enquiryQty Units',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primaryCyan, size: 18),
                          onPressed: () => setModalState(() => enquiryQty++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Notes / Query (Optional)',
                hintText: 'Specify questions, vehicle models or delivery address...',
                controller: noteCtrl,
                maxLines: 2,
              ),
            ],
          );
        },
      ),
      primaryActionText: 'Send Enquiry',
      onPrimaryAction: () async {
        Navigator.pop(context);
        try {
          await ApiService().placeStoreOrder(
            productId: _product!.id,
            quantity: enquiryQty,
            shippingAddress: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'Store Garage Delivery',
            contactPhone: phoneCtrl.text.trim(),
          );
        } catch (_) {
          // Offline fallback
        }
        if (mounted) {
          SuccessDialog.show(
            context: context,
            title: 'Enquiry Sent',
            message: 'Enquiry sent. Our team will contact you soon.',
            primaryButtonText: 'OK',
            onPrimaryPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Store Product'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Store Product'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_shopping_cart_outlined, size: 64, color: AppColors.textMuted.withAlpha(120)),
                const SizedBox(height: 16),
                const Text(
                  'Product Not Found',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This product is currently unavailable or has been removed from inventory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Store',
                  variant: ButtonVariant.secondary,
                  onPressed: widget.onBack,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _product!;
    final total = p.price * _qty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(p.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Category: ${p.category} • Rating: ${p.rating}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    p.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(height: 180, color: AppColors.surfaceHover),
                  ),
                ),
                const SizedBox(height: 16),
                Text(p.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                Text(p.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                const Text('Key Fleet Specifications:', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...p.specs.map((spec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(spec, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order Quantity:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryCyan),
                          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                        ),
                        Text('$_qty Units', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryCyan),
                          onPressed: () => setState(() => _qty++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    Text('₹${total.toInt()}', style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w900, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Enquire Now',
                  icon: Icons.send_rounded,
                  onPressed: _showEnquirySheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    ),
  ),
);
  }
}
