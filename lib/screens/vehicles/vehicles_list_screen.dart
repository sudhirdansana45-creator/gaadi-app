import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/custom_button.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class VehiclesListScreen extends StatefulWidget {
  final Future<void> Function(String route, {dynamic args}) onNavigate;

  const VehiclesListScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  String _selectedCategory = 'All'; // 'All', 'Cars', 'Bikes'
  String _selectedFilter = 'All Status';
  String _searchQuery = '';
  bool _isLoading = false;
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getVehicles();
      if (res != null && res['data'] != null) {
        final list = (res['data'] as List)
            .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _vehicles = list;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ _loadVehicles error: $e');
      // Offline fallback: keep cached data
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredVehicles = _vehicles.where((v) {
      // Category Tab Filter
      if (_selectedCategory == 'Cars') {
        if (v.category.toLowerCase().contains('bike') || v.category.toLowerCase().contains('scooter')) {
          return false;
        }
      } else if (_selectedCategory == 'Bikes') {
        if (!v.category.toLowerCase().contains('bike') && !v.category.toLowerCase().contains('scooter')) {
          return false;
        }
      }

      // Status Chip Filter
      if (_selectedFilter == 'Available' && v.status != VehicleStatus.available) return false;
      if (_selectedFilter == 'Booked' && v.status != VehicleStatus.booked) return false;
      if (_selectedFilter == 'In Service' && v.status != VehicleStatus.inService) return false;
      if (_selectedFilter == 'Disabled' && v.status != VehicleStatus.disabled) return false;

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return v.name.toLowerCase().contains(q) ||
            v.regNumber.toLowerCase().contains(q) ||
            v.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.textDark,
        onPressed: () async {
          await widget.onNavigate('add_vehicle');
          _loadVehicles();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadVehicles,
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
            // Search & Add Button Header
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search reg plate, model or category...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppColors.canvasLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CustomButton(
                  text: '+ Add',
                  width: 90,
                  height: 48,
                  onPressed: () async {
                    await widget.onNavigate('add_vehicle');
                    _loadVehicles();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Car / Bike Category Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.canvasLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  _categoryTab('All', 'All Vehicles', Icons.directions_car_filled_rounded),
                  _categoryTab('Cars', 'Cars & SUVs', Icons.time_to_leave_rounded),
                  _categoryTab('Bikes', 'Bikes & Scooters', Icons.two_wheeler_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All Status', 'Available', 'Booked', 'In Service', 'Disabled'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedFilter = filter),
                      selectedColor: AppColors.primaryCyan,
                      backgroundColor: AppColors.surfaceCard,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryCyan : AppColors.borderSubtle,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Cards Grid or Empty State
            if (filteredVehicles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.canvasLow,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Center(
                        child: Icon(Icons.directions_car_outlined, color: AppColors.textSecondary, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty || _selectedFilter != 'All Status' || _selectedCategory != 'All'
                          ? 'No Matching Vehicles Found'
                          : 'No Vehicles in Fleet',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty || _selectedFilter != 'All Status' || _selectedCategory != 'All'
                          ? 'Try clearing your filters or search keywords.'
                          : 'Register your first car or bike to start managing rentals and bookings.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      text: '+ Add Vehicle',
                      width: 160,
                      height: 40,
                      onPressed: () async {
                        await widget.onNavigate('add_vehicle');
                        _loadVehicles();
                      },
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: crossCount == 1 ? 1.35 : 0.95,
                    ),
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = filteredVehicles[index];
                      return _buildVehicleCard(vehicle);
                    },
                  );
                },
              ),
            const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _categoryTab(String key, String title, IconData icon) {
    final isSelected = _selectedCategory == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.5)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final bool isDisabled = vehicle.status == VehicleStatus.disabled;

    return Container(
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.canvasLow : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDisabled ? AppColors.criticalBorder : AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Opacity(
        opacity: isDisabled ? 0.65 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.canvasLow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    vehicle.regNumber,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                StatusChip.fromVehicleStatus(vehicle.status),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      vehicle.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, err, stack) => Container(
                        color: AppColors.surfaceHover,
                        child: const Center(
                          child: Icon(Icons.directions_car_rounded, color: AppColors.textMuted, size: 40),
                        ),
                      ),
                    ),
                    if (isDisabled)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: AppColors.warningAmber, size: 32),
                              SizedBox(height: 4),
                              Text(
                                'DISABLED',
                                style: TextStyle(
                                  color: AppColors.warningAmber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Partner: ${vehicle.assignedPartner}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              vehicle.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${vehicle.fuelType} • ${vehicle.transmission}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                Text(
                  '₹${vehicle.dailyRate.toInt()}/day',
                  style: const TextStyle(color: AppColors.primaryCyan, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: isDisabled ? 'Disabled' : 'New Booking',
                    height: 36,
                    variant: isDisabled ? ButtonVariant.ghost : ButtonVariant.primary,
                    onPressed: isDisabled ? () {} : () => widget.onNavigate('new_booking', args: vehicle),
                  ),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'Report',
                  variant: ButtonVariant.secondary,
                  width: 70,
                  height: 36,
                  onPressed: () => widget.onNavigate('vehicle_wise_report', args: vehicle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
