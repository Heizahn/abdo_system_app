// lib/components/client_detail/cards/plan_info_card.dart
import 'package:flutter/material.dart';
import '../shared/detail_info_row.dart';
import '../shared/detail_section_card.dart';

class PlanInfoData {
  final String planName;
  final double planPrice;
  final double planMbps;
  final double paymentDay;

  const PlanInfoData({
    required this.planName,
    required this.planPrice,
    required this.planMbps,
    required this.paymentDay,
  });
}

class PlanInfoCard extends StatelessWidget {
  final PlanInfoData data;

  const PlanInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final day = data.paymentDay == 0 ? '—' : 'Día ${data.paymentDay.toInt()}';

    return DetailSectionCard(
      title: 'Plan de Servicio',
      titleIcon: Icons.wifi_rounded,
      children: [
        DetailInfoRow(
          icon: Icons.speed_rounded,
          label: 'Plan contratado',
          value: data.planName,
        ),
        const DetailRowDivider(),
        DetailInfoRow(
          icon: Icons.attach_money_rounded,
          label: 'Precio mensual',
          value: '\$${data.planPrice.toStringAsFixed(2)}',
        ),
        const DetailRowDivider(),
        DetailInfoRow(
          icon: Icons.network_check_rounded,
          label: 'Velocidad',
          value: '${data.planMbps.toInt()} Mbps',
        ),
        const DetailRowDivider(),
        DetailInfoRow(
          icon: Icons.calendar_today_rounded,
          label: 'Día de pago',
          value: day,
        ),
      ],
    );
  }
}
