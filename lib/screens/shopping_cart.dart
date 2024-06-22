import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/screens/checking_page.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/widgets/bottom_tabs.dart';

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  FirebaseServices _firebaseServices = FirebaseServices();

  List<Item> itemsList = [];

  double total = 0;
  double totalWeight = 0;

  static final DateTime now = DateTime.now();
  static final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm:ss');
  final String formatted = formatter.format(now);

  void scanQRCode() async {
    await FlutterBarcodeScanner.scanBarcode(
            '#1faa00', "Cancel", true, ScanMode.BARCODE)
        .then((value) {
      print(value);
      _firebaseServices.productsRef
          .where('barcode', isEqualTo: value)
          .get()
          .then((val) {
        itemsList.add(new Item(
          barcode: val.docs.first['barcode'],
          name: val.docs.first['name'],
          price: double.parse(val.docs.first['price'].toString()),
          weight: double.parse(val.docs.first['weight'].toString()),
          quantity: 1,
          photo: val.docs.first['image'],
        ));
        ScaffoldMessenger.of(context).showSnackBar(_snackBarItemAdded);
        getTotals();
      });
    });
  }

  getTotals() {
    total = 0;
    totalWeight = 0;
    for (var item in itemsList) {
      total += item.price * item.quantity;
      totalWeight += item.weight * item.quantity;
    }
    setState(() {});
  }

  final SnackBar _snackBarItemAdded = SnackBar(
    content: Text(
      "Item added to cart!",
      style: TextStyle(color: Colors.white),
    ),
    backgroundColor: Color(0xff1faa00),
    duration: Duration(seconds: 2),
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Shopping Cart',
            style: Constants.boldHeadingAppBar,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          toolbarHeight: 200.0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                image: DecorationImage(
                    image: AssetImage("assets/image2.png"),
                    fit: BoxFit.cover
                )
            ),
          ),
        ),
        body: SafeArea(
          child: itemsList.isNotEmpty ? buildBody() : emptyBodyBuild(),
        ),
        bottomNavigationBar: itemsList.isNotEmpty
            ? Container(
                height: 180.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    cartBottomTabTotal(total),
                    CartBottomTabBtn(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CheckingPage(
                                  itemsList: itemsList,
                                  total: total,
                                  totalWeight: totalWeight,
                                )));
                      },
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget buildBody() {
    return ListView.builder(
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
