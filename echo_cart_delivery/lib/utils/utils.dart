import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum SnackbarType { success, error }

showAppSnackbar({
  required BuildContext context,
  required SnackbarType type,
  required String description,
}) {
  final backgroundColor = type == SnackbarType.success
      ? Colors.green.withAlpha(220)
      : Colors.red.withAlpha(220);
  final icon = type == SnackbarType.success ? Icons.check_circle : Icons.error;

  final snackBar = SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: backgroundColor,
    content: Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(description, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
    duration: const Duration(milliseconds: 2500),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

Future<String?> openLocationInMaps(LatLng location, String address) async {
  final latitude = location.latitude;
  final longitude = location.longitude;

  final googleMapsUrl = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );
  final fallbackUrl = Uri.parse(
    'geo:$latitude,$longitude?q=${Uri.encodeComponent('$latitude,$longitude($address)')}',
  );

  try {
    final launched = await launchUrl(
      googleMapsUrl,
      mode: LaunchMode.externalApplication,
    );
    if (launched) return null;

    final fallbackLaunched = await launchUrl(
      fallbackUrl,
      mode: LaunchMode.externalApplication,
    );
    if (fallbackLaunched) return null;

    return 'Maps app not available. Please install a maps app to continue.';
  } catch (e) {
    return 'Error opening maps: ${e.toString()}';
  }
}
