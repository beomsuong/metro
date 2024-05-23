import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metro/sqlite.dart';
import 'controller.dart';
import 'model.dart';

class View1 extends ConsumerStatefulWidget {
  const View1({super.key});

  @override
  _View1State createState() => _View1State();
}

class _View1State extends ConsumerState<View1> {
  final DBHelper dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var data = await dbHelper.getClosestSearch();
      print(data);
      ref
          .read(realtimeArrivalProvider.notifier)
          .fetchRealtimeArrival(data.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final realtimeArrivalAsyncValue = ref.watch(realtimeArrivalProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('실시간 도착 알리미 '),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: '지하철명',
              ),
              onSubmitted: (value) async {
                ref
                    .read(realtimeArrivalProvider.notifier)
                    .fetchRealtimeArrival(value);
                await dbHelper.insertSearch(value);
              },
            ),
            const SizedBox(height: 30),
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
