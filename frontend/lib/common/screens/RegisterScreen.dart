import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/provider/authProvider.dart';
import 'package:frontend/widgets/mainButton.dart';
import 'package:frontend/widgets/textField.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = "operator";

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECT: ref is available automatically
    final authState = ref.watch(authProvider);

    // Listen for side-effects (navigation, snackbar)
    ref.listen(authProvider, (previous, next) {
      if (next is AsyncData && next.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful")),
        );
        context.go("/login");
      }

      if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(label: "Email", controller: emailController),
            const SizedBox(height: 12),
            AppTextField(
              label: "Password",
              controller: passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Select Role",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "operator", child: Text("Operator")),
                DropdownMenuItem(
                  value: "supervisor",
                  child: Text("Supervisor"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            const SizedBox(height: 24),

            AppButton(
              text: "Register",
              isLoading: authState is AsyncLoading,
              onPressed: () {
                ref
                    .read(authProvider.notifier)
                    .register(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      role: selectedRole,
                    );
              },
            ),

            TextButton(
              onPressed: () => context.go("/login"),
              child: const Text("Already have an account?"),
            ),
          ],
        ),
      ),
    );
  }
}
