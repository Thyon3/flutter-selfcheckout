import 'package:flutter/material.dart';

enum SortOption { priceLowToHigh, priceHighToLow, nameAZ, nameZA, newestFirst }

class SortWidget extends StatelessWidget {
  final SortOption selectedSort;
  final Function(SortOption) onSortChanged;

  const SortWidget({
    Key? key,
    required this.selectedSort,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: DropdownButton<SortOption>(
        value: selectedSort,
        hint: Text('Sort by'),
        isExpanded: true,
        items: SortOption.values,
        onChanged: (SortOption? value) {
          if (value != null) onSortChanged(value!);
        },
      ),
    );
  }
}
