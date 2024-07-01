import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/constants.dart';

//CUSTOM BUTTONS TO LOGIN AND REGISTER PAGES / WHITE - GREEN
class CustomBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool outlineBtn;
  final bool isLoading;

  CustomBtn({
    required this.text,
    required this.onPressed,
    this.outlineBtn = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isOutlineBtn = outlineBtn ?? false;
    bool isButtonLoading = isLoading ?? false;

    return GestureDetector(
      onTap: isButtonLoading ? null : onPressed,
      child: Container(
        height: 65.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOutlineBtn ? Colors.transparent : Color(0xff1faa00),
          border: Border.all(
            color: Color(0xff1faa00),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 8.0,
        ),
        child: Stack(
          children: [
            Visibility(
              visible: !isButtonLoading,
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isOutlineBtn ? Color(0xff1faa00) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: isButtonLoading,
              child: Center(
                child: SizedBox(
                  height: 30.0,
                  width: 30.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOutlineBtn ? Color(0xff1faa00) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//WHITE - BLUE
class CustomEditBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool outlineBtn;
  final bool isLoading;

  CustomEditBtn({
    required this.text,
    required this.onPressed,
    this.outlineBtn = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isOutlineBtn = outlineBtn ?? false;
    bool isButtonLoading = isLoading ?? false;

    return GestureDetector(
      onTap: isButtonLoading ? null : onPressed,
      child: Container(
        height: 45.0,
        width: 100.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOutlineBtn ? Colors.transparent : Color(0xffD50000),
          border: Border.all(
            color: Color(0xffD50000),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 8.0,
        ),
        child: Stack(
          children: [
            Visibility(
              visible: !isButtonLoading,
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isOutlineBtn ? Color(0xffD50000) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: isButtonLoading,
              child: Center(
                child: SizedBox(
                  height: 20.0,
                  width: 20.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOutlineBtn ? Color(0xffD50000) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
