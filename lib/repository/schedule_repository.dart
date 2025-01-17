import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:intl/intl.dart';

import '../models/Schedule.dart';

class ScheduleRepository {
  static Future<void> insertSchedule(Schedule newSchedule) async {
    try {
      final request = ModelMutations.create(newSchedule);
      final response = await Amplify.API.mutate(request: request).response;

      final createdSchedule = response.data;
      if (createdSchedule == null) {
        print('スケジュール作成失敗');
        return;
      }
      print('Mutation result: ${createdSchedule.title}');
    } on ApiException catch (e) {
      print('Mutation failed: $e');
    }
  }

  static Future<List<Schedule?>> fetchScheduleList() async {
    try {
      final request = ModelQueries.list(Schedule.classType);
      final response = await Amplify.API.mutate(request: request).response;

      final schedules = response.data?.items;
      if (schedules == null) {
        print('errors: ${response.errors}');
        return <Schedule?>[];
      }
      return schedules;
    } on ApiException catch (e) {
      print('Query failed: $e');
    }
    return <Schedule?>[];
  }

  static Future<void> updateSchedule(Schedule updatedSchedule) async {
    final request = ModelMutations.update(updatedSchedule);
    final response = await Amplify.API.mutate(request: request).response;
    safePrint('Response: $response');
  }

  static Future<void> deleteSchedule(Schedule scheduleToDelete) async {
    final request = ModelMutations.delete(scheduleToDelete);
    final response = await Amplify.API.mutate(request: request).response;
    safePrint('Response: $response');
  }
}
