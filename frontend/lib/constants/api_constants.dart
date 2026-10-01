import 'package:flutter/foundation.dart';

/// Constantes de configuração de rede da API.
class ApiConstants {
  /// Permite sobrescrever a URL base via `--dart-define=API_URL=http://...`
  static const String _customUrl = String.fromEnvironment('API_URL', defaultValue: '');

  /// Retorna a URL base adequada ao ambiente de execução:
  /// - Web / Desktop / iOS Simulator: `http://localhost:8000`
  /// - Emulador Android: `http://10.0.2.2:8000` (ponte para o localhost da máquina host)
  static String get baseUrl {
    if (_customUrl.isNotEmpty) {
      return _customUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
