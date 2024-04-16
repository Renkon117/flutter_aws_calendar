import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_aws_calendar/models/Schedule.dart';
import 'package:flutter_aws_calendar/repository/schedule_repository.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({Key? key}) : super(key: key);

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  TextEditingController titleController = TextEditingController();
  DateTime now = DateTime.now();
  List<String> weekName = ['月', '火', '水', '木', '金', '土', '日'];
  late PageController controller;
  DateTime firstDay = DateTime(2024, 1, 1);
  late DateTime selectedDate;
  late int initialIndex;
  int monthDuration = 0;

  DateTime? selectedStartTime;
  DateTime? selectedEndTime;
  Schedule? updateTargetSchedule;

  late List<int> yearOption;
  late List<int> monthOption = List.generate(12, (index) => index + 1);
  late List<int>? dayOption;

  void buildDayOption(DateTime selectedDate) {
    List<int> _list = [];
    for (int i = 1;
        i <=
            DateTime(selectedDate.year, selectedDate.month + 1, 1)
                .subtract(const Duration(days: 1))
                .day;
        i++) {
      _list.add(i);
    }
    dayOption = _list;
  }

  List<int> hourOption = List.generate(24, (index) => index);
  List<int> minuteOption = List.generate(60, (index) => index);

  bool isSettingStartTime = false;

  Map<DateTime, List<Schedule>> scheduleMap = {};

  void selectDate(DateTime cacheDate) {
    selectedDate = cacheDate;
    setState(() {});
  }

  Future<void> fetchScheduleList() async {
    List<Schedule?> scheduleList = await ScheduleRepository.fetchScheduleList();
    print(scheduleList);

    scheduleMap = {};
    for (var schedule in scheduleList) {
      DateTime startAt = DateTime.parse(schedule!.startAt);
      DateTime checkStartTime =
          DateTime(startAt.year, startAt.month, startAt.day);
      if (scheduleMap.containsKey(checkStartTime)) {
        scheduleMap[checkStartTime]!.add(schedule);
      } else {
        scheduleMap[checkStartTime] = [schedule];
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchScheduleList();

    yearOption = [now.year, now.year + 1];
    selectedDate = now;

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
          Expanded(child: createCalendarItem()),
          Container(
            alignment: Alignment.centerRight,
            height: 50,
            width: double.infinity,
            color: Theme.of(context).primaryColor,
            child: IconButton(
              splashRadius: 25,
              icon: const Icon(Icons.add, color: Colors.white, size: 30),
              onPressed: () async {
                selectedStartTime = selectedDate;
                await showDialog(
                    context: context,
                    builder: (context) {
                      return buildAddScheduleDialog();
                    });
                titleController.clear();
                setState(() {});
              },
            ),
          )
        ],
      ),
    );
  }

  Widget buildAddScheduleDialog({bool isNew = true}) {
    return StatefulBuilder(builder: (context, setState) {
      return SimpleDialog(
        titlePadding: EdgeInsets.zero,
        title: Column(
          children: [
            Row(
              children: [
                IconButton(
                  splashRadius: 10,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel),
                ),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'タイトルを入力'),
                  ),
                ),
                IconButton(
                    onPressed: () async {
                      // スケジュールを追加する処理
                      if (!validationIsOk()) {
                        return;
                      }

                      if (isNew) {
                        Schedule newSchedule = Schedule(
                            title: titleController.text,
                            startAt: DateFormat('yyyy-MM-dd HH:mm')
                                .format(selectedStartTime!),
                            endAt: DateFormat('yyyy-MM-dd HH:mm')
                                .format(selectedEndTime!));

                        await ScheduleRepository.insertSchedule(newSchedule);
                      } else {
                        Schedule updatedSchedule =
                            updateTargetSchedule!.copyWith(
                          title: titleController.text,
                          startAt: DateFormat('yyyy-MM-dd HH:mm')
                              .format(selectedStartTime!),
                          endAt: DateFormat('yyyy-MM-dd HH:mm')
                              .format(selectedEndTime!),
                        );
                        await ScheduleRepository.updateSchedule(
                            updatedSchedule);
                      }

                      fetchScheduleList();

                      selectedEndTime = null;
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.check_circle)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      buildDayOption(selectedDate);
                      isSettingStartTime = true;
                      await showDialog(
                          context: context,
                          builder: (context) {
                            return buildSelectTimeDialog();
                          });
                      setState(() {});
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('yyyy').format(selectedStartTime!)),
                          Text(DateFormat('MM/dd').format(selectedStartTime!)),
                          Text(DateFormat('HH:mm').format(selectedStartTime!))
                        ],
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_right),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      buildDayOption(selectedDate);
                      isSettingStartTime = false;
                      selectedEndTime ??= selectedStartTime;
                      await showDialog(
                          context: context,
                          builder: (context) {
                            return buildSelectTimeDialog();
                          });
                      setState(() {});
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(selectedEndTime == null
                              ? '----'
                              : DateFormat('yyyy').format(selectedEndTime!)),
                          Text(selectedEndTime == null
                              ? '--/--'
                              : DateFormat('MM/dd').format(selectedEndTime!)),
                          Text(selectedEndTime == null
                              ? '--:--'
                              : DateFormat('HH:mm').format(selectedEndTime!))
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    });
  }

  Widget buildSelectTimeDialog() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: StatefulBuilder(builder: (context, setState) {
        return SimpleDialog(
          titlePadding: EdgeInsets.zero,
          title: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    splashRadius: 10,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel),
                  ),
                  const Expanded(
                    child: Text(
                      '日付を選択',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle)),
                ],
              ),
              Container(
                height: 150,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        itemExtent: 35,
                        onSelectedItemChanged: (int index) {
                          if (isSettingStartTime) {
                            selectedStartTime = DateTime(
                                yearOption[index],
                                selectedStartTime!.month,
                                selectedStartTime!.day,
                                selectedStartTime!.hour,
                                selectedStartTime!.minute);
                          } else {
                            selectedEndTime = DateTime(
                                yearOption[index],
                                selectedEndTime!.month,
                                selectedEndTime!.day,
                                selectedEndTime!.hour,
                                selectedEndTime!.minute);
                          }
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: yearOption.indexOf(isSettingStartTime
                              ? selectedStartTime!.year
                              : selectedEndTime!.year),
                        ),
                        children: yearOption
                            .map((e) => Container(
                                  alignment: Alignment.center,
                                  height: 35,
                                  child: Text('$e'),
                                ))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 35,
                        onSelectedItemChanged: (int index) {
                          if (isSettingStartTime) {
                            selectedStartTime = DateTime(
                                selectedStartTime!.year,
                                monthOption[index],
                                selectedStartTime!.day,
                                selectedStartTime!.hour,
                                selectedStartTime!.minute);
                            buildDayOption(selectedStartTime!);
                          } else {
                            selectedEndTime = DateTime(
                                selectedEndTime!.year,
                                monthOption[index],
                                selectedEndTime!.day,
                                selectedEndTime!.hour,
                                selectedEndTime!.minute);
                            buildDayOption(selectedEndTime!);
                          }
                          setState(() {});
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: monthOption.indexOf(isSettingStartTime
                              ? selectedStartTime!.month
                              : selectedEndTime!.month),
                        ),
                        children: monthOption
                            .map((e) => Container(
                                  alignment: Alignment.center,
                                  height: 35,
                                  child: Text('$e'),
                                ))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 35,
                        onSelectedItemChanged: (int index) {
                          if (isSettingStartTime) {
                            selectedStartTime = DateTime(
                                selectedStartTime!.year,
                                selectedStartTime!.month,
                                dayOption![index],
                                selectedStartTime!.hour,
                                selectedStartTime!.minute);
                          } else {
                            selectedEndTime = DateTime(
                                selectedEndTime!.year,
                                selectedEndTime!.month,
                                dayOption![index],
                                selectedEndTime!.hour,
                                selectedEndTime!.minute);
                          }
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: dayOption!.indexOf(isSettingStartTime
                              ? selectedStartTime!.day
                              : selectedEndTime!.day),
                        ),
                        children: dayOption!
                            .map((e) => Container(
                                  alignment: Alignment.center,
                                  height: 35,
                                  child: Text('$e'),
                                ))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 35,
                        onSelectedItemChanged: (int index) {
                          if (isSettingStartTime) {
                            selectedStartTime = DateTime(
                                selectedStartTime!.year,
                                selectedStartTime!.month,
                                selectedStartTime!.day,
                                hourOption[index],
                                selectedStartTime!.minute);
                          } else {
                            selectedEndTime = DateTime(
                                selectedEndTime!.year,
                                selectedEndTime!.month,
                                selectedEndTime!.day,
                                hourOption[index],
                                selectedEndTime!.minute);
                          }
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: hourOption.indexOf(isSettingStartTime
                              ? selectedStartTime!.hour
                              : selectedEndTime!.hour),
                        ),
                        children: hourOption
                            .map((e) => Container(
                                  alignment: Alignment.center,
                                  height: 35,
                                  child: Text('$e'),
                                ))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 35,
                        onSelectedItemChanged: (int index) {
                          if (isSettingStartTime) {
                            selectedStartTime = DateTime(
                                selectedStartTime!.year,
                                selectedStartTime!.month,
                                selectedStartTime!.day,
                                selectedStartTime!.hour,
                                minuteOption[index]);
                          } else {
                            selectedEndTime = DateTime(
                                selectedEndTime!.year,
                                selectedEndTime!.month,
                                selectedEndTime!.day,
                                selectedEndTime!.hour,
                                minuteOption[index]);
                          }
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: minuteOption.indexOf(isSettingStartTime
                              ? selectedStartTime!.minute
                              : selectedEndTime!.minute),
                        ),
                        children: minuteOption
                            .map((e) => Container(
                                  alignment: Alignment.center,
                                  height: 35,
                                  child: Text('$e'),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  bool validationIsOk() {
    if (selectedEndTime == null) {
      print('終了時刻が入力されていません。');
      return false;
    } else if (selectedStartTime!.isAfter(selectedEndTime!)) {
      print('開始日時より終了日時の方が先になっています。');
      return false;
    } else {
      return true;
    }
  }

  Future<void> editSchedule(
      {required int index, required Schedule selectedSchedule}) async {
    updateTargetSchedule = selectedSchedule;
    selectedStartTime = DateTime.parse(selectedSchedule.startAt);
    selectedEndTime = DateTime.parse(selectedSchedule.endAt);

    titleController.text = selectedSchedule.title;
    await showDialog(
        context: context,
        builder: (context) {
          return buildAddScheduleDialog(isNew: false);
        });
  }

  Future<void> deleteSchedule(
      {required int index, required Schedule selectedSchedule}) async {
    await ScheduleRepository.deleteSchedule(selectedSchedule);
    fetchScheduleList();
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
              selectDate: selectDate,
              selectedDate: selectedDate,
              editSchedule: editSchedule,
              deleteSchedule: deleteSchedule,
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
  final DateTime selectedDate;
  final List<Schedule>? scheduleList;
  final Function selectDate;
  final Function editSchedule;
  final Function deleteSchedule;

  const _CalendarItem(
      {required this.day,
      required this.now,
      required this.cacheDate,
      required this.selectedDate,
      this.scheduleList,
      required this.selectDate,
      required this.editSchedule,
      required this.deleteSchedule,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSelected = (selectedDate.difference(cacheDate).inDays == 0) &&
        (selectedDate.day == cacheDate.day);
    bool isToday =
        (now.difference(cacheDate).inDays == 0) && (now.day == cacheDate.day);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          selectDate(cacheDate);
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black.withOpacity(0.2) : null,
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
                          .asMap()
                          .entries
                          .map((e) => GestureDetector(
                                onTap: () {
                                  print('予定がタップ');
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return CupertinoAlertDialog(
                                          title: Text(e.value.title),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: const Text('編集'),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                editSchedule(
                                                    index: e.key,
                                                    selectedSchedule: e.value);
                                              },
                                            ),
                                            CupertinoDialogAction(
                                              isDestructiveAction: true,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                deleteSchedule(
                                                    index: e.key,
                                                    selectedSchedule: e.value);
                                              },
                                              child: const Text('削除'),
                                            ),
                                            CupertinoDialogAction(
                                              child: const Text('キャンセル'),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 20,
                                  alignment: Alignment.centerLeft,
                                  margin: const EdgeInsets.only(
                                      left: 2, right: 2, top: 2),
                                  padding:
                                      const EdgeInsets.only(left: 2, right: 2),
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.8),
                                  child: Text(
                                    e.value.title,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ))
                          .toList(),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
