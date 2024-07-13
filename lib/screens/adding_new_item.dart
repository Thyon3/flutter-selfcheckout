import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/widgets/custom_button.dart';
import 'package:selfcheckoutapp/widgets/custom_input.dart';

class NewItemView extends StatefulWidget {
  final Function(String) onItemAdded;
  final String? initialText;

  NewItemView({
    required this.onItemAdded,
    this.initialText,
  });

  @override
  _NewItemViewState createState() => _NewItemViewState();
}

class _NewItemViewState extends State<NewItemView> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
  }

  Future<void> _addItem() async {
    final text = _textController.text.trim();
    
    if (text.isEmpty) {
      _showErrorDialog('Please enter an item');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate API call delay
      await Future.delayed(Duration(milliseconds: 500));
      
      widget.onItemAdded(text);
      Navigator.pop(context);
    } catch (e) {
      _showErrorDialog('Failed to add item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text(
          widget.initialText != null ? 'Edit Item' : 'Add New Item',
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
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40.0),
            Text(
              widget.initialText != null 
                  ? 'Edit your shopping item'
                  : 'Add a new item to your shopping list',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.0),
            CustomInput(
              hintText: 'Enter item name',
              textEditingController: _textController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addItem(),
            ),
            SizedBox(height: 20.0),
            Text(
              'Tips:',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Color(0xff1faa00),
              ),
            ),
            SizedBox(height: 8.0),
            ...[
              _buildTip('• Be specific (e.g., "2% milk" instead of "milk")'),
              _buildTip('• Add quantities (e.g., "3 cans tomatoes")'),
              _buildTip('• Include brand preferences if important'),
            ],
            Spacer(),
            CustomBtn(
              text: widget.initialText != null ? 'Update Item' : 'Add Item',
              onPressed: _addItem,
              isLoading: _isLoading,
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  void saveData() {
    if (textFieldController.text.isNotEmpty) {
      setState(() {
        Navigator.of(context).pop(textFieldController.text);
      });
    }
  }
}
