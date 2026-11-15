import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherGraph extends StatelessWidget {
  const WeatherGraph({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current time and generate the next few hours
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');

    String t1 = timeFormat.format(now.subtract(const Duration(hours: 3)));
    String t2 = timeFormat.format(now);
    String t3 = timeFormat.format(now.add(const Duration(hours: 2)));
    String t4 = timeFormat.format(now.add(const Duration(hours: 4)));
    String t5 = timeFormat.format(now.add(const Duration(hours: 6)));

    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          // 1. The Background Arc & Line
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcPainter(),
            ),
          ),
          
          // 2. The Data Points & Labels
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTimeLabel(t1, "23°"),
                _buildTimeLabel(t2, "27°"),
                
                // Highlighted Current Time
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF2C3E50), shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 4),
                    Text("$t3 • 29°", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  ],
                ),
                
                _buildTimeLabel(t4, "25°"),
                _buildTimeLabel(t5, "22°"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabel(String time, String temp) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("$time • $temp", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintArea = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2C3E50).withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    
    path.moveTo(0, size.height - 20);

    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1, 
      size.width * 0.5, size.height * 0.2,  
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.3, 
      size.width, size.height - 20,         
    );

    canvas.drawPath(path, paintLine);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paintArea);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}