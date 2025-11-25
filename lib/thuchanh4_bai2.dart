import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'thuchanh4_bai1.dart' as shop;

// Model cho người dùng
class AppUser {
  final String id;
  final String email;
  final String role; // 'student', 'parent', 'teacher'
  final String name;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      name: data['name'] ?? '',
    );
  }
}

// Model cho lịch học
class ScheduleItem {
  final String id;
  final String subject;
  final String teacher;
  final String time;
  final String day;

  ScheduleItem({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.time,
    required this.day,
  });

  factory ScheduleItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ScheduleItem(
      id: doc.id,
      subject: data['subject'] ?? '',
      teacher: data['teacher'] ?? '',
      time: data['time'] ?? '',
      day: data['day'] ?? '',
    );
  }
}

// Model cho điểm số
class GradeItem {
  final String subject;
  final double score;
  final String semester;
  final String studentId;
  final String studentName;

  GradeItem({
    required this.subject,
    required this.score,
    required this.semester,
    this.studentId = '',
    this.studentName = '',
  });

  factory GradeItem.fromMap(Map<String, dynamic> data) {
    return GradeItem(
      subject: data['subject'] ?? '',
      score: (data['score'] as num).toDouble(),
      semester: data['semester'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'score': score,
      'semester': semester,
      'studentId': studentId,
      'studentName': studentName,
    };
  }
}

// Ứng dụng chính
class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Trường học',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Wrapper để kiểm tra trạng thái đăng nhập
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

// Màn hình đăng nhập
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedRole = 'student';

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Đăng ký
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Lưu thông tin user vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': _selectedRole,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Học sinh')),
                    DropdownMenuItem(value: 'parent', child: Text('Phụ huynh')),
                    DropdownMenuItem(value: 'teacher', child: Text('Giáo viên')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value!);
                  },
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _authenticate,
                      child: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Màn hình chính
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<AppUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _getCurrentUser();
  }

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<AppUser?> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) return const LoginPage();

        final List<Widget> pages = [
          HomeContent(user: user, onNavigateToTab: changeTab),
          SchedulePage(user: user),
          user.role == 'teacher' ? TeacherGradesPage(user: user) : GradesPage(user: user),
          NotificationsPage(user: user),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text('Xin chào ${user.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Chuyển sang Shop Online',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const shop.ShopOnline(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Lịch học',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grade),
                label: 'Điểm số',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Thông báo',
              ),
            ],
          ),
        );
      },
    );
  }
}

// Nội dung trang chủ
class HomeContent extends StatelessWidget {
  final AppUser user;
  final Function(int) onNavigateToTab;

