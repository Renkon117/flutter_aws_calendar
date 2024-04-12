import 'package:flutter/material.dart';
import 'package:flutter_aws_calendar/model/schedule.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({Key? key}) : super(key: key);

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime now = DateTime.now();
  List<String> weekName = ['月', '火', '水', '木', '金', '土', '日'];
  late PageController controller;
  DateTime firstDay = DateTime(2024, 1, 1);
  late int initialIndex;
  int monthDuration = 0;

  Map<DateTime, List<Schedule>> scheduleMap = {
    DateTime(2024, 4, 11): [
      Schedule(
        title: '買い出し',
        startAt: DateTime(2024, 4, 11, 10),
        endAt: DateTime(2024, 4, 11, 12),
      ),
      Schedule(
        title: '宿題をする',
        startAt: DateTime(2024, 4, 11, 15),
        endAt: DateTime(2024, 4, 11, 17),
      ),
    ],
    DateTime(2024, 4, 12): [
      Schedule(
        title: '買い出し',
        startAt: DateTime(2024, 4, 12, 10),
        endAt: DateTime(2024, 4, 12, 12),
      ),
    ]
  };

  @override
  void initState() {
    super.initState();

    initialIndex =
        (now.year - firstDay.year) * 12 + (now.month - firstDay.month);
    controller = PageController(initialPage: initialIndex);
    controller.addListener(() {
      monthDuration = (controller.page! - initialIndex).round();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
            DateFormat('yyyy年 M月')
                .format(DateTime(now.year, now.month + monthDuration)),
            style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 30,
            color: Theme.of(context).primaryColor,
            child: Row(
              children: weekName
                  .map((e) => Expanded(
                          child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          e,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )))
                  .toList(),
            ),
          ),
          Expanded(child: createCalendarItem())
        ],
      ),
    );
  }

  Widget createCalendarItem() {
    return PageView.builder(
        controller: controller,
        itemBuilder: (context, index) {
          List<Widget> _list = [];
          List<Widget> _listCache = [];

          DateTime date =
              DateTime(now.year, now.month + index - initialIndex, 1);
          int monthLastDay = DateTime(date.year, date.month + 1, 1)
              .subtract(const Duration(days: 1))
              .day;

          for (int i = 0; i < monthLastDay; i++) {
            _listCache.add(_CalendarItem(
              day: i + 1,
              now: now,
              cacheDate: DateTime(date.year, date.month, i + 1),
              scheduleList: scheduleMap[DateTime(date.year, date.month, i + 1)],
            ));
            int repeatNumber = 7 - _listCache.length;
            if (date.add(Duration(days: i)).weekday == 7) {
              if (i < 7) {
                _listCache.insertAll(
                  0,
                  List.generate(
                    repeatNumber,
                    (index) => Expanded(
                      child: Container(color: Colors.black.withOpacity(0.1)),
                    ),
                  ),
                );
              }

              _list.add(Row(children: _listCache));
              _listCache = [];
            } else if (i == monthLastDay - 1) {
              _listCache.addAll(
                List.generate(
                  repeatNumber,
                  (index) => Expanded(
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
              );
              _list.add(Row(
                children: _listCache,
              ));
            }
          }

          return Column(
            children: _list,
          );
        });
  }
}

class _CalendarItem extends StatelessWidget {
  final int day;
  final DateTime now;
  final DateTime cacheDate;
  final List<Schedule>? scheduleList;

  const _CalendarItem(
      {required this.day,
      required this.now,
      required this.cacheDate,
      this.scheduleList,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isToday =
        (now.difference(cacheDate).inDays == 0) && (now.day == cacheDate.day);
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              color: isToday
                  ? Theme.of(context).primaryColor.withOpacity(0.8)
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(color: isToday ? Colors.white : null),
              ),
            ),
            scheduleList == null
                ? Container()
                : Column(
                    children: scheduleList!
                        .map((e) => Container(
                              width: double.infinity,
                              height: 20,
                              alignment: Alignment.centerLeft,
                              margin: const EdgeInsets.only(left: 2, right: 2, top: 2),
                              padding: const EdgeInsets.only(left: 2, right: 2),
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.8),
                              child: Text(
                                e.title,
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                  )
          ],
        ),
      ),
    );
  }
}
