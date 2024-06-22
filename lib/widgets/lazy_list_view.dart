import 'package:flutter/material.dart';

class LazyListView extends StatefulWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final int initialBatchSize;
  final int batchSize;

  const LazyListView({
    Key? key,
    required this.children,
    this.controller,
    this.initialBatchSize = 10,
    this.batchSize = 10,
  }) : super(key: key);

  @override
  _LazyListViewState createState() => _LazyListViewState();
}

class _LazyListViewState extends State<LazyListView> {
  int _displayedItemCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayedItemCount = widget.initialBatchSize;
    widget.controller?.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (widget.controller == null) return;
    
    if (widget.controller!.position.pixels >= 
        widget.controller!.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoading || _displayedItemCount >= widget.children.length) return;
    
    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _displayedItemCount = (_displayedItemCount + widget.batchSize)
            .clamp(0, widget.children.length);
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      itemCount: _displayedItemCount < widget.children.length 
          ? _displayedItemCount + 1 
          : _displayedItemCount,
      itemBuilder: (context, index) {
        if (index == _displayedItemCount && _displayedItemCount < widget.children.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (index < _displayedItemCount) {
          return widget.children[index];
        }
        
        return SizedBox.shrink();
      },
    );
  }
}
