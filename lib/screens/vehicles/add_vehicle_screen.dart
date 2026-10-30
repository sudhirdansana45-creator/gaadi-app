import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';

class AddVehicleScreen extends StatefulWidget {
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const AddVehicleScreen({
    super.key,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  String _selectedCategory = 'car'; // 'car' or 'bike'
  String _selectedFuel = 'Petrol';
  String _ownershipMode = 'own'; // 'own' or 'partner'
  
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _mfgYearController = TextEditingController();
  final _colorController = TextEditingController();
  
  final _hourlyRateCtrl = TextEditingController();
  final _dailyRateCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _extraKmCtrl = TextEditingController();

  final _partnerNameCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _handlePublish() async {
    final regNo = _regController.text.trim();
    final name = _nameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter vehicle brand & model'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }
    if (regNo.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter registration plate number'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().createVehicle(
        fields: {
          'name': name,
          'number': regNo,
          'type': _selectedCategory,
          'fuel_type': _selectedFuel,
          'daily_rate': _dailyRateCtrl.text.trim(),
          'hourly_rate': _hourlyRateCtrl.text.trim(),
          'security_deposit': _depositCtrl.text.trim(),
          'extra_km_rate': _extraKmCtrl.text.trim(),
          'color': _colorController.text.trim(),
          'year': _mfgYearController.text.trim(),
        },
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('🚀 Vehicle $regNo live on fleet!'),
            backgroundColor: const Color(0xFF06B6D4),
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      final msg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.criticalRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-Header Navigation / Helper Strip
                    _buildSubHeaderStrip(context),
                    const SizedBox(height: 12),

                    // Section 1: Vehicle Category Switcher (Car vs Bike)
                    _buildCategorySwitcher(context),
                    const SizedBox(height: 14),

                    // Visual Asset Showcase Banner
                    _buildShowcaseBanner(context),
                    const SizedBox(height: 16),

                    // Section 2: Identity & Specs Card
                    _buildIdentityAndSpecsCard(context),
                    const SizedBox(height: 16),

                    // Section 3: Rental Pricing & Tariff (Bento Matrix)
                    _buildTariffBentoCard(context),
                    const SizedBox(height: 16),

                    // Section 4: Fleet Ownership Structure
                    _buildOwnershipCard(context),
                    const SizedBox(height: 16),

                    // Section 5: Vehicle Documents
                    _buildDocumentsCard(context),
                    const SizedBox(height: 160), // Gap to prevent overlap with bottom tab menu
                  ],
                ),
              ),
            ),

