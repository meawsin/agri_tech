// lib/features/retailer/widgets/rating_dialog.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingDialog extends StatefulWidget {
  final String orderId;
  final String farmerId;

  const RatingDialog({super.key, required this.orderId, required this.farmerId});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 3.0;
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate this Farmer'),
      content: RatingBar.builder(
        initialRating: _rating,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: true,
        itemCount: 5,
        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: Colors.amber,
        ),
        onRatingUpdate: (rating) {
          setState(() {
            _rating = rating;
          });
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Submit'),
          onPressed: () async {
            // Store navigator and messenger before the async call
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            await _dbService.submitFarmerRating(
              farmerId: widget.farmerId,
              rating: _rating,
            );

            if (!mounted) return;

            navigator.pop();
            messenger.showSnackBar(
              const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: Colors.green),
            );
          },
        ),
      ],
    );
  }
}