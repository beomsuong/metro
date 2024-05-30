import 'dart:math';

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
                  Wrap(
                    children: [
                      for (var search in searches ?? [])
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 40,
                            width: 60,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 86, 169, 205),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: InkWell(
                              onTap: () async {
                                realtimeArrivalAsyncRead.fetchData(search);
                                await dbHelper.updateSearch(search);
                                searches = await dbHelper.getSearches();
                                setState(() {});
                              },
                              onLongPress: () async {
                                await dbHelper.deleteSearch(search);
                                searches = await dbHelper.getSearches();
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Center(
                                  child: FittedBox(
                                    child: Text(
                                      search,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '지하철명',
                    ),
                    onSubmitted: (value) async {
                      searchText = value;
                      realtimeArrivalAsyncRead.fetchData(value);
                      await dbHelper.insertSearch(value);
                      searches = await dbHelper.getSearches();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      realtimeArrivalAsyncRead.timeStartStop(searchText);
                    },
                    child: CustomPaint(
                      size: const Size(100, 100),
                      painter: CircularTimerPainter(
                          progress: realtimeArrivalAsyncRead.progress),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Expanded(
              child: realtimeArrivalAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const Center(child: Text('데이터 조회 실패')),
                data: (data) => ListView.builder(
                  itemCount: data.realtimeArrivalList?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = data.realtimeArrivalList![index];
                    return InkWell(
                      onTap: () {
                        realtimeArrivalAsyncRead.setBtrainNo(data
                            .realtimeArrivalList![index].btrainNo
                            .toString());
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

class CircularTimerPainter extends CustomPainter {
  CircularTimerPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    final Paint fillPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double radius = min(size.width / 2, size.height / 2) - 10;
    canvas.drawCircle(size.center(Offset.zero), radius, backgroundPaint);
    final double angle = 2 * pi * progress;
    final Rect rect =
        Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
    canvas.drawArc(rect, -pi / 2, angle, false, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
