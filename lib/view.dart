import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controller.dart';
import 'model.dart';

class View1 extends ConsumerWidget {
  final String stationName;

  const View1({super.key, required this.stationName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtimeArrivalAsyncValue = ref.watch(realtimeArrivalProvider);
    final notifier = ref.read(realtimeArrivalProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Realtime Arrival for $stationName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                print('버튼');
                notifier.fetchRealtimeArrival('공덕');
              },
              child: Container(
                height: 30,
                width: 30,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 30),
            realtimeArrivalAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (realtimeArrival) => Expanded(
                child: ListView.builder(
                  itemCount: realtimeArrival.realtimeArrivalList?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = realtimeArrival.realtimeArrivalList![index];
                    return ListTile(
                      title: Text(item.trainLineNm.toString()),
                      subtitle: Text(item.arvlMsg2.toString()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
