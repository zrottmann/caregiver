import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/simple_auth_service.dart';
import 'services/simple_appointment_service.dart';
import 'services/denver_rate_service.dart';
import 'services/appwrite_messaging_service.dart';
import 'services/appwrite_service.dart';
import 'models/message.dart';
import 'screens/booking/simple_booking_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appwrite with environment variables
  await AppwriteService.instance.initialize();

  runApp(const CaregiverPlatformApp());
}

class CaregiverPlatformApp extends StatelessWidget {
  const CaregiverPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Christy Cares',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D8A),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF2E7D8A),
          secondary: const Color(0xFF8B5A96),
          tertiary: const Color(0xFF4CAF50),
          surface: const Color(0xFFF5F9FA),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2D3748),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SimpleAuthService _authService = SimpleAuthService();
  bool _isLoggedIn = false;
  bool _loading = true;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoggedIn = true;
        _loading = false;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _loading = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _onLogout() async {
    await _authService.logout();
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    // Check if user is caregiver for admin mode
    if (_currentUser?['userType'] == 'caregiver') {
      return CaregiverAdminScreen(onLogout: _onLogout, currentUser: _currentUser!);
    }

    return MainScreen(onLogout: _onLogout);
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SimpleAuthService _authService = SimpleAuthService();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Christy Cares',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Personalized care with heart, by Christina Rottmann',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!value!.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Password is required';
                  return null;
                },
              ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _loading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Demo Mode',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '👤 Patient Login: Use any regular email',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '👩‍⚕️ Caregiver Admin: Use "christina@christycares.com" or any email with "caregiver", "admin", "nurse", or staff member names',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final success = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success) {
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;
  
  const MainScreen({super.key, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final SimpleAppointmentService _appointmentService = SimpleAppointmentService();
  final SimpleAuthService _authService = SimpleAuthService();
  final AppwriteMessagingService _messagingService = AppwriteMessagingService();
  List<SimpleAppointment> _appointments = [];
  List<Message> _messages = [];
  Map<String, dynamic>? _currentUser;
  int _unreadMessageCount = 0;
  String get _userType => _currentUser?['userType'] ?? 'patient';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authService.getCurrentUser();
    final appointments = await _appointmentService.getAppointments();

    // Load messages from Appwrite
    final messageDocs = await _messagingService.getMessages(user?['id'] ?? '');
    final messages = messageDocs.map((doc) => Message.fromDocument(doc)).toList();
    final unreadCount = await _messagingService.getUnreadCount(user?['id'] ?? '');

    setState(() {
      _currentUser = user;
      _appointments = appointments;
      _messages = messages;
      _unreadMessageCount = unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Christy Cares',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: widget.onLogout,
              tooltip: 'Sign Out',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Book',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildBookingScreen();
      case 2:
        return _buildAppointmentsScreen();
      case 3:
        return _buildMessagesScreen();
      case 4:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Christy Cares, ${_currentUser?['name'] ?? 'Friend'}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Care Sessions', _appointments.length.toString(), Icons.calendar_today),
                      _buildStatCard('Years Experience', '8', Icons.favorite),
                      _buildStatCard('Satisfaction', '4.9', Icons.star),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Christina's Personal Message",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _appointments.isEmpty
              ? Center(
                  child: Card(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome to Christy Cares!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hi there! I'm Christina Rottmann, and I care deeply about your happiness and wellbeing. My mission is to help you reach your goals through personalized, compassionate assisted living services.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Let's start your wellness journey together!",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(appointment.caregiverName),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy - hh:mm a').format(appointment.dateTime),
                        ),
                        trailing: Chip(
                          label: Text(appointment.status),
                          backgroundColor: appointment.status == 'confirmed' 
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBookingScreen() {
    return BookingScreen(
      onAppointmentBooked: (appointment) async {
        await _appointmentService.bookAppointment(appointment);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
      },
    );
  }

  Widget _buildAppointmentsScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Appointments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _appointments.isEmpty
              ? const Center(
                  child: Text('No appointments yet. Book one from the Book tab!'),
                )
              : ListView.builder(
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  appointment.caregiverName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(appointment.status),
                                  backgroundColor: appointment.status == 'confirmed' 
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('EEEE, MMM dd, yyyy - hh:mm a').format(appointment.dateTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              appointment.description,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${appointment.location} - ${appointment.locationAddress}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${appointment.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _appointmentService.calculateCancellationFee(appointment.dateTime) == 0
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _appointmentService.getCancellationPolicyText(appointment.dateTime),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _appointmentService.calculateCancellationFee(appointment.dateTime) == 0
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openInGoogleMaps(appointment.locationAddress),
                                    icon: const Icon(Icons.map, size: 16),
                                    label: const Text('Maps'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _appointmentService.canEditAppointment(appointment.dateTime)
                                      ? () => _showEditAppointmentDialog(appointment)
                                      : null,
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      foregroundColor: _appointmentService.canEditAppointment(appointment.dateTime)
                                        ? null
                                        : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showCancellationDialog(appointment),
                                    icon: const Icon(Icons.cancel, size: 16),
                                    label: const Text('Cancel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                                      foregroundColor: Colors.red,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentUser?['name'] ?? 'User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUser?['email'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(_currentUser?['userType'] ?? 'patient'),
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Messages',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_unreadMessageCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadMessageCount new',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.sync, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Messages sync across email, SMS, and this app',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation with your caregiver',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isFromMe = message.senderId == (_currentUser?['id'] ?? '');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: message.isRead ? null : Colors.blue.withValues(alpha: 0.05),
                      child: InkWell(
                        onTap: () => _showMessageDialog(message),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isFromMe ? Colors.blue : Colors.green,
                                    child: Text(
                                      isFromMe ? 'Me' : message.senderName.substring(0, 1),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFromMe ? 'To: ${message.recipientName}' : message.senderName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _formatDateTime(message.timestamp),
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!message.isRead && !isFromMe)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    message.channel == MessageChannel.email
                                      ? Icons.email
                                      : message.channel == MessageChannel.sms
                                        ? Icons.phone
                                        : Icons.chat,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    message.channel.toString().split('.').last.toUpperCase(),
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showNewMessageDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Message'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _showMessageDialog(Message message) async {
    if (!message.isRead) {
      await _messagingService.markAsRead(message.id);
      await _loadData();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.senderName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, yyyy h:mm a').format(message.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(message.content),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  message.channel == MessageChannel.email
                    ? Icons.email
                    : message.channel == MessageChannel.sms
                      ? Icons.phone
                      : Icons.chat,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Sent via ${message.channel.toString().split('.').last}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showReplyDialog(message);
            },
            icon: const Icon(Icons.reply, size: 16),
            label: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _showNewMessageDialog() {
    final contentController = TextEditingController();
    final recipientController = TextEditingController(
      text: _userType == 'caregiver' ? 'Patient' : 'Christina Rottmann',
    );

    MessageChannel selectedChannel = MessageChannel.all;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Type your message here...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send via:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<MessageChannel>(
                        value: MessageChannel.all,
                        groupValue: selectedChannel,
                        onChanged: (value) => setState(() => selectedChannel = value!),
                        title: const Text('All channels (App + Email + SMS)'),
                        subtitle: const Text('Ensures delivery everywhere'),
                        dense: true,
                      ),
                      RadioListTile<MessageChannel>(
                        value: MessageChannel.app,
                        groupValue: selectedChannel,
                        onChanged: (value) => setState(() => selectedChannel = value!),
                        title: const Text('App only'),
                        subtitle: const Text('Quick, no notifications'),
                        dense: true,
                      ),
                      RadioListTile<MessageChannel>(
                        value: MessageChannel.email,
                        groupValue: selectedChannel,
                        onChanged: (value) => setState(() => selectedChannel = value!),
                        title: const Text('Email only'),
                        subtitle: const Text('For longer messages'),
                        dense: true,
                      ),
                      RadioListTile<MessageChannel>(
                        value: MessageChannel.sms,
                        groupValue: selectedChannel,
                        onChanged: (value) => setState(() => selectedChannel = value!),
                        title: const Text('SMS only'),
                        subtitle: const Text('For urgent messages'),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => _sendMessage(
                recipientController.text,
                contentController.text,
                selectedChannel,
              ),
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(Message originalMessage) {
    _showNewMessageDialog();
  }

  Future<void> _sendMessage(String recipient, String content, MessageChannel channel) async {
    if (content.trim().isEmpty) {
      _showSnackBar('Please enter a message');
      return;
    }

    try {
      await _messagingService.sendMessage(
        senderId: _currentUser?['id'] ?? '',
        senderName: _currentUser?['name'] ?? 'User',
        senderEmail: _currentUser?['email'] ?? 'user@example.com',
        recipientId: _userType == 'caregiver' ? 'patient-1' : 'caregiver-1',
        recipientName: recipient,
        recipientEmail: _userType == 'caregiver' ? 'patient@example.com' : 'christina@christycares.com',
        content: content,
        channel: Message.channelToString(channel),
        recipientPhone: _userType == 'caregiver' ? '+13035551234' : '+13035550123',
        senderPhone: _currentUser?['phone'],
      );

      await _loadData();
      Navigator.of(context).pop();
      _showSnackBar('Message sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> _openInGoogleMaps(String address) async {
    final url = _appointmentService.getGoogleMapsUrl(address);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Future<void> _openInAppleMaps(String address) async {
    final url = _appointmentService.getAppleMapsUrl(address);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Google Maps if Apple Maps is not available
      _openInGoogleMaps(address);
    }
  }

  void _showCancellationDialog(SimpleAppointment appointment) {
    final fee = _appointmentService.calculateCancellationFee(appointment.dateTime);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel your appointment with ${appointment.caregiverName}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fee == 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    fee == 0 ? Icons.check_circle : Icons.warning,
                    color: fee == 0 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fee == 0 
                        ? 'No cancellation fee'
                        : 'Cancellation fee: \$${fee.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: fee == 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _appointmentService.cancelAppointment(appointment.id);
              _loadData();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    fee == 0 
                      ? 'Appointment cancelled successfully' 
                      : 'Appointment cancelled. Fee: \$${fee.toStringAsFixed(0)}'
                  ),
                  backgroundColor: fee == 0 ? Colors.green : Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(fee == 0 ? 'Cancel Appointment' : 'Cancel & Pay Fee'),
          ),
        ],
      ),
    );
  }

  void _showEditAppointmentDialog(SimpleAppointment appointment) {
    // For now, show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _showEditProfileDialog() {
    // For now, show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile edit coming soon')),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class BookingScreen extends StatefulWidget {
  final Function(SimpleAppointment) onAppointmentBooked;
  
  const BookingScreen({super.key, required this.onAppointmentBooked});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCaregiver = 'Sarah Johnson, RN';
  String _selectedService = 'Personal Care & Daily Activities';
  String _selectedLocation = "Patient's Home";
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  final List<String> _caregivers = [
    'Christina Rottmann (Owner)',
    'Sarah Johnson, RN',
    'Emily Chen, CNA',
    'Michael Davis, HHA',
    'Lisa Brown, PCA',
  ];
  
  final Map<String, double> _services = {
    'Personal Care & Daily Activities': 45.0,
    'Companion Care & Emotional Support': 40.0,
    'Medication Management': 50.0,
    'Light Housekeeping & Meal Prep': 35.0,
    'Transportation & Errands': 30.0,
    'Specialized Dementia Care': 60.0,
  };
  
  final List<String> _locations = [
    "Patient's Home",
    "Caregiver's Location",
    'Medical Facility',
    'Community Center',
    'Custom Location',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Appointment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Date',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TableCalendar<void>(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(_selectedTime.format(context)),
                      leading: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Caregiver',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _selectedCaregiver,
                      isExpanded: true,
                      items: _caregivers.map((caregiver) {
                        return DropdownMenuItem(
                          value: caregiver,
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                child: Icon(Icons.person, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(caregiver),
                                  Text(
                                    '⭐ 4.9 • Personalized Care',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCaregiver = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Service',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _selectedService,
                      isExpanded: true,
                      items: _services.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text('\$${entry.value}/hr'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedService = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _selectedLocation,
                      isExpanded: true,
                      items: _locations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Row(
                            children: [
                              Icon(
                                _getLocationIcon(location),
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(location),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                    ),
                    if (_selectedLocation == 'Custom Location') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Address',
                          hintText: '123 Main St, City, State, ZIP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Notes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Any special requirements or notes...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Book Appointment & Pay Deposit',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLocationIcon(String location) {
    switch (location) {
      case "Patient's Home":
        return Icons.home;
      case "Caregiver's Location":
        return Icons.business;
      case 'Medical Facility':
        return Icons.local_hospital;
      case 'Community Center':
        return Icons.location_city;
      case 'Custom Location':
        return Icons.location_on;
      default:
        return Icons.place;
    }
  }

  String _getDefaultAddress(String location) {
    switch (location) {
      case "Patient's Home":
        return '123 Patient Home St, City, State 12345';
      case "Caregiver's Location":
        return '456 Caregiver Ave, City, State 12345';
      case 'Medical Facility':
        return '789 Hospital Dr, City, State 12345';
      case 'Community Center':
        return '321 Community Blvd, City, State 12345';
      default:
        return '123 Main St, City, State 12345';
    }
  }

  void _bookAppointment() {
    final address = _selectedLocation == 'Custom Location' 
      ? _addressController.text.isNotEmpty 
        ? _addressController.text 
        : '123 Main St, City, State'
      : _getDefaultAddress(_selectedLocation);
    
    final appointment = SimpleAppointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      caregiverName: _selectedCaregiver,
      dateTime: DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      price: _services[_selectedService]!,
      status: 'confirmed',
      description: _descriptionController.text.isEmpty 
        ? _selectedService 
        : '$_selectedService - ${_descriptionController.text}',
      location: _selectedLocation,
      locationAddress: address,
    );

    // Show payment dialog
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        amount: appointment.price,
        onPaymentComplete: () {
          Navigator.of(context).pop();
          widget.onAppointmentBooked(appointment);
        },
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class PaymentDialog extends StatefulWidget {
  final double amount;
  final VoidCallback onPaymentComplete;
  
  const PaymentDialog({
    super.key,
    required this.amount,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Deposit Amount: \$${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/25',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _processing ? null : _processPayment,
          child: _processing 
            ? const CircularProgressIndicator()
            : const Text('Pay Now'),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all payment fields')),
      );
      return;
    }

    setState(() => _processing = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _processing = false);
    
    widget.onPaymentComplete();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class CaregiverAdminScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> currentUser;
  
  const CaregiverAdminScreen({
    super.key, 
    required this.onLogout, 
    required this.currentUser,
  });

  @override
  State<CaregiverAdminScreen> createState() => _CaregiverAdminScreenState();
}

class _CaregiverAdminScreenState extends State<CaregiverAdminScreen> {
  int _currentIndex = 0;
  final DenverRateService _rateService = DenverRateService();
  final SimpleAppointmentService _appointmentService = SimpleAppointmentService();
  CaregiverProfile? _caregiverProfile;
  List<AvailabilitySlot> _availabilitySlots = [];
  List<SimpleAppointment> _appointments = [];
  String get _userType => 'caregiver';

  @override
  void initState() {
    super.initState();
    _loadCaregiverData();
  }

  Future<void> _loadCaregiverData() async {
    final caregivers = await _rateService.getCaregivers();
    final caregiver = caregivers.firstWhere(
      (c) => c.id == widget.currentUser['id'],
      orElse: () => caregivers.first,
    );
    final slots = await _rateService.getAvailabilitySlots(caregiver.id);

    setState(() {
      _caregiverProfile = caregiver;
      _availabilitySlots = slots;
    });

    await _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final appointments = await _appointmentService.getAppointments();
    setState(() {
      _appointments = appointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Christy Cares - Caregiver Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: widget.onLogout,
              tooltip: 'Sign Out',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: _buildCurrentScreen(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SimpleBookingForm()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Test Email Function'),
        backgroundColor: const Color(0xFF2E7D8A),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Rates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_caregiverProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildSchedule();
      case 2:
        return _buildRatesScreen();
      case 3:
        return _buildAnalytics();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final profile = _caregiverProfile!;
    final bookingPercentage = profile.bookingPercentage;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${profile.name}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Hours Worked', '${profile.totalHoursWorked}h', Icons.access_time),
                      _buildStatCard('Booking Rate', '${bookingPercentage.toStringAsFixed(1)}%', Icons.trending_up),
                      _buildStatCard('Rating', profile.rating.toString(), Icons.star),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dynamic Rate Multiplier',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(DenverRateService.getBookingMultiplier(bookingPercentage) * 100).toStringAsFixed(0)}% of base rate',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Based on your ${bookingPercentage.toStringAsFixed(1)}% booking rate',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: bookingPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      bookingPercentage >= 80 
                        ? Colors.green 
                        : bookingPercentage >= 60 
                          ? Colors.orange 
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSchedule() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Schedule',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAvailabilityDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Hours'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _availabilitySlots.isEmpty
              ? const Center(
                  child: Text(
                    'No availability set. Add your available hours to start receiving bookings.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _availabilitySlots.length,
                  itemBuilder: (context, index) {
                    final slot = _availabilitySlots[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          slot.isBooked ? Icons.event_busy : Icons.event_available,
                          color: slot.isBooked ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          DateFormat('EEEE, MMM dd').format(slot.startTime),
                        ),
                        subtitle: Text(
                          '${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}',
                        ),
                        trailing: slot.isBooked
                          ? const Chip(
                              label: Text('Booked'),
                              backgroundColor: Colors.red,
                            )
                          : const Chip(
                              label: Text('Available'),
                              backgroundColor: Colors.green,
                            ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesScreen() {
    final profile = _caregiverProfile!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dynamic Pricing System',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your rates automatically adjust based on performance metrics',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Explanation Card
          Card(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'How Dynamic Pricing Works',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Base rates are set using Denver, CO market research',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Your booking rate (${profile.bookingPercentage.toStringAsFixed(1)}%) affects pricing multiplier',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Higher ratings (${profile.rating}/5.0) earn premium rates',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Experience level (${profile.credentials}) adds qualification bonus',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: profile.bookingPercentage >= 80
                        ? Colors.green.withValues(alpha: 0.1)
                        : profile.bookingPercentage >= 60
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      profile.bookingPercentage >= 80
                        ? '✅ Excellent performance - earning premium rates!'
                        : profile.bookingPercentage >= 60
                          ? '⚠️ Good performance - room for improvement'
                          : '⚡ Focus on increasing your booking rate for higher pay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: profile.bookingPercentage >= 80
                          ? Colors.green[700]
                          : profile.bookingPercentage >= 60
                            ? Colors.orange[700]
                            : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Service Rates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              children: DenverRateService.denverBaseRates.entries.map((entry) {
                final dynamicRate = _rateService.calculateDynamicRate(
                  serviceType: entry.key,
                  bookingPercentage: profile.bookingPercentage,
                  credentials: profile.credentials,
                  rating: profile.rating,
                );

                final multiplier = dynamicRate / entry.value;
                final bonusPercent = ((multiplier - 1) * 100);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (bonusPercent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '+${bonusPercent.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Market Base',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '\$${entry.value.toStringAsFixed(2)}/hr',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Your Rate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '\$${dynamicRate.toStringAsFixed(2)}/hr',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: bonusPercent > 0 ? (bonusPercent / 50).clamp(0.0, 1.0) : 0.1,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            bonusPercent >= 20
                              ? Colors.green
                              : bonusPercent >= 10
                                ? Colors.orange
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bonusPercent > 0
                            ? 'Earning ${bonusPercent.toStringAsFixed(0)}% above market rate'
                            : 'At market rate - improve metrics for bonuses',
                          style: TextStyle(
                            fontSize: 11,
                            color: bonusPercent > 0 ? Colors.green[700] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    final profile = _caregiverProfile!;
    final totalEarnings = profile.totalHoursWorked * profile.baseRate;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earnings Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total Earnings', '\$${totalEarnings.toStringAsFixed(0)}', Icons.attach_money),
                      _buildStatCard('Avg Rate', '\$${profile.baseRate.toStringAsFixed(2)}/hr', Icons.trending_up),
                      _buildStatCard('Experience', '${DateTime.now().year - profile.joinDate.year}+ years', Icons.star),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Rate Multipliers Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How your performance metrics affect your hourly rates',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  _buildEnhancedMultiplierRow(
                    'Booking Rate Bonus',
                    DenverRateService.getBookingMultiplier(profile.bookingPercentage),
                    'Based on your ${profile.bookingPercentage.toStringAsFixed(1)}% booking rate',
                    profile.bookingPercentage >= 80
                      ? 'Excellent! Keep accepting bookings to maintain this bonus'
                      : profile.bookingPercentage >= 60
                        ? 'Good performance. Accept more bookings for higher rates'
                        : 'Focus on increasing your booking acceptance rate',
                    Icons.event_available,
                  ),

                  _buildEnhancedMultiplierRow(
                    'Experience Bonus',
                    DenverRateService.getExperienceMultiplier(profile.credentials),
                    'Your qualification level: ${profile.credentials}',
                    profile.credentials == 'RN'
                      ? 'Registered Nurse - highest qualification bonus'
                      : profile.credentials == 'CNA'
                        ? 'Certified Nursing Assistant - good qualification bonus'
                        : 'Consider additional certifications to increase this multiplier',
                    Icons.school,
                  ),

                  _buildEnhancedMultiplierRow(
                    'Rating Bonus',
                    profile.rating >= 4.8 ? 1.1 : (profile.rating >= 4.5 ? 1.05 : 1.0),
                    'Patient feedback rating: ${profile.rating}/5.0',
                    profile.rating >= 4.8
                      ? 'Outstanding! Patients love your care'
                      : profile.rating >= 4.5
                        ? 'Good rating. Continue providing excellent care'
                        : 'Focus on patient satisfaction to increase this bonus',
                    Icons.star,
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calculate, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Total Rate Calculation',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Base Rate × Booking Multiplier × Experience Multiplier × Rating Multiplier = Your Final Rate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierRow(String label, double multiplier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${(multiplier * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: multiplier > 1.0 ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMultiplierRow(String label, double multiplier, String description, String advice, IconData icon) {
    final isBonus = multiplier > 1.0;
    final bonusPercent = ((multiplier - 1) * 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBonus ? Colors.green.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBonus ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isBonus ? Colors.green[700] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isBonus ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isBonus ? '+${bonusPercent.toStringAsFixed(0)}%' : '${(multiplier * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isBonus ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            advice,
            style: TextStyle(
              fontSize: 11,
              color: isBonus ? Colors.green[700] : Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Availability'),
        content: const Text(
          'Schedule management coming soon! You can add your available hours and Christina will help coordinate with patient bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditAppointmentDialog(SimpleAppointment appointment) {
    if (!_appointmentService.canEditAppointment(appointment.dateTime)) {
      _showSnackBar(_appointmentService.getEditRestrictionMessage(appointment.dateTime));
      return;
    }

    final dateController = TextEditingController(
      text: appointment.dateTime.toLocal().toString().substring(0, 16),
    );
    final locationController = TextEditingController(text: appointment.location);
    final addressController = TextEditingController(text: appointment.locationAddress);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  hintText: 'YYYY-MM-DD HH:MM',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDateTime(dateController, appointment),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location Type',
                  hintText: 'e.g., Home, Hospital, Facility',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  hintText: 'Street, City, State, ZIP',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _appointmentService.getEditRestrictionMessage(appointment.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveAppointmentChanges(
              appointment,
              dateController.text,
              locationController.text,
              addressController.text,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _selectDateTime(TextEditingController controller, SimpleAppointment appointment) async {
    final now = DateTime.now();
    final initialDate = appointment.dateTime.isBefore(now.add(const Duration(hours: 2)))
        ? now.add(const Duration(hours: 2))
        : appointment.dateTime;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.add(const Duration(hours: 2)),
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

        if (_appointmentService.canRescheduleToTime(appointment.dateTime, newDateTime)) {
          controller.text = newDateTime.toLocal().toString().substring(0, 16);
        } else {
          _showSnackBar('Selected time is not available for scheduling');
        }
      }
    }
  }

  void _saveAppointmentChanges(SimpleAppointment original, String dateTimeStr, String location, String address) async {
    try {
      final newDateTime = DateTime.parse(dateTimeStr.replaceAll(' ', 'T'));

      if (!_appointmentService.canRescheduleToTime(original.dateTime, newDateTime)) {
        _showSnackBar('Invalid appointment time selected');
        return;
      }

      final updatedAppointment = SimpleAppointment(
        id: original.id,
        caregiverName: original.caregiverName,
        dateTime: newDateTime,
        price: original.price,
        status: original.status,
        description: original.description,
        location: location.trim().isEmpty ? original.location : location.trim(),
        locationAddress: address.trim().isEmpty ? original.locationAddress : address.trim(),
      );

      await _appointmentService.updateAppointment(updatedAppointment);
      await _loadAppointments();

      Navigator.of(context).pop();
      _showSnackBar('Appointment updated successfully!');
    } catch (e) {
      _showSnackBar('Failed to update appointment: ${e.toString()}');
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userType == 'caregiver' ? 'Christina Rottmann' : 'Patient Name');
    final emailController = TextEditingController(text: _userType == 'caregiver' ? 'christina@christycares.com' : 'patient@example.com');
    final phoneController = TextEditingController(text: _userType == 'caregiver' ? '(303) 555-0123' : '(555) 123-4567');
    final addressController = TextEditingController(text: _userType == 'caregiver' ? '1234 Healthcare Ave, Denver, CO 80202' : '5678 Patient St, Denver, CO 80210');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Home Address',
                  hintText: 'Street, City, State, ZIP',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address is used for appointment scheduling and navigation',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveProfileChanges(
              nameController.text,
              emailController.text,
              phoneController.text,
              addressController.text,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _saveProfileChanges(String name, String email, String phone, String address) {
    // Here you would typically save to a database or shared preferences
    Navigator.of(context).pop();
    _showSnackBar('Profile updated successfully!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}