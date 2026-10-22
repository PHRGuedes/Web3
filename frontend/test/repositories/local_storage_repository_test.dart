import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/repositories/local_storage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageRepository Unit Tests', () {
    test('Salva, obtém, verifica e remove token com SharedPreferences mockado', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalStorageRepository();

      expect(await repository.possuiToken(), isFalse);
      expect(await repository.obterToken(), isNull);

      await repository.salvarToken('jwt_mock_token_abc');
      expect(await repository.possuiToken(), isTrue);
      expect(await repository.obterToken(), 'jwt_mock_token_abc');

      await repository.removerToken();
      expect(await repository.possuiToken(), isFalse);
      expect(await repository.obterToken(), isNull);
    });

    test('Inicia com token pré-existente nos valores mockados', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageRepository.keyToken: 'token_pre_existente',
      });
      final repository = LocalStorageRepository();

      expect(await repository.possuiToken(), isTrue);
      expect(await repository.obterToken(), 'token_pre_existente');
    });
  });
}