  const HomeContent({
    super.key,
    required this.user,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade700,
                        radius: 30,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.role == 'student'
                                  ? 'Học sinh'
                                  : user.role == 'parent'
                                      ? 'Phụ huynh'
                                      : 'Giáo viên',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tính năng chính:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (user.role == 'student') ...[
            _buildFeatureCard(
              context,
              'Xem lịch học',
              Icons.calendar_today,
              'Xem thời khóa biểu và lịch học',
              () => onNavigateToTab(1),
            ),
            _buildFeatureCard(
              context,
              'Xem điểm số',
              Icons.grade,
              'Xem điểm các môn học',
              () => onNavigateToTab(2),
            ),
            _buildFeatureCard(
              context,
              'Xem thông báo',
              Icons.notifications,
              'Xem thông báo từ nhà trường',
              () => onNavigateToTab(3),
            ),
            const SizedBox(height: 16),
            StudentParentLinker(studentUser: user),
          ] else if (user.role == 'parent') ...[
            _buildFeatureCard(
              context,
              'Theo dõi tiến độ con',
              Icons.child_care,
              'Theo dõi học tập của con',
              null,
            ),
            _buildFeatureCard(
              context,
              'Xem điểm số con',
              Icons.grade,
              'Xem điểm của con em',
              () => onNavigateToTab(2),
            ),
            _buildFeatureCard(
              context,
              'Nhận thông báo từ trường',
              Icons.notifications,
              'Xem thông báo từ nhà trường',
              () => onNavigateToTab(3),
            ),
            const SizedBox(height: 16),
            ParentStudentSelector(parentUser: user),
          ] else ...[
            _buildFeatureCard(
              context,
              'Quản lý điểm',
              Icons.edit,
              'Xem và quản lý điểm học sinh',
              () => onNavigateToTab(2),
            ),
            _buildFeatureCard(
              context,
              'Thêm điểm mới',
              Icons.add_circle,
              'Thêm điểm cho học sinh',
              () => onNavigateToTab(2),
            ),
            _buildFeatureCard(
              context,
              'Xem lịch học',
              Icons.calendar_today,
              'Xem lịch giảng dạy',
              () => onNavigateToTab(1),
            ),
            _buildFeatureCard(
              context,
              'Tạo lịch học',
              Icons.add_box,
              'Tạo lịch học mới cho học sinh',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateSchedulePage(user: user),
                  ),
                );
              },
            ),
            _buildFeatureCard(
              context,
              'Gửi thông báo',
              Icons.send,
              'Gửi thông báo đến học sinh',
              () => onNavigateToTab(3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// Màn hình lịch học
class SchedulePage extends StatelessWidget {
  final AppUser user;

  const SchedulePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('schedule').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Có lỗi xảy ra'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final schedules = snapshot.data!.docs
              .map((doc) => ScheduleItem.fromFirestore(doc))
              .toList();

          if (schedules.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có lịch học'),
                ],
              ),
            );
          }

          // Nhóm lịch học theo ngày
          Map<String, List<ScheduleItem>> schedulesByDay = {};
          for (var schedule in schedules) {
            if (!schedulesByDay.containsKey(schedule.day)) {
              schedulesByDay[schedule.day] = [];
            }
            schedulesByDay[schedule.day]!.add(schedule);
          }

          final daysOrder = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
          final sortedDays = schedulesByDay.keys.toList()
            ..sort((a, b) => daysOrder.indexOf(a).compareTo(daysOrder.indexOf(b)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
              final day = sortedDays[index];
              final daySchedules = schedulesByDay[day]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            day,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...daySchedules.map((schedule) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(Icons.book, color: Colors.blue.shade700),
                          ),
                          title: Text(
                            schedule.subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${schedule.teacher}\n${schedule.time}'),
                          isThreeLine: true,
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: user.role == 'teacher'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateSchedulePage(user: user),
                  ),
                );
              },
              backgroundColor: Colors.blue.shade700,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// Màn hình tạo lịch học cho giáo viên
class CreateSchedulePage extends StatefulWidget {
  final AppUser user;

  const CreateSchedulePage({super.key, required this.user});

  @override
  State<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _timeController = TextEditingController();
  String _selectedDay = 'Thứ 2';

