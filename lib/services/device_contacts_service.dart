import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';

class DevicePhoneContact {
  final String name;
  final String phone;

  const DevicePhoneContact({required this.name, required this.phone});
}

class DeviceContactsService {
  Future<List<DevicePhoneContact>> loadPhoneContacts() async {
    if (kIsWeb) return const [];

    final status = await FlutterContacts.permissions.request(PermissionType.read);
    final granted = status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
    if (!granted) {
      throw Exception('Contacts permission denied.');
    }

    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone},
    );
    final out = <DevicePhoneContact>[];
    final seen = <String>{};

    for (final c in contacts) {
      final displayName = (c.displayName ?? '').trim();
      for (final p in c.phones) {
        final normalized = _normalizePhone(p.number);
        if (normalized.isEmpty || seen.contains(normalized)) continue;
        seen.add(normalized);
        out.add(
          DevicePhoneContact(
            name: displayName.isNotEmpty ? displayName : normalized,
            phone: normalized,
          ),
        );
      }
    }

    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  String _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) {
      return '+${digits.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    return digits.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
