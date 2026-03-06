// lib/components/client_detail/cards/personal_info_card.dart
import 'package:flutter/material.dart';
import '../shared/detail_info_row.dart';
import '../shared/detail_section_card.dart';

class PersonalInfoData {
  final String dni;
  final String phone;
  final String? email;
  final String sectorName;
  final String address;
  final String? commentary;

  const PersonalInfoData({
    required this.dni,
    required this.phone,
    this.email,
    required this.sectorName,
    required this.address,
    this.commentary,
  });
}

class PersonalInfoCard extends StatelessWidget {
  final PersonalInfoData data;

  const PersonalInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: 'Información Personal',
      titleIcon: Icons.person_outline_rounded,
      children: [
        DetailInfoRow(
          icon: Icons.badge_rounded,
          label: 'Cédula / RIF',
          value: data.dni,
          copyable: true,
        ),
        const DetailRowDivider(),
        DetailInfoRow(
          icon: Icons.phone_rounded,
          label: 'Teléfono',
          value: data.phone,
          copyable: true,
        ),
        if (data.email != null && data.email!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.email_rounded,
            label: 'Correo',
            value: data.email!,
            copyable: true,
          ),
        ],
        const DetailRowDivider(),
        DetailInfoRow(
          icon: Icons.location_on_rounded,
          label: 'Sector',
          value: data.sectorName,
        ),
        const DetailRowDivider(),
        DetailInfoRow(
          icon: Icons.home_rounded,
          label: 'Dirección',
          value: data.address,
        ),
        if (data.commentary != null && data.commentary!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.notes_rounded,
            label: 'Nota',
            value: data.commentary!,
          ),
        ],
      ],
    );
  }
}
