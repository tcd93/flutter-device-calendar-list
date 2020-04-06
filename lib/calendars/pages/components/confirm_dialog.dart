import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A dialog with Yes/No buttons
class ConfirmDialog extends StatelessWidget {
  final String message;

  const ConfirmDialog({String message, Key key}) : this.message = message, super(key: key);

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: Text(message),
      actions: [
        FlatButton(
          // use `pop` to turn the AlertDialog off
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        FlatButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
          },
          child: Text('Ok'),
        ),
      ],
    );
}
