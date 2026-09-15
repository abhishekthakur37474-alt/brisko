import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/price_row.dart';
import '../addresses/address_controller.dart';
import '../addresses/address_model.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../location/location_controller.dart';
import '../location/store_closed_banner.dart';
import '../location/store_status.dart';
import '../orders/orders_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _method = 'cod';
  final _notes = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  bool _loading = false;
  bool _notesOpen = false;
  bool _addressesOpen = false;
  bool _receiverEdited = false;
  bool _phoneEdited = false;

  @override
  void initState() {
    super.initState();
    final savedAddress = ref.read(locationControllerProvider).address;
    final user = ref.read(currentUserProvider).valueOrNull;
    final savedName = savedAddress?.receiverName ?? '';
    _receiverName.text = savedName.isNotEmpty ? savedName : (user?.name ?? '');
    final savedPhone = savedAddress?.receiverPhone ?? '';
    _receiverPhone.text = savedPhone.isNotEmpty ? savedPhone : (user?.phone ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    _receiverName.dispose();
    _receiverPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    final items = ref.watch(cartProvider).valueOrNull ?? [];
    final price = ref.watch(priceBreakdownProvider);
    final coupon = ref.watch(appliedCouponProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final loyalty = ref.watch(loyaltyConfigProvider).valueOrNull;
    final redeem = ref.watch(redeemLoyaltyProvider);
    final addresses = ref.watch(addressesProvider).valueOrNull ?? [];

    ref.listen(locationControllerProvider, (previous, next) {
      final name = next.address?.receiverName ?? '';
      if (!_receiverEdited && name.isNotEmpty) _receiverName.text = name;
      final phone = next.address?.receiverPhone ?? '';
      if (!_phoneEdited && phone.isNotEmpty) _receiverPhone.text = phone;
    });

    final minPoints = loyalty?.minPointsToRedeem ?? 50;
    final canRedeem = (user?.loyaltyPoints ?? 0) >= minPoints;
    final storeClosed = ref.watch(storeStatusProvider).isClosed;
    final isPickup = loc.orderMode != OrderMode.delivery || loc.noCoverage;
    final canPlace = loc.outlet != null && (isPickup || loc.address != null) && items.isNotEmpty && !storeClosed;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const BriskoTopBar(
            title: 'Checkout',
            subtitle: 'Almost there',
            circularBack: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const StoreClosedBanner(margin: EdgeInsets.only(bottom: 12)),
                isPickup ? _pickupInfo(loc) : _deliveryAddress(loc, addresses),
                const SizedBox(height: 24),
                const _SectionTitle('Receiver details'),
                const SizedBox(height: 10),
                _SoftCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _receiverName,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => _receiverEdited = true,
                        decoration: const InputDecoration(
                          hintText: 'Who is receiving this order?',
                          filled: true,
                          fillColor: AppColors.warmBg,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _receiverPhone,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => _phoneEdited = true,
                        decoration: const InputDecoration(
                          hintText: 'Receiver phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: AppColors.warmBg,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Loyalty points'),
                const SizedBox(height: 10),
                _LoyaltyCard(
                  points: user?.loyaltyPoints ?? 0,
                  minPoints: minPoints,
                  perPoint: loyalty?.redemptionValuePerPoint ?? 1,
                  value: redeem,
                  enabled: canRedeem,
                  discount: price.loyaltyDiscount,
                  onChanged: (v) => ref.read(redeemLoyaltyProvider.notifier).state = v,
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Payment method'),
                const SizedBox(height: 10),
                _PayOption(
                  icon: Icons.payments_outlined,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your pizza arrives',
                  selected: _method == 'cod',
                  onTap: () => setState(() => _method = 'cod'),
                ),
                const SizedBox(height: 10),
                _PayOption(
                  icon: Icons.credit_card,
                  title: 'Online Payment',
                  subtitle: 'UPI, cards & more · Coming soon',
                  selected: _method == 'online',
                  onTap: () => setState(() => _method = 'online'),
                ),
                const SizedBox(height: 20),
                _NotesCard(
                  controller: _notes,
                  open: _notesOpen,
                  onToggle: () => setState(() => _notesOpen = !_notesOpen),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Price summary'),
                const SizedBox(height: 10),
                _SummaryCard(
                  subtotal: price.subtotal,
                  gst: price.gstAmount,
                  delivery: price.deliveryCharge,
                  couponDiscount: price.couponDiscount,
                  loyaltyDiscount: price.loyaltyDiscount,
                  total: price.finalAmount,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, -6)),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: _PlaceOrderButton(
            label: 'Place Order  •  ${rupees(price.finalAmount)}',
            loading: _loading,
            onPressed: canPlace
                ? () async {
                    if (_method == 'online') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online payment coming soon. Choose Cash on Delivery.')));
                      return;
                    }
                    final receiver = _receiverName.text.trim();
                    if (receiver.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receiver name is required')));
                      return;
                    }
                    final receiverPhone = _receiverPhone.text.trim();
                    if (receiverPhone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receiver phone is required')));
                      return;
                    }
                    if (!PhoneUtil.isValidIndianMobile(receiverPhone)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit mobile number')));
                      return;
                    }
                    setState(() => _loading = true);
                    try {
                      final fallbackAddress = loc.address ??
                          AddressModel(
                            id: 'pickup_${loc.outlet!.id}',
                            label: isPickup ? 'Pickup' : 'Delivery',
                            receiverName: receiver,
                            receiverPhone: receiverPhone,
                            fullAddress: loc.outlet!.address,
                            lat: loc.outlet!.lat,
                            lng: loc.outlet!.lng,
                            outletId: loc.outlet!.id,
                            isDefault: true,
                          );
                      final id = await ref.read(ordersControllerProvider).placeOrder(
                            items: items,
                            address: fallbackAddress,
                            outletId: loc.outlet!.id,
                            price: price,
                            paymentMethod: _method,
                            notes: _notes.text,
                            couponCode: coupon?.code,
                            orderMode: loc.orderMode,
                            receiverName: receiver,
                            receiverPhone: receiverPhone,
                          );
                      if (context.mounted) context.go('/order-confirm/$id');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Widget _pickupInfo(LocationState loc) {
    final outlet = loc.outlet;
    final isDineIn = loc.orderMode == OrderMode.dineIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(isDineIn ? 'Dine-In outlet' : 'Pickup outlet'),
        const SizedBox(height: 10),
        _SoftCard(
          padding: const EdgeInsets.all(14),
          borderColor: outlet != null ? AppColors.primary.withValues(alpha: 0.35) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.storefront_outlined, color: AppColors.primary, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet?.name ?? 'No outlet selected',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15.5, color: AppColors.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      outlet?.address ?? '',
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppColors.muted),
                    ),
                    if (outlet != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.muted),
                          const SizedBox(width: 5),
                          Text(
                            '${outlet.openTime} – ${outlet.closeTime}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      isDineIn ? "You'll eat in at the outlet." : "You'll collect the order at the outlet.",
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/location'),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Change',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deliveryAddress(LocationState loc, List<AddressModel> addresses) {
    final a = loc.address;
    final canToggle = addresses.isNotEmpty;
    final VoidCallback action = canToggle
        ? () => setState(() => _addressesOpen = !_addressesOpen)
        : () => context.push('/addresses');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Delivery address'),
        const SizedBox(height: 10),
        _SoftCard(
          padding: const EdgeInsets.all(14),
          borderColor: a != null ? AppColors.primary.withValues(alpha: 0.35) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation04,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (a?.label.isNotEmpty ?? false) ? a!.label : 'Delivery address',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15.5, color: AppColors.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      a?.fullAddress ?? 'No address selected',
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppColors.muted),
                    ),
                    if (loc.outlet != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 14, color: AppColors.muted),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              loc.outlet!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: action,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a == null ? 'Add' : 'Change',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                      ),
                      if (canToggle) ...[
                        const SizedBox(width: 2),
                        AnimatedRotation(
                          turns: _addressesOpen ? 0.5 : 0,
                          duration: AppMotion.fast,
                          curve: AppMotion.easeOut,
                          child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          alignment: Alignment.topCenter,
          child: !_addressesOpen || addresses.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      ...addresses.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SavedAddressTile(
                            address: item,
                            selected: item.id == a?.id,
                            onTap: () {
                              final outlets = ref.read(outletsProvider).valueOrNull ?? [];
                              ref.read(locationControllerProvider.notifier).setFromSaved(item, outlets);
                              setState(() => _addressesOpen = false);
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.push('/addresses'),
                          icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                          label: const Text('Manage addresses'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.text),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? background;
  final Color? borderColor;
  final double radius;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.borderColor,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border.withValues(alpha: 0.8)),
        boxShadow: AppColors.softShadow,
      ),
      child: child,
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final double size;

  const _RadioDot({required this.selected, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.6),
      ),
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          child: Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  const _SavedAddressTile({required this.address, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft.withValues(alpha: 0.45) : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border.withValues(alpha: 0.8),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (address.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Default',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  final int points;
  final int minPoints;
  final double perPoint;
  final bool value;
  final bool enabled;
  final double discount;
  final ValueChanged<bool> onChanged;

  const _LoyaltyCard({
    required this.points,
    required this.minPoints,
    required this.perPoint,
    required this.value,
    required this.enabled,
    required this.discount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedDiscount01,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeem points',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '$points points available',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min $minPoints pts · 1 pt = ${rupees(perPoint)}',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
                ),
                if (value && discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '- ${rupees(discount)}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            thumbColor: WidgetStateProperty.all(AppColors.white),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
            ),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PayOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft.withValues(alpha: 0.5) : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border.withValues(alpha: 0.8),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? AppColors.white : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final bool open;
  final VoidCallback onToggle;

  const _NotesCard({required this.controller, required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notes_outlined, size: 20, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add order notes',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.text),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Optional',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AppMotion.fast,
                    curve: AppMotion.easeOut,
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Any special instructions?',
                        filled: true,
                        fillColor: AppColors.warmBg,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double gst;
  final double delivery;
  final double couponDiscount;
  final double loyaltyDiscount;
  final double total;

  const _SummaryCard({
    required this.subtotal,
    required this.gst,
    required this.delivery,
    required this.couponDiscount,
    required this.loyaltyDiscount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          PriceRow('Subtotal', rupees(subtotal)),
          PriceRow('GST', rupees(gst)),
          PriceRow(
            'Delivery',
            delivery == 0 ? 'FREE' : rupees(delivery),
            valueColor: delivery == 0 ? AppColors.success : null,
          ),
          if (couponDiscount > 0) PriceRow('Coupon', '- ${rupees(couponDiscount)}', valueColor: AppColors.success),
          if (loyaltyDiscount > 0) PriceRow('Loyalty', '- ${rupees(loyaltyDiscount)}', valueColor: AppColors.success),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Text(
                  'To pay',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text),
                ),
                const Spacer(),
                Text(
                  rupees(total),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 19, color: AppColors.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOrderButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const _PlaceOrderButton({
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  State<_PlaceOrderButton> createState() => _PlaceOrderButtonState();
}

class _PlaceOrderButtonState extends State<_PlaceOrderButton> {
  bool _pressed = false;

  bool get _enabled => !widget.loading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed && _enabled ? 0.98 : 1,
      duration: AppMotion.micro,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _enabled ? widget.onPressed : null,
              onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(18),
              child: Opacity(
                opacity: _enabled ? 1 : 0.45,
                child: Center(
                  child: widget.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}