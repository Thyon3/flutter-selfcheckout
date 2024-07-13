import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:selfcheckoutapp/services/payment_services.dart';
import 'package:selfcheckoutapp/widgets/custom_button.dart';
import 'package:selfcheckoutapp/widgets/custom_input.dart';

class CheckingPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  CheckingPage({
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  _CheckingPageState createState() => _CheckingPageState();
}

class _CheckingPageState extends State<CheckingPage> {
  CreditCardModel _card = CreditCardModel();
  bool _isLoading = false;
  bool _useNewCard = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Color(0xff1faa00),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOrderSummary(),
              SizedBox(height: 20.0),
              _buildPaymentMethodToggle(),
              SizedBox(height: 20.0),
              if (_useNewCard) _buildNewCardForm() else _buildExistingCardForm(),
              SizedBox(height: 20.0),
              CustomBtn(
                text: 'Pay LKR ${widget.totalPrice.toStringAsFixed(2)}',
                onPressed: _processPayment,
                isLoading: _isLoading,
              ),
              SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xff1faa00),
              ),
            ),
            SizedBox(height: 12.0),
            ...widget.cartItems.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item['name']} x${item['quantity']}',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ),
                  Text(
                    'LKR ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'LKR ${widget.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1faa00),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodToggle() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.0),
            RadioListTile(
              title: Text('New Card'),
              value: true,
              groupValue: _useNewCard,
              onChanged: (value) => setState(() => _useNewCard = value!),
            ),
            RadioListTile(
              title: Text('Existing Card'),
              value: false,
              groupValue: _useNewCard,
              onChanged: (value) => setState(() => _useNewCard = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            CreditCardWidget(
              onCreditCardModelChange: (model) {
                setState(() => _card = model);
              },
            ),
            SizedBox(height: 16.0),
            CustomInput(
              hintText: 'Cardholder Name',
              textEditingController: TextEditingController(),
              textInputType: TextInputType.name,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingCardForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Existing Card',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              height: 100.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text('No saved cards available'),
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!PaymentService.validateCard(_card)) {
      _showErrorDialog('Please enter valid card details');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await PaymentService.processPayment(
        card: _card,
        amount: widget.totalPrice,
        description: 'ScanGo Purchase - ${widget.cartItems.length} items',
      );

      if (result['success']) {
        await PaymentService.saveTransaction(
          paymentIntentId: result['paymentIntentId'],
          amount: widget.totalPrice,
          cardType: PaymentService.getCardType(_card.cardNumber),
          items: widget.cartItems,
        );

        _showSuccessDialog('Payment successful!');
      } else {
        _showErrorDialog('Payment failed: ${result['error']}');
      }
    } catch (e) {
      _showErrorDialog('Payment error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
