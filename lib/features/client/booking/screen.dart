import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/common/language_switch/language_switch.dart';
import 'controller.dart';
import 'widgets/booking_form.dart';

class ClientBooking extends GetView<ClientBookingController> {
  const ClientBooking({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        prefixes: [FHeaderAction.back(onPress: controller.goBackOneStep)],
        title: Text('booking_title'.tr),
        suffixes: [LanguageSwitch()],
      ),
      child: const BookingForm(),
    );
  }
}
