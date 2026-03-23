import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<LoginBloc>()
        ..add(LoginSessionChecked()),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              ApplicationRoute.home,
              (_) => false,
            );
          }
        },
        child: const Scaffold(
          body: SafeArea(child: _LoginForm()),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimens.spacing24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Dimens.spacing48),
            Icon(
              Icons.wine_bar,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: Dimens.spacing16),
            Text(
              getString(context, 'login_title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: Dimens.spacing8),
            Text(
              getString(context, 'login_subtitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: Dimens.spacing40),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: getString(context, 'email'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return getString(context, 'auth_error_email_required');
                }
                return null;
              },
            ),
            const SizedBox(height: Dimens.spacing16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(context),
              decoration: InputDecoration(
                labelText: getString(context, 'password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return getString(context, 'auth_error_password_required');
                }
                return null;
              },
            ),
            const SizedBox(height: Dimens.spacing8),
            BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                if (state is LoginError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: Dimens.spacing8),
                    child: Text(
                      getString(context, state.message),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: Dimens.spacing24),
            BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) => PrimaryButton(
                text: getString(context, 'login'),
                isLoading: state is LoginLoading,
                onPressed: () => _submit(context),
              ),
            ),
            const SizedBox(height: Dimens.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  getString(context, 'auth_no_account'),
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    ApplicationRoute.register,
                  ),
                  child: Text(getString(context, 'register')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }
}
