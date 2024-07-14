import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/models/todo.dart';

class ListCheckbox extends StatefulWidget {
  final ToDo todo;
  final Function(bool) onCheckboxChanged;
  final Function(ToDo) onTodoChanged;

  ListCheckbox({
    required this.todo,
    required this.onCheckboxChanged,
    required this.onTodoChanged,
  });

  @override
  _ListCheckboxState createState() => _ListCheckboxState();
}

class _ListCheckboxState extends State<ListCheckbox> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.todo.complete;
  }

  void _onChanged(bool? value) {
    setState(() {
      _isChecked = value ?? false;
    });
    
    final updatedTodo = widget.todo.toggleComplete();
    widget.onTodoChanged(updatedTodo);
    widget.onCheckboxChanged(_isChecked);
  }

  void _startEdit() {
    // This would open an edit dialog or navigate to edit screen
    print('Edit todo: ${widget.todo.title}');
  }

  void _deleteTodo() {
    // This would show a confirmation dialog and delete the todo
    print('Delete todo: ${widget.todo.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            Checkbox(
              value: _isChecked,
              onChanged: _onChanged,
              activeColor: Color(0xff1faa00),
              checkColor: Colors.white,
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: GestureDetector(
                onTap: _startEdit,
                child: Text(
                  widget.todo.title,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: _isChecked ? Colors.grey : Colors.black87,
                    decoration: _isChecked 
                        ? TextDecoration.lineThrough 
                        : TextDecoration.none,
                    decorationColor: _isChecked ? Colors.grey : Colors.transparent,
                    decorationThickness: 2.0,
                  ),
                ),
              ),
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _startEdit();
                } else if (value == 'delete') {
                  _deleteTodo();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
