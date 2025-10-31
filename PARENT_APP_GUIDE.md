# Edcona Parent Mobile App - User Guide

## Overview
The Edcona Parent Mobile App provides a clean, Apple-like interface for parents to monitor their children's academic progress and communicate with teachers.

## Features

### 1. **Child Selection Screen**
- Beautiful welcome screen with gradient cards
- Easy selection of multiple children
- Quick access to each student's information

### 2. **Dashboard Section**
- **Quick Stats**: Average grade and attendance rate at a glance
- **Recent Grades**: View the latest 3 exam results
- **Pending Homework**: See upcoming assignments
- **Latest Announcements**: Stay updated with school news

### 3. **Performance Section**
- **Overall Average**: Large display of student's average grade
- **Detailed Grade List**: All exams with:
  - Grade letter (A, B, C, D, F)
  - Score and percentage
  - Subject and assignment name
  - Visual progress bar
  - Date and exam type

### 4. **Homework Section**
- **Status Cards**: Quick view of pending, submitted, overdue, and total homework
- **Filter Options**: Filter by all, pending, submitted, or overdue
- **Detailed Cards**: Each homework shows:
  - Title and subject
  - Due date and submission date
  - Status badge with color coding
  - Description preview

### 5. **Announcements Section**
- **Priority Levels**: Urgent, Important, and Normal announcements
- **Visual Indicators**: Color-coded badges and icons
- **Full Content**: Read complete announcement messages
- **Date Stamps**: See when announcements were posted

### 6. **Messages Section**
- **Teacher List**: View all teachers
- **Quick Messaging**: Tap to send a message to any teacher
- **Simple Interface**: Easy-to-use message dialog

### 7. **Profile Section**
- **Avatar Selection**: Choose from 24 cool robot-like emojis
- **Student Info Display**: View student ID, name, grade, and role
- **Personalization**: Each student can have their own unique avatar
- **Persistent Storage**: Avatar choice is saved locally

## Design Philosophy

### Apple-Like Design
- **Clean Interface**: Minimal clutter, maximum clarity
- **Smooth Animations**: Subtle transitions and interactions
- **Consistent Colors**: iOS-inspired color palette
  - Blue (#007AFF) for primary actions
  - Green (#34C759) for success/positive
  - Orange (#FF9500) for warnings
  - Red (#FF3B30) for urgent/negative
- **Card-Based Layout**: Information organized in clean white cards
- **Rounded Corners**: 16px border radius for modern look
- **Subtle Shadows**: Soft drop shadows for depth

### User Experience
- **Simple Navigation**: Bottom navigation bar with 6 clear sections
- **Pull to Refresh**: Refresh data by pulling down on any section
- **Empty States**: Friendly messages when no data is available
- **Loading States**: Smooth loading indicators
- **Error Handling**: Clear error messages with retry options

## Technical Structure

```
lib/screens/parent/
├── child_selection_screen.dart    # Initial screen to select child
├── parent_dashboard.dart           # Main dashboard with navigation
└── sections/
    ├── dashboard_section.dart      # Overview with quick stats
    ├── performance_section.dart    # Grades and academic performance
    ├── homework_section.dart       # Homework tracking
    ├── announcements_section.dart  # School announcements
    ├── messages_section.dart       # Teacher communication
    └── profile_section.dart        # Student profile and avatar
```

## API Integration

The app connects to your Railway backend at:
- **Grades**: `/api/grades/student/:studentId`
- **Homework**: `/api/homework/student/:studentId`
- **Attendance**: `/api/attendance/student/:studentId`
- **Announcements**: `/api/announcements`
- **Teachers**: `/api/users/teachers`

## Data Flow

1. Parent logs in with their code
2. System fetches parent's children from `/api/auth/user/:parentId`
3. Parent selects a child
4. App loads all data for that specific child
5. Each section independently fetches and displays relevant data
6. Avatar selection is stored locally per student

## Benefits

### For Parents
- ✅ Monitor multiple children from one account
- ✅ Quick overview of academic performance
- ✅ Track homework completion
- ✅ Stay informed with announcements
- ✅ Easy communication with teachers
- ✅ Personalize experience with avatars

### For Development
- ✅ Simple, maintainable code structure
- ✅ Reusable components
- ✅ Clear separation of concerns
- ✅ Easy to extend with new features
- ✅ Minimal complexity to reduce errors

## Future Enhancements

Potential features to add:
- Push notifications for new announcements
- Calendar view for homework due dates
- Grade trend charts
- Attendance calendar
- File attachments in messages
- Multi-language support expansion
- Dark mode support
