import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() =>
      _SignUpScreenState();
}

class _SignUpScreenState
    extends State<SignUpScreen> {

  final _formKey = GlobalKey<FormState>();

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  final confirmPasswordController =
  TextEditingController();

  final auth = AuthService();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      await auth.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Registration Successful",
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString()
                .replaceAll(
                'Exception: ', ''),
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFBFF),
              Color(0xFFF5F3FF),
              Color(0xFFEDE9FE),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 450,
                  ),
                  child: Card(
                    color: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                          24),
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [

                          Icon(
                            Icons.person_add_alt_1,
                            size: 70,
                            color: theme
                                .primaryColor,
                          ),

                          const SizedBox(
                              height: 16),

                          Text(
                            "Create Account",
                            style: theme
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),

                          const SizedBox(
                              height: 8),

                          Text(
                            "Register to continue",
                            style: theme
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color:
                              Colors.grey,
                            ),
                          ),

                          const SizedBox(
                              height: 30),

                          TextFormField(
                            controller:
                            emailController,
                            keyboardType:
                            TextInputType
                                .emailAddress,
                            decoration:
                            InputDecoration(
                              labelText:
                              "Email",
                              prefixIcon:
                              const Icon(
                                Icons
                                    .email_outlined,
                              ),
                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                    12),
                              ),
                            ),
                            validator:
                                (value) {
                              if (value ==
                                  null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return "Email is required";
                              }

                              final emailRegex =
                              RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );

                              if (!emailRegex
                                  .hasMatch(
                                value.trim(),
                              )) {
                                return "Enter a valid email";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                              height: 16),

                          TextFormField(
                            controller:
                            passwordController,
                            obscureText:
                            obscurePassword,
                            decoration:
                            InputDecoration(
                              labelText:
                              "Password",
                              prefixIcon:
                              const Icon(
                                Icons
                                    .lock_outline,
                              ),
                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                    12),
                              ),
                              suffixIcon:
                              IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons
                                      .visibility
                                      : Icons
                                      .visibility_off,
                                ),
                                onPressed:
                                    () {
                                  setState(
                                          () {
                                        obscurePassword =
                                        !obscurePassword;
                                      });
                                },
                              ),
                            ),
                            validator:
                                (value) {
                              if (value ==
                                  null ||
                                  value
                                      .isEmpty) {
                                return "Password is required";
                              }

                              if (value
                                  .length <
                                  6) {
                                return "Password must be at least 6 characters";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                              height: 16),

                          TextFormField(
                            controller:
                            confirmPasswordController,
                            obscureText:
                            obscureConfirmPassword,
                            decoration:
                            InputDecoration(
                              labelText:
                              "Confirm Password",
                              prefixIcon:
                              const Icon(
                                Icons
                                    .lock_reset,
                              ),
                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                    12),
                              ),
                              suffixIcon:
                              IconButton(
                                icon: Icon(
                                  obscureConfirmPassword
                                      ? Icons
                                      .visibility
                                      : Icons
                                      .visibility_off,
                                ),
                                onPressed:
                                    () {
                                  setState(
                                          () {
                                        obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                      });
                                },
                              ),
                            ),
                            validator:
                                (value) {
                              if (value ==
                                  null ||
                                  value
                                      .isEmpty) {
                                return "Please confirm password";
                              }

                              if (value !=
                                  passwordController
                                      .text) {
                                return "Passwords do not match";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                              height: 24),

                          SizedBox(
                            width:
                            double.infinity,
                            height: 50,
                            child:
                            ElevatedButton(
                              onPressed:
                              loading
                                  ? null
                                  : register,
                              style:
                              ElevatedButton
                                  .styleFrom(
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                      12),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                height:
                                24,
                                width:
                                24,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth:
                                  2,
                                ),
                              )
                                  : const Text(
                                "Create Account",
                                style:
                                TextStyle(
                                  fontSize:
                                  16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              height: 16),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              const Text(
                                "Already have an account?",
                              ),
                              TextButton(
                                onPressed:
                                    () {
                                  Navigator.pop(
                                      context);
                                },
                                child:
                                const Text(
                                  "Login",
                                ),
                              ),
                            ],
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
      ),
    );
  }
}