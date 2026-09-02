import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/booking/controller.dart';
import 'stage_1/booking_stage_time.dart';
import 'stage_2/booking_stage_event.dart';
import 'stage_3/booking_stage_accessories.dart';
import 'stage_3/booking_stage_location.dart';

class BookingStageContent extends GetView<ClientBookingController> {
  const BookingStageContent({super.key, required this.stage});

  final int stage;

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case 0:
        return const BookingTimeStage();
      case 1:
        return const BookingEventStage();
      case 2:
        return const BookingAccessoriesStage();
      case 3:
        return const BookingLocationStage();
      default:
        return const BookingTimeStage();
    }
  }
}
