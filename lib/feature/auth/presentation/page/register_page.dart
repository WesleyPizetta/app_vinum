import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<RegisterBloc>(),
      child: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              ApplicationRoute.login,
              (_) => false,
            );
          }
        },
        child: Scaffold(
          appBar: VinumAppBar(
            title: getString(context, 'register_title'),
            showBackButton: true,
          ),
          body: const SafeArea(child: _RegisterForm()),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
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
            const SizedBox(height: Dimens.spacing24),
            Text(
              getString(context, 'register_subtitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: Dimens.spacing32),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: getString(context, 'name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return getString(context, 'auth_error_name_required');
                }
                return null;
              },
            ),
            const SizedBox(height: Dimens.spacing16),
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
                if (value.length < 6) {
                  return getString(context, 'auth_error_weak_password');
                }
                return null;
              },
            ),
            const SizedBox(height: Dimens.spacing8),
            BlocBuilder<RegisterBloc, RegisterState>(
              builder: (context, state) {
                if (state is RegisterError) {
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
            BlocBuilder<RegisterBloc, RegisterState>(
              builder: (context, state) => PrimaryButton(
                text: getString(context, 'register'),
                isLoading: state is RegisterLoading,
                onPressed: () => _submit(context),
              ),
            ),
            const SizedBox(height: Dimens.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  getString(context, 'auth_has_account'),
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(getString(context, 'login')),
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
    context.read<RegisterBloc>().add(
          RegisterSubmitted(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }
}
