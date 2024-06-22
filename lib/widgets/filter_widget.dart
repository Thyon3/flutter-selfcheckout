import 'package:flutter/material.dart';

class FilterWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const FilterWidget({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: selectedFilter,
        hint: Text('Filter by category'),
        isExpanded: true,
        items: ['All', 'Electronics', 'Food', 'Clothing'],
        onChanged: onFilterChanged,
      ),
    );
  }
}
