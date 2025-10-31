# Edcona Parent App - Visual Structure

## 📱 Screen Flow

```
┌─────────────────────────────────────┐
│         LOGIN SCREEN                │
│  (Enter parent code)                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│    CHILD SELECTION SCREEN           │
│  ┌───────────────────────────────┐  │
│  │  Welcome Card (Gradient)      │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  👤 Student 1 → Tap to view   │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  👤 Student 2 → Tap to view   │  │
│  └───────────────────────────────┘  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      PARENT DASHBOARD               │
│  ┌─────────────────────────────┐   │
│  │  Student Name | Section     │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Selected Section Content]         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Bottom Navigation (6 tabs) │   │
│  │  📊 🎯 📝 📢 💬 👤         │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## 🎯 Bottom Navigation Sections

```
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│Dashboard │Performance│ Homework │Announce- │ Messages │ Profile  │
│    📊    │    🎯    │    📝    │ ments 📢 │    💬    │    👤    │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
```

## 📊 Dashboard Section Layout

```
┌─────────────────────────────────────┐
│  Quick Stats                        │
│  ┌──────────┐  ┌──────────┐        │
│  │ Average  │  │Attendance│        │
│  │   85%    │  │   95%    │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  Recent Grades                      │
│  ┌───────────────────────────────┐ │
│  │ A  Math Exam    95/100        │ │
│  ├───────────────────────────────┤ │
│  │ B  Science Quiz 85/100        │ │
│  ├───────────────────────────────┤ │
│  │ A  English Test 92/100        │ │
│  └───────────────────────────────┘ │
│                                     │
│  Pending Homework                   │
│  ┌───────────────────────────────┐ │
│  │ 📝 Math Assignment            │ │
│  ├───────────────────────────────┤ │
│  │ 📝 Science Project            │ │
│  └───────────────────────────────┘ │
│                                     │
│  Latest Announcements               │
│  ┌───────────────────────────────┐ │
│  │ 📢 School Event Tomorrow      │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 🎯 Performance Section Layout

```
┌─────────────────────────────────────┐
│  Overall Average                    │
│  ┌───────────────────────────────┐ │
│  │        85.5%                  │ │
│  │     (12 Grades)               │ │
│  └───────────────────────────────┘ │
│                                     │
│  All Grades                         │
│  ┌───────────────────────────────┐ │
│  │ A  Math Final    95/100  95%  │ │
│  │ ████████████████░░░░          │ │
│  │ 📅 2024-01-15  [Exam]         │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ B  Science Quiz  85/100  85%  │ │
│  │ ████████████░░░░░░░░          │ │
│  │ 📅 2024-01-14  [Quiz]         │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 📝 Homework Section Layout

```
┌─────────────────────────────────────┐
│  Stats                              │
│  ┌────────┐ ┌────────┐             │
│  │Pending │ │Submitted│            │
│  │   3    │ │   8     │            │
│  └────────┘ └────────┘             │
│  ┌────────┐ ┌────────┐             │
│  │Overdue │ │ Total  │             │
│  │   1    │ │   12   │             │
│  └────────┘ └────────┘             │
│                                     │
│  Filters                            │
│  [All] [Pending] [Submitted] [Overdue]│
│                                     │
│  Homework List                      │
│  ┌───────────────────────────────┐ │
│  │ ⏰ Math Assignment             │ │
│  │ Due: 2024-01-20  [PENDING]    │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ ✅ Science Project            │ │
│  │ Submitted: 2024-01-18 [DONE]  │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 📢 Announcements Section Layout

```
┌─────────────────────────────────────┐
│  ┌───────────────────────────────┐ │
│  │ ⚠️ School Event [URGENT]      │ │
│  │ Tomorrow at 9 AM              │ │
│  │ Please attend the parent      │ │
│  │ meeting in the main hall.     │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ ℹ️ Exam Schedule              │ │
│  │ 2024-01-15                    │ │
│  │ Final exams start next week.  │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 💬 Messages Section Layout

```
┌─────────────────────────────────────┐
│  Teachers                           │
│  ┌───────────────────────────────┐ │
│  │ 👨‍🏫 Mr. Smith (Math)     💬   │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 👩‍🏫 Ms. Johnson (Science) 💬  │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 👨‍🏫 Mr. Brown (English)   💬  │ │
│  └───────────────────────────────┘ │
│                                     │
│  [Tap to send message]              │
└─────────────────────────────────────┘
```

## 👤 Profile Section Layout

```
┌─────────────────────────────────────┐
│  Profile Header                     │
│  ┌───────────────────────────────┐ │
│  │         🤖                    │ │
│  │    Student Name               │ │
│  │    Grade 5                    │ │
│  └───────────────────────────────┘ │
│                                     │
│  Choose Avatar                      │
│  ┌───────────────────────────────┐ │
│  │ 🤖 👾 🦾 🦿 🛸 🚀           │ │
│  │ ⚡ 🔮 💎 🌟 ⭐ ✨           │ │
│  │ 🎯 🎮 🎨 🎭 🎪 🎬           │ │
│  │ 🏆 🥇 🎓 📚 🔬 🔭           │ │
│  └───────────────────────────────┘ │
│                                     │
│  Student Information                │
│  ┌───────────────────────────────┐ │
│  │ 🆔 Student ID: 12345          │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 👤 Name: John Doe             │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 🎨 Color Scheme

```
Primary Blue:    #007AFF  ████  (iOS Blue)
Success Green:   #34C759  ████  (Positive/Good)
Warning Orange:  #FF9500  ████  (Pending/Warning)
Error Red:       #FF3B30  ████  (Urgent/Error)
Background:      #F2F2F7  ████  (Light Gray)
Card White:      #FFFFFF  ████  (Pure White)
Text Black:      #000000  ████  (Primary Text)
Text Gray:       #8E8E93  ████  (Secondary Text)
```

## 📦 Component Hierarchy

```
ParentDashboard
├── AppBar (with back button & student name)
├── Body (switches based on selected tab)
│   ├── DashboardSection
│   ├── PerformanceSection
│   ├── HomeworkSection
│   ├── AnnouncementsSection
│   ├── MessagesSection
│   └── ProfileSection
└── BottomNavigationBar (6 tabs)
```

## 🔄 Data Flow

```
User Login
    ↓
Fetch Parent Data
    ↓
Get Children List
    ↓
Select Child
    ↓
Load Child Data
    ├── Grades
    ├── Homework
    ├── Attendance
    ├── Announcements
    └── Teachers
    ↓
Display in Sections
    ↓
Pull to Refresh (updates data)
```

## 💡 Key Design Principles

1. **Simplicity**: One task per screen
2. **Clarity**: Clear labels and icons
3. **Consistency**: Same patterns throughout
4. **Feedback**: Loading, success, error states
5. **Accessibility**: Large touch targets, readable text
6. **Performance**: Efficient data loading
7. **Delight**: Smooth animations, fun avatars

This structure ensures a clean, maintainable, and user-friendly parent experience! 🎉
