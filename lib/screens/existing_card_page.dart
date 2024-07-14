import 'package:flutter/cupertino.dart';
import 'package:flutter_credit_card/credit_card_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/screens/home.dart';
import 'package:selfcheckoutapp/services/payment_services.dart';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/widgets/custom_button.dart';

class ExistingCardPage extends StatefulWidget {
  @override
  _ExistingCardPageState createState() => _ExistingCardPageState();
}

class _ExistingCardPageState extends State<ExistingCardPage> {
  List<Map<String, String>> _savedCards = [];
  int? _selectedCardIndex;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  void _loadSavedCards() {
    // In a real app, this would load from secure storage
    setState(() {
      _savedCards = [
        {
          'last4': '4242',
          'brand': 'Visa',
          'expiry': '12/25',
        },
        {
          'last4': '5555',
          'brand': 'MasterCard', 
          'expiry': '08/24',
        },
      ];
    });
  }

  void _selectCard(int index) {
    setState(() {
      _selectedCardIndex = index;
    });
  }

  void _useSelectedCard() {
    if (_selectedCardIndex != null) {
      Navigator.pop(context, {
        'useExisting': true,
        'cardIndex': _selectedCardIndex,
      });
    }
  }

  void _addNewCard() {
    Navigator.pop(context, {
      'useExisting': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xff1faa00),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewCard,
            tooltip: 'Add New Card',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.0),
            Text(
              'Choose a saved card or add a new one',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: ListView.builder(
                itemCount: _savedCards.length,
                itemBuilder: (context, index) {
                  final card = _savedCards[index];
                  final isSelected = _selectedCardIndex == index;
                  
                  return Card(
                    margin: EdgeInsets.only(bottom: 12.0),
                    elevation: isSelected ? 8.0 : 2.0,
                    color: isSelected ? Color(0xff1faa00).withOpacity(0.1) : Colors.white,
                    child: InkWell(
                      onTap: () => _selectCard(index),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: _getCardColor(card['brand']!),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Center(
                                child: Text(
                                  card['brand']![0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '••••• ${card['last4']}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    'Expires ${card['expiry']}',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Color(0xff1faa00),
                                size: 24.0,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
            CustomBtn(
              text: 'Use Selected Card',
              onPressed: _selectedCardIndex != null ? _useSelectedCard : null,
              isLoading: false,
            ),
            SizedBox(height: 12.0),
            CustomBtn(
              text: 'Add New Card',
              onPressed: _addNewCard,
              outlineBtn: true,
              isLoading: false,
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Color(0xff1A1F71);
      case 'mastercard':
        return Color(0xffEB001B);
      case 'american express':
        return Color(0xff0077A6);
      case 'discover':
        return Color(0xffFF6000);
      default:
        return Colors.grey;
    }
  }
}
