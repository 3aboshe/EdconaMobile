import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

/// Centralized date formatting utility for multilingual, human-readable dates
/// 
/// Features:
/// - Relative dates (Today, Yesterday, Tomorrow)
/// - Locale-aware formatting with day names
/// - RTL support for Arabic, Kurdish, etc.
class DateFormatter {
  
  /// Format a date into a readable, locale-aware string
  /// 
  /// Examples:
  /// - English: "Monday, January 5" or "Today"
  /// - Arabic: "الاثنين، 5 يناير" or "اليوم"
  /// - Kurdish: "دووشەممە 5 کانونی دووەم" or "ئەمڕو"
  static String formatReadableDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final locale = context.locale.toString();
    
    // Normalize dates to midnight for accurate day comparison
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;
    
    // Relative date handling
    if (difference == 0) {
      return 'common.today'.tr();
    } else if (difference == -1) {
      return 'common.yesterday'.tr();
    } else if (difference == 1) {
      return 'common.tomorrow'.tr();
    } else if (difference > -7 && difference < 7) {
      // Within a week - show day name with abbreviated date
      // Format: "Mon, Jan 5" (en) or "الاثنين 5 يناير" (ar)
      return DateFormat.EEEE(locale).format(date);
    } else {
      // Full date for older/future dates
      // Format: "January 5, 2025" (en) or "5 يناير 2025" (ar)
      return DateFormat.yMMMd(locale).format(date);
    }
  }
  
  /// Format a date with time included
  /// 
  /// Example: "Monday, January 5 at 2:30 PM"
  static String formatReadableDateTime(DateTime dateTime, BuildContext context) {
    final locale = context.locale.toString();
    final datePart = formatReadableDate(dateTime, context);
    final timePart = DateFormat.jm(locale).format(dateTime);
    
    return '$datePart ${'common.at'.tr()} $timePart';
  }
  
  /// Format due date with relative language
  /// 
  /// Examples:
  /// - "Due today"
  /// - "Due in 3 days"
  /// - "Due Friday, January 10"
  static String formatDueDate(DateTime dueDate, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = targetDate.difference(today).inDays;
    
    if (difference == 0) {
      return 'parent.due_today'.tr();
    } else if (difference < 0) {
      // Overdue
      final daysLate = difference.abs();
      return 'parent.overdue_by_days'.tr(namedArgs: {'days': daysLate.toString()});
    } else if (difference == 1) {
      return 'parent.due_tomorrow'.tr();
    } else if (difference <= 7) {
      // Due within a week - show day name
      final locale = context.locale.toString();
      final dayName = DateFormat.EEEE(locale).format(dueDate);
      return 'parent.due_day'.tr(namedArgs: {'day': dayName});
    } else {
      // More than a week away - full date
      final locale = context.locale.toString();
      final dateStr = DateFormat.yMMMd(locale).format(dueDate);
      return 'parent.due_date'.tr(namedArgs: {'date': dateStr});
    }
  }
  
  /// Short date format for lists and cards
  /// 
  /// Examples: "Jan 5", "5 يناير"
  static String formatShortDate(DateTime date, BuildContext context) {
    final locale = context.locale.toString();
    return DateFormat.yMd(locale).format(date);
  }
  
  /// Format date range (e.g., for homework assignment periods)
  /// 
  /// Example: "Jan 5 - Jan 10, 2025"
  static String formatDateRange(DateTime start, DateTime end, BuildContext context) {
    final locale = context.locale.toString();
    
    if (start.year == end.year && start.month == end.month) {
      // Same month: "Jan 5 - 10, 2025"
      return '${DateFormat.MMMd(locale).format(start)} - ${DateFormat.d(locale).format(end)}, ${start.year}';
    } else if (start.year == end.year) {
      // Same year: "Jan 5 - Feb 10, 2025"
      return '${DateFormat.MMMd(locale).format(start)} - ${DateFormat.MMMd(locale).format(end)}, ${start.year}';
    } else {
      // Different years: "Jan 5, 2024 - Feb 10, 2025"
      return '${DateFormat.yMMMd(locale).format(start)} - ${DateFormat.yMMMd(locale).format(end)}';
    }
  }
  
  /// Check if a date is overdue
  static bool isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }
  
  /// Get days until due (negative if overdue)
  static int getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return targetDate.difference(today).inDays;
  }
}
