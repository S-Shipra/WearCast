import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'home_screen.dart';
import '../services/location_service.dart';
import '../services/api_config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedGender = 'men';
  bool _isLoading = false;

  // Live Weather State
  bool _isWeatherLoading = true;
  String _dynamicCity = 'Detecting...';
  int _dynamicTemp = 19;
  int _dynamicHumidity = 54;
  int _dynamicWind = 12;
  int _dynamicPrecip = 10;
  String _dynamicCondition = 'Overcast Breezy';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather();
  }

  Future<void> _fetchLiveWeather() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      final res = await http
          .get(
            apiUri('weather', {'lat': '${loc['lat']}', 'lon': '${loc['lon']}'}),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          _dynamicCity = loc['city'] ?? 'Local Area';
          _dynamicTemp = (data['feelsLike'] as num).round();
          _dynamicHumidity = (data['humidity'] as num).round();
          _dynamicWind = (data['windSpeed'] as num).round();
          _dynamicPrecip = (data['rainProb'] as num).round();

          if (_dynamicPrecip > 40) {
            _dynamicCondition = 'Rainy Conditions';
          } else if (_dynamicHumidity > 70) {
            _dynamicCondition = 'Humid & Overcast';
          } else if (_dynamicTemp > 28) {
            _dynamicCondition = 'Sunny & Warm';
          } else if (_dynamicTemp < 15) {
            _dynamicCondition = 'Chilly Breeze';
          } else {
            _dynamicCondition = 'Overcast Breezy';
          }
          _isWeatherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isWeatherLoading = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final invalidPassword = isLogin ? password.isEmpty : password.length < 8;
    if ((!isLogin && _nameController.text.trim().isEmpty) ||
        !RegExp(r'^\S+@\S+\.\S+$').hasMatch(email) ||
        invalidPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogin
                ? 'Enter a valid email and password.'
                : 'Enter a valid email and a password with at least 8 characters.',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final url = apiUri(isLogin ? 'auth/login' : 'auth/register');
    final body = isLogin
        ? {
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
          }
        : {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'gender': _selectedGender,
          };

    try {
      final response = await http
          .post(url, headers: apiHeaders(json: true), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(token: data['token'], user: data['user']),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Something went wrong')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connection error. Check the API address and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE CHECK
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: Stack(
        children: [
          // TOP RIGHT BETA BADGE (Hidden on mobile to save space)
          if (!isMobile)
            Positioned(
              top: 20,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sensors,
                      size: 12,
                      color: Color(0xFFB07D62),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Beta Engine Connected • $_dynamicCity $_dynamicTemp°C $_dynamicCondition",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // MAIN CONTENT
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: isMobile ? 16.0 : 20.0,
                ),
                child: isMobile
                    ? Column(
                        // MOBILE LAYOUT
                        children: [
                          _buildFormContainer(isMobile),
                          const SizedBox(height: 24),
                          _buildVisualsContainer(isMobile),
                        ],
                      )
                    : Row(
                        // DESKTOP LAYOUT
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormContainer(isMobile),
                          const SizedBox(width: 40),
                          _buildVisualsContainer(isMobile),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 480,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF2C3E50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Wearcast",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    "YOUR WEATHER-SMART WARDROBE",
                    style: TextStyle(
                      fontSize: 7,
                      letterSpacing: 1,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Toggle Buttons
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => isLogin = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: !isLogin
                        ? const Color(0xFF2C3E50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Create Account",
                    style: TextStyle(
                      color: !isLogin ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => isLogin = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isLogin
                        ? const Color(0xFF2C3E50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: isLogin ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (!isMobile) ...[
                const Spacer(),
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      "JWT Secure",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 30),

          // Titles
          const Text(
            "STEP 01 / AUTHENTICATION & CURATION BASE",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Personalize your meteorological outfit engine.",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Configure your silhouette preferences and wardrobe index for tailored, weather-responsive layering.",
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 30),

          // Fields
          if (!isLogin) ...[
            _buildTextField(
              "Full Name",
              "Astrid Lindqvist",
              Icons.person_outline,
              _nameController,
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            "Email Address",
            "astrid@fordstudio.se",
            Icons.email_outlined,
            _emailController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            "Password",
            "Minimum 8 characters",
            Icons.lock_outline,
            _passwordController,
            isObscure: true,
          ),

          if (!isLogin) ...[
            const SizedBox(height: 24),
            if (isMobile)
              const Text(
                "Wardrobe Silhouette Seed",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Wardrobe Silhouette Seed",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Used for initial Atlas vector matching",
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
            if (isMobile) ...[
              const SizedBox(height: 4),
              Text(
                "Used for initial Atlas vector matching",
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGenderChip('Men', 'men', Icons.male),
                const SizedBox(width: 8),
                _buildGenderChip('Women', 'women', Icons.female),
                const SizedBox(width: 8),
                _buildGenderChip(
                  'Unisex / All',
                  'unisex',
                  Icons.people_outline,
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Dynamic Engine Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF2EBE1)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.thermostat, color: Color(0xFFB07D62), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dynamic Thermal Engine Active",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF6B4A36),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Upon registration, local UV index, humidity, wind gusts, and precipitation forecasts will generate custom multi-layered garment configurations.",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B5A40),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLogin
                          ? "Sign In"
                          : "Create Account & Get Recommendations →",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy note
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 12,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                "Privacy Anonymity Daily Forecast Deck",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Stores user auth token, gender profile & favorites in MongoDB Atlas  •  v2.4.1  •  REST API Microservices",
              style: TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualsContainer(bool isMobile) {
    return Column(
      children: [
        Container(
          width: isMobile ? double.infinity : 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F1EB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Daily Curated Fit #104",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.bookmark_border,
                    color: Colors.grey,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // FIXED IMAGE CONTAINER
              Container(
                height: 240,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EBE1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/auth_outfit_preview.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TARGET CONDITIONS",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isWeatherLoading
                            ? "Fetching..."
                            : "$_dynamicTemp°C • $_dynamicCondition",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Thermal Comfort",
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isWeatherLoading ? "..." : "Optimal (Layer 1.5)",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB07D62),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: isMobile ? double.infinity : 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LIVE SENSOR CALIBRATION",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                  Icon(Icons.sensors, color: Colors.white54, size: 14),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSensorStat(
                    "Humidity",
                    _isWeatherLoading ? "--" : "$_dynamicHumidity%",
                  ),
                  _buildSensorStat(
                    "Wind Spd",
                    _isWeatherLoading ? "--" : "$_dynamicWind km/h",
                  ),
                  _buildSensorStat(
                    "Precip Risk",
                    _isWeatherLoading ? "--" : "$_dynamicPrecip%",
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2C3E50)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String label, String value, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2C3E50)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
