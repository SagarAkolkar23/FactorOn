import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/provider/authProvider.dart';
import 'package:frontend/widgets/mainButton.dart';
import 'package:frontend/widgets/textField.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // Watch auth state
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      // If login successful → navigate
      if (next is AsyncData && next.value != null) {
        final role = next.value!.role;

        if (role == "operator") {
          context.go("/operatorHome");
        } else {
          context.go("/supervisorHome");
        }
      }

      // If error → show snackbar
      if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              label: "Email",
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Password",
              controller: passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 24),

            /// Button reacts automatically to loading state
            AppButton(
              text: "Login",
              isLoading: authState is AsyncLoading,
              onPressed: () {
                ref
                    .read(authProvider.notifier)
                    .login(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
              },
            ),
            TextButton(onPressed: () { context.go("/register"); }, 
            child: Text("Don't have an account?")
            ),
          ],
        ),
      ),
    );
  }
}
