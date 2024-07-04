import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/constants.dart';

//BOTTOM NAVIGATION BAR BUTTON - INCLUDED IN BottomTabs CLASS
class BottomTabBtn extends StatelessWidget {
  final IconData iconData; //CUSTOM ICON
  final String icon;
  final bool selected;
  final Function onPressed;

  const BottomTabBtn(
      {Key key, this.icon, this.selected, this.iconData, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //CHECKING WHETHER THE TAB IS SELECTED
    bool _selected = selected ?? false;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 28.0, horizontal: 16.0),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  BottomTabBtn({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50.0,
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Color(0xff1faa00),
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20.0,
              ),
              SizedBox(width: 8.0),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeNavigateTabs extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  HomeNavigateTabs({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(20.0),
        margin: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50.0,
              color: Color(0xff1faa00),
            ),
            SizedBox(height: 10.0),
            Text(
              text,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CartBottomTabBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  CartBottomTabBtn({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60.0,
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Color(0xff1faa00),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}

class cartBottomTabTotal extends StatelessWidget {
  final String totalAmount;

  cartBottomTabTotal({
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total:',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            totalAmount,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Color(0xff1faa00),
            ),
          ),
        ],
      ),
    );
  }
}
