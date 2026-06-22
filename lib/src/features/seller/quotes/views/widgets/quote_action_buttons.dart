import 'package:flutter/material.dart';
import 'package:gta_app/src/models/quotation_model.dart';

class QuoteActionButtons extends StatelessWidget {
  final Quotation quote;
  final VoidCallback onCancel;
  final VoidCallback onFinalize;

  const QuoteActionButtons({
    super.key,
    required this.quote,
    required this.onCancel,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onFinalize,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('Finalize'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              shadowColor: Theme.of(context).primaryColor.withAlpha(100),
            ),
          ),
        ),
      ],
    );
  }
}
