import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = false; // Default to Sign Up to match your screenshot
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedGender = 'men';
  bool _isLoading = false;

  static const String baseUrl = 'http://localhost:5000/api/auth';

  void _submit() async {
    setState(() => _isLoading = true);
    
    final url = isLogin ? '$baseUrl/login' : '$baseUrl/register';
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
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(token: data['token'], user: data['user'])),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection Error. Is the backend running?')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // LEFT COLUMN: FORM
                // ==========================================
                Container(
                  width: 450,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny, color: Color(0xFF2C3E50), size: 28),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ClimaWear", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                              Text("YOUR WEATHER-SMART WARDROBE", style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Toggle Buttons
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => isLogin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: !isLogin ? const Color(0xFF2C3E50) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text("Create Account", style: TextStyle(color: !isLogin ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => isLogin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: isLogin ? const Color(0xFF2C3E50) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text("Sign In", style: TextStyle(color: isLogin ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const Spacer(),
                          const Row(
                            children: [
                              Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                              SizedBox(width: 4),
                              Text("JWT Secure", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Titles
                      const Text("STEP 01 / AUTHENTICATION & CURATION BASE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      const Text("Personalize your meteorological outfit engine.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      const Text("Configure your silhouette preferences and wardrobe index for tailored, weather-responsive layering.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 30),

                      // Fields
                      if (!isLogin) ...[
                        _buildTextField("Full Name", "Astrid Lindqvist", Icons.person_outline, _nameController),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField("Email Address", "astrid@fordstudio.se", Icons.email_outlined, _emailController),
                      const SizedBox(height: 16),
                      _buildTextField("Password", "Minimum 8 characters", Icons.lock_outline, _passwordController, isObscure: true),
                      
                      if (!isLogin) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Wardrobe Silhouette Seed", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text("Used for initial Atlas vector matching", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildGenderChip('Men', 'men'),
                            const SizedBox(width: 8),
                            _buildGenderChip('Women', 'women'),
                            const SizedBox(width: 8),
                            _buildGenderChip('Unisex / All', 'unisex'),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Dynamic Engine Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.thermostat, color: Color(0xFFB07D62), size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Dynamic Thermal Engine Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6B4A36))),
                                  SizedBox(height: 4),
                                  Text("Upon registration, local UV index, humidity, wind gusts, and precipitation forecasts will generate custom multi-layered garment configurations.", style: TextStyle(fontSize: 11, color: Color(0xFF8B5A40), height: 1.4)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isLogin ? "Sign In" : "Create Account → Get Recommendations", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Privacy note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("Stores user auth token, gender profile & favorites in MongoDB Atlas  •  v2.4.1", style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(width: 40),

                // ==========================================
                // RIGHT COLUMN: VISUALS
                // ==========================================
                if (MediaQuery.of(context).size.width > 1000)
                  Column(
                    children: [
                      // Outfit Preview Card
                      Container(
                        width: 400,
                        height: 480,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EBE1), // Light beige
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: const Text("DAILY CURATED FIT #104", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                                const Icon(Icons.bookmark_border, color: Colors.grey, size: 20),
                              ],
                            ),
                            const Spacer(),
                            // Placeholder for clothes
                            Center(
                              child: Icon(Icons.checkroom, size: 180, color: Colors.grey.shade400),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("TARGET CONDITIONS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                                      SizedBox(height: 4),
                                      Text("19°C • Overcast Breezy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("Thermal Comfort", style: TextStyle(fontSize: 9, color: Colors.grey)),
                                      SizedBox(height: 4),
                                      Text("Optimal (Layer 1.5)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB07D62))),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Live Sensor Calibration Card
                      Container(
                        width: 400,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E50), // Dark navy
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("LIVE SENSOR CALIBRATION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
                                Icon(Icons.sensors, color: Colors.white54, size: 16),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSensorStat("Humidity", "54%"),
                                _buildSensorStat("Wind Spd", "12 km/h"),
                                _buildSensorStat("Precip Risk", "10%"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("Atlas wardrobe clustering weights breathable textiles when humidity is above 50% and precipitation is under 20%.", style: TextStyle(fontSize: 10, color: Colors.white70, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isObscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF9F8F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String label, String value) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}