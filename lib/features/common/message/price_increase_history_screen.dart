import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import 'controller.dart';
import 'widget/price_increase_request_card.dart';

class PriceIncreaseHistoryScreen extends StatefulWidget {
  const PriceIncreaseHistoryScreen({super.key, required this.billId});
  final int billId;

  @override
  State<PriceIncreaseHistoryScreen> createState() => _PriceIncreaseHistoryScreenState();
}

class _PriceIncreaseHistoryScreenState extends State<PriceIncreaseHistoryScreen> {
  late Future<List<PriceIncreaseRequestModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = Get.find<MessageController>().getPriceIncreaseRequests(billId: widget.billId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch sử yêu cầu tăng giá')),
    backgroundColor: const Color(0xFFF8FAFC),
    body: FutureBuilder<List<PriceIncreaseRequestModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(snapshot.error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => setState(_reload), child: const Text('Thử lại')),
            ]),
          ));
        }
        final requests = snapshot.data ?? const <PriceIncreaseRequestModel>[];
        if (requests.isEmpty) {
          return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history_rounded, size: 52, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text('Chưa có yêu cầu tăng giá', style: TextStyle(color: Color(0xFF64748B))),
          ]));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => PriceIncreaseRequestCard(request: requests[index]),
          ),
        );
      },
    ),
  );
}
