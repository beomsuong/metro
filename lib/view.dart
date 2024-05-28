import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metro/model.dart';
import 'controller.dart';
import 'sqlite.dart';

class View1 extends ConsumerStatefulWidget {
  const View1({super.key});

  @override
  _View1State createState() => _View1State();
}

class _View1State extends ConsumerState<View1> {
  final DBHelper dbHelper = DBHelper();
  List<String>? searches;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var data = await dbHelper.getClosestSearch();
      if (data != null) {
        ref.read(realtimeArrivalNotifierProvider.notifier).fetchData(data);
        ref.read(realtimeArrivalNotifierProvider.notifier).timeStartStop(data);
      }
      searches = await dbHelper.getSearches();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final realtimeArrivalAsyncValue =
        ref.watch(realtimeArrivalNotifierProvider);

    final realtimeArrivalAsyncRead =
        ref.read(realtimeArrivalNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('실시간 도착 알리미 '),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Text(searches?.join(', ') ?? 'Loading...'),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '지하철명',
                    ),
                    onSubmitted: (value) async {
                      searchText = value;
                      ref
                          .read(realtimeArrivalNotifierProvider.notifier)
                          .fetchData(value);
                      await dbHelper.insertSearch(value);
                      searches = await dbHelper.getSearches();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(realtimeArrivalNotifierProvider.notifier)
                          .timeStartStop(searchText);
                    },
                    child: const Icon(Icons.timer_rounded),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Expanded(
              child: realtimeArrivalAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (realtimeArrival) => ListView.builder(
                  itemCount: realtimeArrival.realtimeArrivalList?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = realtimeArrival.realtimeArrivalList![index];
                    return InkWell(
                      onTap: () {
                        realtimeArrivalAsyncRead.setBtrainNo(realtimeArrival
                            .realtimeArrivalList![index].btrainNo
                            .toString());
                        setState(() {});
                      },
                      child: Container(
                        color: item.btrainNo.toString() ==
                                realtimeArrivalAsyncRead.selectedBtrainNo
                            ? Colors.amber
                            : Colors.white,
                        child: ListTile(
                          title: Text(item.trainLineNm.toString()),
                          subtitle: Text(
                              '${item.arvlMsg2.toString()} /${(int.parse(item.barvlDt.toString()) / 60).toString().split('.')[0]}분'),
                        ),
                      ),
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
