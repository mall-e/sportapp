import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin/coachs_list_page.dart';
import 'package:sportapp/admin_login_page.dart';
import 'package:sportapp/admin/admin_menu.dart';
import 'package:sportapp/attendant_menu.dart';
import 'package:sportapp/coach_students_page.dart';
import 'package:sportapp/coachs_program_page.dart';
import 'package:sportapp/course_schedule_page.dart';
import 'package:sportapp/main.dart';
import 'package:sportapp/models/student_model.dart';
import 'package:sportapp/month_page.dart';
import 'package:sportapp/months.dart';
import 'package:sportapp/roll_call_page.dart';
import 'package:sportapp/settings_page.dart';
import 'package:sportapp/student_info_page.dart';
import 'package:sportapp/student_list_page.dart';

class AppRoutes {
  static const String authCheck = '/';
  static const String login = '/login';
  static const String adminMenu = '/admin-menu';
  static const String attendantMenu = '/attendant-menu';
  static const String rollCallPage = '/roll-call-page';
  static const String addStudent = '/add-student';
  static const String coachsStudentsPage = '/coachs-students-page';
  static const String coachsProgramsPage = '/coachs-programs-page';
  static const String courseSchedulePage = '/course-schedule-page';
  static const String monthPage = '/month-page';
  static const String months = '/months';
  static const String settingsPage = '/settings-page';
  static const String studentInfoPage = '/student-info-page';
  static const String studentListPage = '/student-list-page';
  static const String coachListPage = '/coach-list-page';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authCheck:
        return MaterialPageRoute(builder: (_) => AuthCheck());
      case login:
        return MaterialPageRoute(builder: (_) => AdminLoginPage());
      case adminMenu:
        return MaterialPageRoute(builder: (_) => AdminMenu());
      case attendantMenu:
        return MaterialPageRoute(builder: (_) => AttendantMenu());
      case addStudent:
        return MaterialPageRoute(builder: (_) => AddStudentPage());
      case coachsStudentsPage:
        final args = settings.arguments as Map<String, dynamic>?;
        final coachId = args?['coachId'] as String;
        final coachName = args?['coachName'] as String;
        return MaterialPageRoute(
          builder: (_) => CoachStudentsPage(
            coachId: coachId,
            coachName: coachName,
          ),
        );
      case coachsProgramsPage:
        return MaterialPageRoute(builder: (_) => CoachsProgramPage());
      case monthPage:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MonthPage(
            monthName: args?['monthName'],
            daysInMonth: args?['daysInMonth'],
            selectedMonth: args?['selectedMonth'],
          ),
        );
      case rollCallPage:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RollCallPage(
            selectedDate: args?['selectedDate'],
          ),
        );
      case months:
        return MaterialPageRoute(builder: (_) => Months());
      case settingsPage:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case studentInfoPage:
        final args = settings.arguments as Map<String, dynamic>?;
        final Student student = args?['student'];
        return MaterialPageRoute(
          builder: (_) => StudentInfoPage(student: student),
        );
      case courseSchedulePage:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CourseSchedulePage(
            studentName: args?['studentName'],
            availableBranches:
                List<String>.from(args?['availableBranches'] ?? []),
            studentId: args?['studentId'],
          ),
        ); // Veri ile
      // case coachListPage:
      //   return MaterialPageRoute(builder: (_) => const CoachListPage());
      case studentListPage:
        final args = settings.arguments as Map<String, dynamic>?;
        final coachId = args?['coachId'] as String?;
        return MaterialPageRoute(
          builder: (_) => StudentListPage(coachId: coachId),
        );
      default:
        return MaterialPageRoute(
            builder: (_) => AdminLoginPage()); // Default route
    }
  }
}
