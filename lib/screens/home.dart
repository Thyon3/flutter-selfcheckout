import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/screens/cart_history.dart';
import 'package:selfcheckoutapp/screens/shopping_cart.dart';
import 'package:selfcheckoutapp/screens/shopping_list.dart';
import 'package:selfcheckoutapp/widgets/app_drawer.dart';
import 'package:selfcheckoutapp/widgets/bottom_tabs.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text(
          'ScanGo',
          style: GoogleFonts.poppins(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xff1faa00),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to ScanGo!',
                style: GoogleFonts.poppins(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1faa00),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.0),
              Text(
                'Choose an option below to get started:',
                style: GoogleFonts.poppins(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.0),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  children: [
                    HomeNavigateTabs(
                      text: 'Create Shopping List',
                      icon: Icons.list_alt,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShoppingListPage(),
                          ),
                        );
                      },
                    ),
                    HomeNavigateTabs(
                      text: 'View Cart History',
                      icon: Icons.history,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillHistoryPage(),
                          ),
                        );
                      },
                    ),
                    HomeNavigateTabs(
                      text: 'Start Shopping',
                      icon: Icons.shopping_cart,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShoppingCartPage(),
                          ),
                        );
                      },
                    ),
                    HomeNavigateTabs(
                      text: 'Profile Settings',
                      icon: Icons.person,
                      onPressed: () {
                        // Navigate to profile
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
