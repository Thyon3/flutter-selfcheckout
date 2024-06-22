import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? leading;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingsTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: leading != null ? Icon(leading) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class SwitchSettingsTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? leading;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchSettingsTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  _SwitchSettingsTileState createState() => _SwitchSettingsTileState();
}

class _SwitchSettingsTileState extends State<SwitchSettingsTile> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      trailing: Switch(
        value: _value,
        onChanged: (value) {
          setState(() {
            _value = value;
            widget.onChanged(value);
          });
        },
      ),
    );
  }
}