  @override
  void initState() {
    super.initState();
    _teacherController.text = widget.user.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo lịch học mới'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin lịch học',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Môn học',
                          prefixIcon: Icon(Icons.book),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập môn học';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _teacherController,
                        decoration: const InputDecoration(
                          labelText: 'Giáo viên',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên giáo viên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian (VD: 07:00 - 08:30)',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập thời gian';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Ngày trong tuần',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Thứ 2', child: Text('Thứ 2')),
                          DropdownMenuItem(value: 'Thứ 3', child: Text('Thứ 3')),
                          DropdownMenuItem(value: 'Thứ 4', child: Text('Thứ 4')),
                          DropdownMenuItem(value: 'Thứ 5', child: Text('Thứ 5')),
                          DropdownMenuItem(value: 'Thứ 6', child: Text('Thứ 6')),
                          DropdownMenuItem(value: 'Thứ 7', child: Text('Thứ 7')),
                          DropdownMenuItem(value: 'Chủ nhật', child: Text('Chủ nhật')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDay = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createSchedule,
                icon: const Icon(Icons.add),
                label: const Text('Tạo lịch học'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('schedule').add({
        'subject': _subjectController.text,
        'teacher': _teacherController.text,
        'time': _timeController.text,
        'day': _selectedDay,
        'createdBy': widget.user.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo lịch học thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}

// Widget liên kết học sinh với phụ huynh
class StudentParentLinker extends StatelessWidget {
  final AppUser studentUser;

  const StudentParentLinker({super.key, required this.studentUser});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phụ huynh của bạn:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _showLinkParentDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'parent')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                // Lọc phụ huynh đã được liên kết
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(studentUser.id)
                      .get(),
                  builder: (context, studentSnapshot) {
                    if (!studentSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final studentData = studentSnapshot.data!.data() as Map<String, dynamic>?;
                    final parentId = studentData?['parentId'] as String?;

                    if (parentId == null) {
                      return const Text('Chưa liên kết với phụ huynh');
                    }

                    // Tìm thông tin phụ huynh
                    final parentDoc = snapshot.data!.docs.firstWhere(
                      (doc) => doc.id == parentId,
                      orElse: () => throw Exception('Không tìm thấy phụ huynh'),
                    );

                    final parentData = parentDoc.data() as Map<String, dynamic>;
                    final parentName = parentData['name'] ?? 'Phụ huynh';

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.family_restroom, color: Colors.white),
                      ),
                      title: Text(parentName),
                      subtitle: Text(parentData['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _unlinkParent(context),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkParentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liên kết với phụ huynh'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'parent')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final parents = snapshot.data!.docs;

              if (parents.isEmpty) {
                return const Text('Không có phụ huynh nào trong hệ thống');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: parents.length,
                itemBuilder: (context, index) {
                  final parentData = parents[index].data() as Map<String, dynamic>;
                  final parentName = parentData['name'] ?? 'Phụ huynh';
                  final parentEmail = parentData['email'] ?? '';

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.family_restroom, color: Colors.white),
                    ),
                    title: Text(parentName),
                    subtitle: Text(parentEmail),
                    onTap: () async {
                      await _linkParent(context, parents[index].id);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkParent(BuildContext context, String parentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentUser.id)
          .update({'parentId': parentId});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liên kết phụ huynh thành công!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _unlinkParent(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn hủy liên kết với phụ huynh?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentUser.id)
          .update({'parentId': FieldValue.delete()});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy liên kết với phụ huynh')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}

// Widget chọn học sinh cho phụ huynh
class ParentStudentSelector extends StatelessWidget {
  final AppUser parentUser;

  const ParentStudentSelector({super.key, required this.parentUser});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Con em của bạn:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('parentId', isEqualTo: parentUser.id)
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final students = snapshot.data!.docs;

                if (students.isEmpty) {
                  return const Text('Chưa có thông tin học sinh');
                }

                return Column(
                  children: students.map((doc) {
                    final studentData = doc.data() as Map<String, dynamic>;
                    final studentName = studentData['name'] ?? 'Học sinh';
                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(studentName),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParentViewGradesPage(
                              studentId: doc.id,
                              studentName: studentName,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Màn hình phụ huynh xem điểm con
class ParentViewGradesPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const ParentViewGradesPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm của $studentName'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('grades')
            .doc(studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Có lỗi xảy ra'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có điểm số'),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final grades = (data['grades'] as List<dynamic>?)
              ?.map((e) => GradeItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
              [];

          // Tính điểm trung bình
          double averageScore = 0;
          if (grades.isNotEmpty) {
            averageScore = grades.fold(0.0, (sum, grade) => sum + grade.score) /
                grades.length;
          }

          return Column(
            children: [
              // Card điểm trung bình
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điểm trung bình',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tất cả các môn',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    Text(
                      averageScore.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Danh sách điểm
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grades.length,
                  itemBuilder: (context, index) {
                    final grade = grades[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getGradeColor(grade.score),
                          child: const Icon(Icons.grade, color: Colors.white),
                        ),
                        title: Text(
                          grade.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Học kỳ: ${grade.semester}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeColor(grade.score),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            grade.score.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getGradeColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6.5) return Colors.blue;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }
}

// Màn hình điểm số cho học sinh
class GradesPage extends StatelessWidget {
  final AppUser user;

  const GradesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.role == 'parent') {
      return const Center(
        child: Text(
          'Vui lòng chọn con em từ trang chủ để xem điểm',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (user.role != 'student') {
      return const Center(child: Text('Chỉ học sinh mới có thể xem điểm'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grades')
          .doc(user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Có lỗi xảy ra'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Chưa có điểm số'),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final grades = (data['grades'] as List<dynamic>?)
            ?.map((e) => GradeItem.fromMap(e as Map<String, dynamic>))
            .toList() ??
            [];

        // Tính điểm trung bình
        double averageScore = 0;
        if (grades.isNotEmpty) {
          averageScore = grades.fold(0.0, (sum, grade) => sum + grade.score) /
              grades.length;
        }

        return Column(
          children: [
            // Card điểm trung bình
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điểm trung bình',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tất cả các môn',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Text(
                    averageScore.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Danh sách điểm
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: grades.length,
                itemBuilder: (context, index) {
                  final grade = grades[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getGradeColor(grade.score),
                        child: const Icon(Icons.grade, color: Colors.white),
                      ),
                      title: Text(
                        grade.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Học kỳ: ${grade.semester}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor(grade.score),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          grade.score.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getGradeColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6.5) return Colors.blue;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }
}

// Màn hình quản lý điểm cho giáo viên
class TeacherGradesPage extends StatefulWidget {
  final AppUser user;

  const TeacherGradesPage({super.key, required this.user});

  @override
  State<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _TeacherGradesPageState extends State<TeacherGradesPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Có lỗi xảy ra'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có học sinh nào'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentData =
                  students[index].data() as Map<String, dynamic>;
              final studentName = studentData['name'] ?? 'Học sinh';
              final studentId = students[index].id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ID: ${studentId.substring(0, 8)}...'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParentViewGradesPage(
                                studentId: studentId,
                                studentName: studentName,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          _showAddGradeDialog(context, studentId, studentName);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton.extended(
          onPressed: () {
            _showAddGradeToMultipleStudents(context);
          },
          backgroundColor: Colors.blue.shade700,
          icon: const Icon(Icons.add_circle),
          label: const Text('Thêm điểm nhanh'),
        ),
      ),
      ],
    );
  }

  void _showAddGradeDialog(
      BuildContext context, String studentId, String studentName) {
    final subjectController = TextEditingController();
    final scoreController = TextEditingController();
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm điểm cho $studentName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Môn học',
                  prefixIcon: Icon(Icons.book),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Điểm số',
                  prefixIcon: Icon(Icons.grade),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(
                  labelText: 'Học kỳ',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.isEmpty ||
                  scoreController.text.isEmpty ||
                  semesterController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                );
                return;
              }

              try {
                final score = double.parse(scoreController.text);
                final grade = GradeItem(
                  subject: subjectController.text,
                  score: score,
                  semester: semesterController.text,
                  studentId: studentId,
                  studentName: studentName,
                );

                // Lấy điểm hiện tại
                final doc = await FirebaseFirestore.instance
                    .collection('grades')
                    .doc(studentId)
                    .get();

                List<Map<String, dynamic>> currentGrades = [];
                if (doc.exists) {
                  final data = doc.data() as Map<String, dynamic>;
                  currentGrades = List<Map<String, dynamic>>.from(
                      data['grades'] ?? []);
                }

                // Thêm điểm mới
                currentGrades.add(grade.toMap());

                // Cập nhật vào Firestore
                await FirebaseFirestore.instance
                    .collection('grades')
                    .doc(studentId)
                    .set({'grades': currentGrades});

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm điểm thành công!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showAddGradeToMultipleStudents(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm điểm cho nhiều học sinh'),
        content: const Text(
          'Tính năng này sẽ cho phép bạn thêm điểm cho nhiều học sinh cùng lúc.\n\nĐang phát triển...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

// Màn hình thông báo
class NotificationsPage extends StatelessWidget {
  final AppUser user;

  const NotificationsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Có lỗi xảy ra'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final data = notifications[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications, color: Colors.orange),
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['message'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}
