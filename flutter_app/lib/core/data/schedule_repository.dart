import '../../models/schedule_models.dart';

abstract class ScheduleRepository {
  Future<SemesterSchedule?> loadLocal();
  Future<void> saveLocal(SemesterSchedule schedule);
  Future<SemesterSchedule?> pullRemote(String userId);
  Future<void> pushRemote(String userId, SemesterSchedule schedule);
}