            // Floating Sticky Action Deck
            _buildStickyActionDeck(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-HEADER HELPER STRIP
  // ---------------------------------------------------------------------------
  Widget _buildSubHeaderStrip(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: widget.onCancel,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Vehicle Form',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF252A36),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF4EDEAE)),
                  SizedBox(width: 6),
                  Text(
                    'Auto-saving',
                    style: TextStyle(
                      color: Color(0xFF4EDEAE),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF252A36),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.folder_open_rounded, color: Color(0xFF4CD7F6), size: 15),
                  SizedBox(width: 4),
                  Text(
                    'Drafts (2)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. VEHICLE CATEGORY SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildCategorySwitcher(BuildContext context) {
    final isCar = _selectedCategory == 'car';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF171B27),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = 'car';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isCar ? const Color(0xFF1B1F2B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isCar
                      ? const [
                          BoxShadow(
                            color: Color(0x59000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      color: isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Car / SUV',
                      style: TextStyle(
                        color: isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                        fontSize: 14,
                        fontWeight: isCar ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = 'bike';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isCar ? const Color(0xFF1B1F2B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isCar
                      ? const [
                          BoxShadow(
                            color: Color(0x59000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      color: !isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Bike / Scooter',
                      style: TextStyle(
                        color: !isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                        fontSize: 14,
                        fontWeight: !isCar ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHOWCASE BANNER
  // ---------------------------------------------------------------------------
  Widget _buildShowcaseBanner(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=800',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xF00E131E), Color(0x660E131E), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified, color: Color(0xFF003640), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Vehicle Profile Setup',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF303541),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Step 1 of 4',
                    style: TextStyle(
                      color: Color(0xFF4CD7F6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. IDENTITY & SPECS CARD
  // ---------------------------------------------------------------------------
  Widget _buildIdentityAndSpecsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Identity & Specs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BBD85).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'RTO COMPLIANT',
                  style: TextStyle(
                    color: Color(0xFF4EDEAE),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vehicle Model Field
          const Text(
            'Vehicle Brand & Model',
            style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Royal Enfield Meteor 350 / Mahindra Thar',
              hintStyle: const TextStyle(color: Color(0xFF869397), fontSize: 13),
              prefixIcon: const Icon(Icons.directions_car_rounded, color: Color(0xFF869397), size: 20),
              filled: true,
              fillColor: const Color(0xFF171B27),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Registration Plate (HSRP Format)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Registration Plate (HSRP Format)',
                style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Live Vahan Link',
                style: TextStyle(color: Color(0xFF4EDEAE), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // High-detail Indian Plate Box
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Left IND Strip
                Container(
                  width: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF303541),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'IND',
                        style: TextStyle(
                          color: Color(0xFF4CD7F6),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text('🇮🇳', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _regController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        color: Color(0xFF4CD7F6),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'KA 05 MN 4410',
                        hintStyle: TextStyle(color: Color(0xFF869397), fontSize: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF4EDEAE), size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2 Columns: Mfg Year & Color Shade
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mfg Year', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _mfgYearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF869397), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF171B27),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Color Shade', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _colorController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.palette_rounded, color: Color(0xFF869397), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF171B27),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fuel Type Chips
          const Text('Powertrain / Fuel Variant', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _fuelChip('Petrol', Icons.local_gas_station_rounded),
              const SizedBox(width: 6),
              _fuelChip('Diesel', Icons.opacity_rounded),
              const SizedBox(width: 6),
              _fuelChip('Electric', Icons.bolt_rounded),
              const SizedBox(width: 6),
              _fuelChip('CNG', Icons.propane_tank_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fuelChip(String label, IconData icon) {
    final isSelected = _selectedFuel == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFuel = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF171B27),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [BoxShadow(color: Color(0x6606B6D4), blurRadius: 10, offset: Offset(0, 3))]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF003640) : const Color(0xFFBCC9CD), size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF003640) : const Color(0xFFBCC9CD),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TARIFF & SECURITY RATES (BENTO MATRIX)
  // ---------------------------------------------------------------------------
  Widget _buildTariffBentoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.currency_rupee_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Tariff & Security Rates',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0566D9).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UPI READY',
                  style: TextStyle(
                    color: Color(0xFFADC6FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Bento Matrix
          Row(
            children: [
              Expanded(
                child: _bentoTile(
                  title: 'Hourly Rate',
                  rightBadge: null,
                  rightIcon: Icons.schedule_rounded,
                  ctrl: _hourlyRateCtrl,
                  currencyColor: const Color(0xFF4CD7F6),
                  footerText: 'PER HOUR CHARGE',
                  footerColor: const Color(0xFF869397),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bentoTile(
                  title: 'Daily Tariff',
                  rightBadge: 'POPULAR',
                  rightIcon: null,
                  ctrl: _dailyRateCtrl,
                  currencyColor: const Color(0xFF4CD7F6),
                  footerText: 'FULL 24 HRS CYCLE',
                  footerColor: const Color(0xFF869397),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _bentoTile(
                  title: 'Caution Money',
                  rightBadge: null,
                  rightIcon: Icons.verified_user_rounded,
                  ctrl: _depositCtrl,
                  currencyColor: const Color(0xFF4EDEAE),
                  footerText: '100% REFUNDABLE',
                  footerColor: const Color(0xFF4EDEAE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bentoTile(
                  title: 'Over-limit Km',
                  rightBadge: null,
                  rightIcon: Icons.speed_rounded,
                  ctrl: _extraKmCtrl,
                  currencyColor: const Color(0xFF4CD7F6),
                  footerText: 'PER EXCESS KM',
                  footerColor: const Color(0xFF869397),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bentoTile({
    required String title,
    required String? rightBadge,
    required IconData? rightIcon,
    required TextEditingController ctrl,
    required Color currencyColor,
    required String footerText,
    required Color footerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B27),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFFBCC9CD), fontSize: 11)),
              if (rightBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1BBD85).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rightBadge,
                    style: const TextStyle(color: Color(0xFF4EDEAE), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else if (rightIcon != null)
                Icon(rightIcon, color: currencyColor, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: currencyColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            footerText,
            style: TextStyle(
              color: footerColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FLEET OWNERSHIP STRUCTURE
  // ---------------------------------------------------------------------------
  Widget _buildOwnershipCard(BuildContext context) {
    final isPartner = _ownershipMode == 'partner';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.real_estate_agent_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Ownership & Payouts',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Financial Model',
                style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Segmented Ownership Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _ownershipMode = 'own'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isPartner ? const Color(0xFF1B1F2B) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, color: !isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Own Fleet (100%)',
                            style: TextStyle(
                              color: !isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                              fontSize: 12,
                              fontWeight: !isPartner ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _ownershipMode = 'partner'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPartner ? const Color(0xFF1B1F2B) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.handshake_rounded, color: isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Partner Attached',
                            style: TextStyle(
                              color: isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                              fontSize: 12,
                              fontWeight: isPartner ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isPartner) ...[
            const SizedBox(height: 14),
            const Text('Partner / Investor Full Name', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _partnerNameCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF869397), size: 20),
                filled: true,
                fillColor: const Color(0xFF171B27),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Revenue Share Split', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
                const Text('75% Owner / 25% Shop', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171B27),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Car Owner Payout', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      Text('75%', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar Split (75% Cyan / 25% Blue)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(flex: 75, child: Container(color: const Color(0xFF06B6D4))),
                          Expanded(flex: 25, child: Container(color: const Color(0xFF0566D9))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shop commission retention: 25%', style: TextStyle(color: Color(0xFF869397), fontSize: 10)),
                      Text('Direct Ledger Sync', style: TextStyle(color: Color(0xFF869397), fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. VEHICLE DOCUMENTS
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.folder_shared_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Vehicle Documents',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BBD85).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: Color(0xFF4EDEAE), size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Quick AI Scan',
                      style: TextStyle(color: Color(0xFF4EDEAE), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Upload Tile 1: RC Smart Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252A36),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.contact_emergency_rounded, color: Color(0xFF4CD7F6), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('RC Book / Smart Card', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          CircleAvatar(radius: 3, backgroundColor: Color(0xFF4EDEAE)),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text('DL01AB7729_RC_Front.pdf', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252A36),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.photo_camera_rounded, color: Color(0xFF4CD7F6), size: 14),
                      SizedBox(width: 4),
                      Text('Retake', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Upload Tile 2: Comprehensive Insurance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF252A36),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFFADC6FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comprehensive Insurance', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Digit General Insurance Ltd.', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Valid', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text('Policy Expiration Date', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 11)),
                const SizedBox(height: 4),
                TextField(
                  controller: _expiryDateCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.event_rounded, color: Color(0xFF869397), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF252A36),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FLOATING STICKY ACTION DECK
  // ---------------------------------------------------------------------------
  Widget _buildStickyActionDeck(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.width >= 1100 ? 0 : 84),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131E).withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          // Save Draft Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Draft successfully updated!'),
                  backgroundColor: Color(0xFF252A36),
                ),
              );
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF252A36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.save_rounded, color: Color(0xFFADC6FF), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Save Draft',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Publish to Fleet Button
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _handlePublish,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0566D9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x5906B6D4), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003640)),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_rounded, color: Color(0xFF003640), size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Publish to Fleet',
                              style: TextStyle(
                                color: Color(0xFF003640),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
