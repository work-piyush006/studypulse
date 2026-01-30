import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About StudyPulse'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 App Logo
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 90,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'StudyPulse',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Focus • Track • Succeed',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 About App
            const Text(
              'Why StudyPulse?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'StudyPulse is built to help students stay focused, '
              'track their academic progress, and prepare better for exams. '
              'It combines essential student tools like percentage calculation, '
              'CGPA conversion, and exam countdown with smart reminders.',
              style: TextStyle(height: 1.5),
            ),

            const SizedBox(height: 30),

            // 🔹 Developer Section
            const Text(
              'Developer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            _infoTile(
              icon: Icons.person,
              title: 'Piyush Sharma',
              subtitle: 'Independent Student Developer',
            ),

            _infoTile(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'work.piyush006@gmail.com',
              onTap: () => _launchUrl(
                'mailto:work.piyush006@gmail.com',
              ),
            ),

            _infoTile(
              icon: Icons.camera_alt,
              title: 'Instagram',
              subtitle: '@_piyush0609',
              onTap: () => _launchUrl(
                'https://instagram.com/_piyush0609',
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Privacy Policy
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            _infoTile(
              icon: Icons.public,
              title: 'View Privacy Policy',
              subtitle:
                  'studypulse-privacypolicy.blogspot.com',
              onTap: () => _launchUrl(
                'http://studypulse-privacypolicy.blogspot.com/2026/01/studypulse-privacy-policy.html',
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Footer
            Center(
              child: Column(
                children: const [
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    'Made with ❤️ for students',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '© 2026 StudyPulse',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}