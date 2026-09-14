import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../location/location_controller.dart';
import 'address_controller.dart';
import 'address_model.dart';

class DetectAddressScreen extends ConsumerStatefulWidget {
  const DetectAddressScreen({super.key});

  @override
  ConsumerState<DetectAddressScreen> createState() => _DetectAddressScreenState();
}

class _DetectAddressScreenState extends ConsumerState<DetectAddressScreen> {
  late final WebViewController _web;
  bool _loading = false;
  bool _saving = false;
  bool _showForm = false;
  String? _error;
  DetectedLocation? _detected;

  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _landmark = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _fallbackLat = 28.6139;
  static const _fallbackLng = 77.2090;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.white);
    _loadMap(_fallbackLat, _fallbackLng);
  }

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _landmark.dispose();
    _area.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _loadMap(double lat, double lng) {
    _web.loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>html,body,iframe{margin:0;padding:0;height:100%;width:100%;border:0;overflow:hidden;}</style>
</head>
<body>
<iframe src="https://maps.google.com/maps?q=$lat,$lng&z=16&hl=en&output=embed" allowfullscreen loading="lazy"></iframe>
</body>
</html>
''');
  }

  Future<void> _detect() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await LocationService().detect();
    if (!mounted) return;

    if (result.fail != null) {
      setState(() {
        _loading = false;
        _error = switch (result.fail!) {
          LocationFail.denied => 'Location permission denied. Allow location to continue.',
          LocationFail.deniedForever => 'Location permission is blocked. Enable it in settings.',
          LocationFail.gpsOff => 'Turn on device location and try again.',
          LocationFail.failed => 'Could not detect location. Try again.',
        };
      });
      return;
    }

    final loc = result.location!;
    _loadMap(loc.lat, loc.lng);
    _line1.text = loc.line1;
    _area.text = loc.area;
    _city.text = loc.city;
    _state.text = loc.state;
    _pincode.text = loc.pincode;
    setState(() {
      _loading = false;
      _detected = loc;
      _showForm = true;
    });
  }

  String _composeAddress() {
    return [
      _line1.text.trim(),
      _line2.text.trim(),
      _landmark.text.trim(),
      _area.text.trim(),
      _city.text.trim(),
      _state.text.trim(),
      _pincode.text.trim(),
    ].where((e) => e.isNotEmpty).join(', ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _detected == null) return;
    setState(() => _saving = true);

    final outlets = ref.read(outletsProvider).valueOrNull ?? [];
    final outlet = ref.read(locationControllerProvider.notifier).matchOutlet(_detected!.lat, _detected!.lng, outlets);
    final existing = ref.read(addressesProvider).valueOrNull ?? [];
    final makeDefault = existing.isEmpty;
    final fullAddress = _composeAddress();

    final savedId = await ref.read(addressControllerProvider).save(
          AddressModel(
            id: '',
            label: 'Home',
            fullAddress: fullAddress,
            lat: _detected!.lat,
            lng: _detected!.lng,
            outletId: outlet?.id,
            isDefault: makeDefault,
          ),
        );

    if (savedId != null) {
      ref.read(locationControllerProvider.notifier).setFromSaved(
            AddressModel(
              id: savedId,
              label: 'Home',
              fullAddress: fullAddress,
              lat: _detected!.lat,
              lng: _detected!.lng,
              outletId: outlet?.id,
              isDefault: makeDefault,
            ),
            outlets,
          );
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  InputDecoration _dec(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      alignLabelWithHint: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const BriskoTopBar(
            title: 'Detect address',
            subtitle: 'Pin your delivery location',
          ),
          Expanded(
            child: _showForm ? _formBody(bottom) : _mapBody(bottom),
          ),
        ],
      ),
    );
  }

  Widget _mapBody(double bottom) {
    return Column(
      children: [
        Expanded(
          child: ClipRect(
            child: WebViewWidget(controller: _web),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: _loading ? 'Detecting...' : 'Detect location',
                loading: _loading,
                onPressed: _detect,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formBody(double bottom) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
        children: [
          TextFormField(
            controller: _line1,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Address line 1', required: true),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Address line 1 is required' : null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _line2,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Address line 2'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _landmark,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Landmark'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _area,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Area'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('City'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _state,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('State'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pincode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: _dec('Pincode'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save address',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
