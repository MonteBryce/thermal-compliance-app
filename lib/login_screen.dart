import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> signInWithMicrosoft() async {
    // TODO: Implement Microsoft sign-in
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation from login
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B132B),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 600
                                ? 24
                                : 48,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Spacer(),
                                const SizedBox(height: 40),
                                // Logo
                                Center(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width <
                                                  400
                                              ? 200
                                              : 280,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 32),
                                    child: Image.asset(
                                      'assets/images/gem_logo.png',
                                      width: MediaQuery.of(context).size.width <
                                              400
                                          ? 200
                                          : 280,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // App Title
                                Text(
                                  'Thermal Log App',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 400
                                            ? 20
                                            : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Subtitle
                                Text(
                                  'Secure Field Entry Portal',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 400
                                            ? 14
                                            : 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width < 400
                                            ? 32
                                            : 48),

                                // Microsoft Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: signInWithMicrosoft,
                                    icon: SvgPicture.asset(
                                      'assets/images/microsoft_icon.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                    ),
                                    label:
                                        const Text('Continue with Microsoft'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),

                                // Divider with "or"
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(color: Colors.white24),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          'or',
                                          style: GoogleFonts.nunito(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(color: Colors.white24),
                                      ),
                                    ],
                                  ),
                                ),

                                // Email Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      try {
                                        // First try to create the test user if it doesn't exist
                                        try {
                                          await FirebaseAuth.instance
                                              .createUserWithEmailAndPassword(
                                            email: 'test@example.com',
                                            password: 'password123',
                                          );
                                          debugPrint(
                                              'Test user created successfully');
                                        } catch (e) {
                                          // Ignore error if user already exists
                                          debugPrint(
                                              'Test user might already exist: $e');
                                        }

                                        // Now try to sign in
                                        final credential = await FirebaseAuth
                                            .instance
                                            .signInWithEmailAndPassword(
                                          email: 'test@example.com',
                                          password: 'password123',
                                        );

                                        if (credential.user != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Successfully signed in'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          debugPrint(
                                              'Signed in: ${credential.user?.email}');
                                        }
                                      } on FirebaseAuthException catch (e) {
                                        String message;

                                        switch (e.code) {
                                          case 'user-not-found':
                                            message =
                                                'No user found with this email';
                                            break;
                                          case 'wrong-password':
                                            message = 'Wrong password provided';
                                            break;
                                          case 'invalid-email':
                                            message = 'Invalid email format';
                                            break;
                                          case 'user-disabled':
                                            message =
                                                'This account has been disabled';
                                            break;
                                          default:
                                            message =
                                                'An error occurred: ${e.message}';
                                        }

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(message),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        debugPrint('Error: $message');
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'An unexpected error occurred: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        debugPrint('Error: $e');
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Colors.white24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Sign in with Email',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 48),

                                // Disclaimer
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Only authorized operators may log data.',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white54,
                                          fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width <
                                                  400
                                              ? 12
                                              : 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Please use your Microsoft account.',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white54,
                                          fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width <
                                                  400
                                              ? 12
                                              : 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Footer Links
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).size.width < 400
                                            ? 16
                                            : 24,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    400
                                                ? 8
                                                : 12,
                                          ),
                                        ),
                                        child: Text(
                                          'Terms of Service',
                                          style: GoogleFonts.nunito(
                                            color: Colors.white54,
                                            fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    400
                                                ? 10
                                                : 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width <
                                                  400
                                              ? 10
                                              : 12,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    400
                                                ? 8
                                                : 12,
                                          ),
                                        ),
                                        child: Text(
                                          'Privacy Policy',
                                          style: GoogleFonts.nunito(
                                            color: Colors.white54,
                                            fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    400
                                                ? 10
                                                : 12,
                                          ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
