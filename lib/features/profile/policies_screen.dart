import 'package:flutter/material.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Policies')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          SizedBox(height: 8),
          Text('Brisko Pizza collects your name, email, phone, address and order history to fulfill deliveries. Data is stored in Firebase. We do not sell personal data.'),
          SizedBox(height: 20),
          Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          SizedBox(height: 8),
          Text('Orders are subject to outlet availability and service area. Prices include GST as shown at checkout. Cash on Delivery is available in v1.'),
          SizedBox(height: 20),
          Text('Refund & Cancellation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          SizedBox(height: 8),
          Text('You may cancel while an order is Placed or Confirmed. After preparation starts, cancellation is not available. COD refunds are not applicable. Online payment refunds will follow gateway policy once enabled.'),
        ],
      ),
    );
  }
}
