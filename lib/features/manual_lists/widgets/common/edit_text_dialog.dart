import 'package:flutter/material.dart';

Future<String?> showEditTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
  int maxLines = 1,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _EditTextDialogBody(
      title: title,
      label: label,
      initialValue: initialValue,
      maxLines: maxLines,
    ),
  );
}

class _EditTextDialogBody extends StatefulWidget {
  const _EditTextDialogBody({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.maxLines,
  });

  final String title;
  final String label;
  final String initialValue;
  final int maxLines;

  @override
  State<_EditTextDialogBody> createState() => _EditTextDialogBodyState();
}

class _EditTextDialogBodyState extends State<_EditTextDialogBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _controller.text.trim());
          },
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
