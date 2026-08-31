import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shared add/remove string-row editor used by lesson steps and quiz options.
class DynamicStringListField extends StatefulWidget {
  const DynamicStringListField({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.itemLabelBuilder,
    this.minItems = 0,
    this.addLabel = 'Add row',
    this.fieldKeyPrefix,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String Function(int index)? itemLabelBuilder;
  final int minItems;
  final String addLabel;
  final String? fieldKeyPrefix;

  @override
  State<DynamicStringListField> createState() => _DynamicStringListFieldState();
}

class _DynamicStringListFieldState extends State<DynamicStringListField> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _buildControllers(widget.values);
  }

  @override
  void didUpdateWidget(covariant DynamicStringListField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values.length != widget.values.length) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers = _buildControllers(widget.values);
      return;
    }

    for (var i = 0; i < widget.values.length; i++) {
      if (_controllers[i].text != widget.values[i]) {
        _controllers[i].text = widget.values[i];
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> _buildControllers(List<String> values) {
    return values.map((value) => TextEditingController(text: value)).toList();
  }

  void _notifyChanged() {
    widget.onChanged(_controllers.map((controller) => controller.text).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (var i = 0; i < _controllers.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: widget.fieldKeyPrefix == null
                      ? ValueKey('${widget.label}-$i')
                      : Key('${widget.fieldKeyPrefix}-$i'),
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: widget.itemLabelBuilder?.call(i) ?? 'Item ${i + 1}',
                  ),
                  onChanged: (_) => _notifyChanged(),
                ),
              ),
              Tooltip(
                message: 'Remove',
                child: ShadIconButton.ghost(
                  onPressed: _controllers.length <= widget.minItems
                      ? null
                      : () {
                          final next = [...widget.values]..removeAt(i);
                          widget.onChanged(next.isEmpty && widget.minItems == 0 ? [''] : next);
                        },
                  icon: const Icon(LucideIcons.trash2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.ghost(
            onPressed: () => widget.onChanged([...widget.values, '']),
            leading: const Icon(LucideIcons.plus, size: 16),
            child: Text(widget.addLabel),
          ),
        ),
      ],
    );
  }
}
