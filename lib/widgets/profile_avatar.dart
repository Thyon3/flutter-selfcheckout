import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final String? name;
  final Color? backgroundColor;

  Avatar({
    this.radius = 30.0,
    this.imageUrl,
    this.name,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null && name != null
          ? Text(
              _getInitials(name!),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : imageUrl == null
              ? Icon(
                  Icons.person,
                  size: radius * 1.2,
                  color: Colors.grey[600],
                )
              : null,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
    }
  }
}
