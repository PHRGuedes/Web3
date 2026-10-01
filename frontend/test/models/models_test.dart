import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/usuario.dart';
import '../../lib/models/auth_token.dart';
import '../../lib/models/login_request.dart';
import '../../lib/models/cadastro_request.dart';

void main() {
  group('Models Unit Tests', () {
    test('Usuario model serializa e deserializa corretamente (fromJson / toJson)', () {
      final json = {
        'id': 1,
        'nome': 'Ana Ribeiro',
        'email': 'ana.ribeiro@reqflow.com',
        'created_at': '2026-10-01T12:00:00.000Z',
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.id, 1);
      expect(usuario.nome, 'Ana Ribeiro');
      expect(usuario.email, 'ana.ribeiro@reqflow.com');
      expect(usuario.createdAt, isNotNull);

      final outputJson = usuario.toJson();
      expect(outputJson['id'], 1);
      expect(outputJson['nome'], 'Ana Ribeiro');
      expect(outputJson['email'], 'ana.ribeiro@reqflow.com');
      expect(outputJson['created_at'], contains('2026-10-01'));
    });

    test('AuthToken model deserializa corretamente e exporta toJson', () {
      final json = {
        'access_token': 'jwt_secret_token_12345',
        'token_type': 'bearer',
      };

      final token = AuthToken.fromJson(json);
      expect(token.accessToken, 'jwt_secret_token_12345');
      expect(token.tokenType, 'bearer');

      final outputJson = token.toJson();
      expect(outputJson['access_token'], 'jwt_secret_token_12345');
      expect(outputJson['token_type'], 'bearer');
    });

    test('LoginRequest gera JSON correto', () {
      const request = LoginRequest(
        email: 'ana.ribeiro@reqflow.com',
        senha: 'senhaSuperSegura123',
      );

      final json = request.toJson();
      expect(json['email'], 'ana.ribeiro@reqflow.com');
      expect(json['senha'], 'senhaSuperSegura123');

      final deserialized = LoginRequest.fromJson(json);
      expect(deserialized.email, request.email);
      expect(deserialized.senha, request.senha);
    });

    test('CadastroRequest gera JSON correto', () {
      const request = CadastroRequest(
        nome: 'Carlos Mendes',
        email: 'carlos@reqflow.com',
        senha: 'senhaForte456',
      );

      final json = request.toJson();
      expect(json['nome'], 'Carlos Mendes');
      expect(json['email'], 'carlos@reqflow.com');
      expect(json['senha'], 'senhaForte456');

      final deserialized = CadastroRequest.fromJson(json);
      expect(deserialized.nome, request.nome);
      expect(deserialized.email, request.email);
    });
  });
}
