import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/complaint_entities.dart';

extension ComplaintTypeUi on ComplaintType {
  String get label => switch (this) {
        ComplaintType.aggressiveDriver => 'Conductor agresivo',
        ComplaintType.overcharge => 'Cobro excesivo',
        ComplaintType.routeNotRespected => 'Ruta no respetada',
        ComplaintType.poorVehicleCondition => 'Vehículo en mal estado',
        ComplaintType.harassment => 'Acoso',
        ComplaintType.other => 'Otro',
      };
}

extension ComplaintStatusUi on ComplaintStatus {
  String get label => switch (this) {
        ComplaintStatus.inReview => 'En revisión',
        ComplaintStatus.resolved => 'Resuelto',
        ComplaintStatus.closed => 'Cerrado',
      };

  Color get background => switch (this) {
        ComplaintStatus.inReview => ChasquiColors.warm200,
        ComplaintStatus.resolved => ChasquiColors.successSurface,
        ComplaintStatus.closed => ChasquiColors.neutral100,
      };

  Color get foreground => switch (this) {
        ComplaintStatus.inReview => ChasquiColors.warm800,
        ComplaintStatus.resolved => ChasquiColors.successText,
        ComplaintStatus.closed => ChasquiColors.neutral600,
      };
}
