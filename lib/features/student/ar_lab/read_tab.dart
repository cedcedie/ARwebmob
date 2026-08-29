import 'package:flutter/material.dart';

import 'ar_lab_providers.dart';

class ReadTab extends StatelessWidget {
  const ReadTab({super.key, required this.vm});

  final ArLabViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(vm.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(vm.summary, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        if (!vm.isRead)
          FilledButton(
            onPressed: () async => vm.onMarkAsRead(),
            child: const Text('Mark as Read'),
          )
        else
          const Chip(label: Text('Read'), avatar: Icon(Icons.check)),
      ],
    );
  }
}
