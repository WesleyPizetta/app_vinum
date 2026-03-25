abstract class Environment {
  final bool isProduction;
  final String apiUrl;
  final String name;
  final String googleWebClientId;

  Environment({
    required this.isProduction,
    required this.apiUrl,
    required this.name,
    required this.googleWebClientId,
  });
}
