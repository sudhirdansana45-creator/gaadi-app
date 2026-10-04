import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../data/mock_data.dart';

class StoreScreen extends StatelessWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const StoreScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                decoration: BoxDecoration(color: AppColors.primaryCyan.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryCyan)),
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
                itemCount: MockData.storeProducts.length,
                itemBuilder: (context, i) {
                  final p = MockData.storeProducts[i];
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
                          onPressed: () => onNavigate('product_detail', args: p),
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
    );
  }
}
