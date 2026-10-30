import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class StoreScreen extends StatefulWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const StoreScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = false;
  List<StoreProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getStoreProducts();
      if (res != null && res['data'] is List && mounted) {
        final List list = res['data'];
        final dynamicItems = list.map((item) => StoreProduct.fromJson(item)).toList();
        setState(() => _products = dynamicItems);
      }
    } catch (_) {
      // Graceful offline fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadProducts,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet Store Inventory', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('GPS Trackers, FASTag Scanners, Dashcams & Insurance', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryCyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryCyan)),
                  child: const Row(
                    children: [
                      Icon(Icons.local_shipping_rounded, color: AppColors.primaryCyan, size: 14),
                      SizedBox(width: 4),
                      Text('Free Express Delivery', style: TextStyle(color: AppColors.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_products.isEmpty && !_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted.withAlpha(120)),
                    const SizedBox(height: 16),
                    const Text(
                      'No Hardware Inventory Found',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'GPS Trackers, FASTag Scanners and Dashcams will appear here once listed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                  return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: crossCount == 1 ? 1.3 : 0.82,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: AppColors.surfaceHover, child: const Icon(Icons.shopping_bag_rounded, color: AppColors.textMuted, size: 36))),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('SPONSORED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    ),
                                  ),
                                  if (p.isPopular)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.primaryCyan, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('BESTSELLER', style: TextStyle(color: AppColors.textDark, fontSize: 9, fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(p.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(p.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.verified_outlined, size: 12, color: AppColors.primaryCyan),
                              SizedBox(width: 4),
                              Text('Sold by Verified IoT Vendor', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₹${p.price.toInt()}', style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('₹${p.originalPrice.toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            text: 'View Specs & Order',
                            height: 36,
                            onPressed: () => widget.onNavigate('product_detail', args: p),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
          ],
        ),
      ),
    ),
  );
  }
}
