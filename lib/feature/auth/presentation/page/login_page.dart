import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
            const SizedBox(height: Dimens.spacing12),
            OutlinedButton.icon(
              onPressed: () => _socialLogin(context, provider: 'google'),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Google'),
            ),
            const SizedBox(height: Dimens.spacing8),
            OutlinedButton.icon(
              onPressed: () => _socialLogin(context, provider: 'apple'),
              icon: const Icon(Icons.apple, size: 28),
              label: const Text('Apple'),
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

  Future<void> _socialLogin(
    BuildContext context, {
    required String provider,
  }) async {
    if (provider == 'google') {
      await _signInWithGoogle(context);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In em breve')),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    debugPrint('[GoogleBFF] _signInWithGoogle: iniciando fluxo');
    final env = ApplicationContainer.resolve<Environment>();
    debugPrint('[GoogleBFF] apiUrl=${env.apiUrl}  googleWebClientId=${env.googleWebClientId.isEmpty ? '<vazio>' : env.googleWebClientId}');
    final googleSignIn = GoogleSignIn(
      serverClientId: env.googleWebClientId.isNotEmpty
          ? env.googleWebClientId
          : null,
    );
    try {
      debugPrint('[GoogleBFF] chamando googleSignIn.signIn()...');
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        debugPrint('[GoogleBFF] usuário cancelou o Google Sign-In');
        return;
      }
      debugPrint('[GoogleBFF] conta obtida: ${account.email}');
      final auth = await account.authentication;
      final idToken = auth.idToken;
      debugPrint('[GoogleBFF] idToken ${idToken == null ? 'é NULL' : 'obtido (${idToken.length} chars)'}');
      if (idToken == null || !context.mounted) return;
      debugPrint('[GoogleBFF] disparando LoginSocialSubmitted ao Bloc');
      context.read<LoginBloc>().add(
            LoginSocialSubmitted(provider: 'google', idToken: idToken),
          );
    } catch (e, st) {
      debugPrint('[GoogleBFF] ERRO em _signInWithGoogle: $e\n$st');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao iniciar Google Sign-In')),
      );
    }
  }
}
