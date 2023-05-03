import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Location permission'),
      content: const Text(
          'Can we open location settings for full range experience of this application?'),
      actions: [
        TextButton(
          onPressed: () {
            Geolocator.openAppSettings();
          },
          child: const Text('Open settings'),
        ),
      ],
    );
  }
}
