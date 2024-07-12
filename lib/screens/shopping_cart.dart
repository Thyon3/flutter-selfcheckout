import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/screens/checking.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/widgets/bottom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  List<Item> cartItems = [];
  bool _isLoading = false;
  double _totalPrice = 0.0;
  double _totalWeight = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getStringList('cart_items') ?? [];
    
    setState(() {
      cartItems = cartData.map((item) {
        final parts = item.split('|');
        return Item(
          name: parts[0],
          barcode: parts[1],
          price: double.tryParse(parts[2]) ?? 0.0,
          weight: double.tryParse(parts[3]) ?? 0.0,
          quantity: int.tryParse(parts[4]) ?? 1,
          photo: parts.length > 5 ? parts[5] : null,
        );
      }).toList();
      _calculateTotals();
    });
  }

  Future<void> _saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = cartItems.map((item) => 
      '${item.name}|${item.barcode}|${item.price}|${item.weight}|${item.quantity}|${item.photo ?? ""}'
    ).toList();
    await prefs.setStringList('cart_items', cartData);
  }

  void _calculateTotals() {
    _totalPrice = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    _totalWeight = cartItems.fold(0.0, (sum, item) => sum + (item.weight * item.quantity));
  }

  Future<void> _scanBarcode() async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcode != '-1') {
        await _fetchProductByBarcode(barcode);
      }
    } catch (e) {
      _showErrorDialog('Failed to scan barcode: $e');
    }
  }

  Future<void> _fetchProductByBarcode(String barcode) async {
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await _firebaseServices.productsRef
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final productData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final existingItemIndex = cartItems.indexWhere(
          (item) => item.barcode == barcode,
        );

        if (existingItemIndex != -1) {
          setState(() {
            cartItems[existingItemIndex].quantity++;
          });
        } else {
          final newItem = Item(
            name: productData['name'] ?? 'Unknown Product',
            barcode: productData['barcode'] ?? barcode,
            price: (productData['price'] ?? 0.0).toDouble(),
            weight: (productData['weight'] ?? 0.0).toDouble(),
            quantity: 1,
            photo: productData['photo'],
          );
          setState(() {
            cartItems.add(newItem);
          });
        }
        
        _calculateTotals();
        await _saveCartItems();
        _showSuccessDialog('Product added to cart!');
      } else {
        _showErrorDialog('Product not found for barcode: $barcode');
      }
    } catch (e) {
      _showErrorDialog('Failed to fetch product: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
      _calculateTotals();
    });
    _saveCartItems();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }

    setState(() {
      cartItems[index].quantity = newQuantity;
      _calculateTotals();
    });
    _saveCartItems();
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
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    return ListView.builder(
      itemCount: cartItems.length,
      itemCount: itemsList.length,
      itemBuilder: (context, index) {
        return buildItem(itemsList[index], index);
      },
    );
  }

  Widget buildItem(Item item, int index) {
    return Card(
      child: Dismissible(
        key: Key(item.hashCode.toString()), //HAS TO GIVE A UNIQUE KEY TO IDENTIFY THE DISMISS TILE
        onDismissed: (direction) => removeItem(item),
        direction: DismissDirection.startToEnd,
        background: Container(
          color: Color(0xffD50000),
          child: Icon(Icons.delete_rounded, color: Colors.white),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 15.0),
        ),
        child: ListTile(
          leading: Image.network(item.photo),
          title: Text(item.name),
          subtitle: Text(
                "LKR ${item.price}0\nQuantity: ${item.quantity}\nWeight: ${item.weight} kg",
                isThreeLine: true,
              ),
          trailing: Text(
            "LKR ${item.price * item.quantity}0",
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 16.0),
          ),
        ),
      ),
      elevation: 2.0,
    );
  }

  Container emptyBodyBuild() {
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              size: 50.0,
              color: Colors.black26,
            ),
            Text(
              "No items in cart.\nScan items to start!",
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  //FUNCTION TO REMOVE ITEMS FROM THE LIST
  void removeItem(Item item) {
    setState(() {
      itemsList.remove(item);
      getTotals();
    });
  }
}
