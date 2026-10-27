import 'package:flutter_test/flutter_test.dart';
import 'package:directorio_usuarios/models/user_model.dart';
import 'package:directorio_usuarios/models/post_model.dart';
import 'package:directorio_usuarios/services/api_service.dart';

void main() {
  group('Modelos de Datos Tests', () {
    test('UserModel mapea correctamente JSON anidado de JSONPlaceholder', () {
      final json = {
        'id': 1,
        'name': 'Leanne Graham',
        'username': 'Bret',
        'email': 'Sincere@april.biz',
        'phone': '1-770-736-8031 x56442',
        'website': 'hildegard.org',
        'company': {
          'name': 'Romaguera-Crona',
          'catchPhrase': 'Multi-layered client-server neural-net',
          'bs': 'harness real-time e-markets'
        }
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'Leanne Graham');
      expect(user.username, 'Bret');
      expect(user.email, 'Sincere@april.biz');
      expect(user.companyName, 'Romaguera-Crona');
    });

    test('UserModel soporta mapa plano de SQLite bidireccionalmente', () {
      final sqliteMap = {
        'id': 2,
        'name': 'Ervin Howell',
        'username': 'Antonette',
        'email': 'Shanna@melissa.tv',
        'phone': '010-692-6593 x09125',
        'website': 'anastasia.net',
        'companyName': 'Deckow-Crist',
      };

      final user = UserModel.fromMap(sqliteMap);
      expect(user.companyName, 'Deckow-Crist');

      final toMapResult = user.toMap();
      expect(toMapResult['companyName'], 'Deckow-Crist');
      expect(toMapResult['name'], 'Ervin Howell');
    });

    test('PostModel mapea campos correctamente', () {
      final json = {
        'userId': 1,
        'id': 101,
        'title': 'Test Title',
        'body': 'Test Body Content'
      };

      final post = PostModel.fromJson(json);
      expect(post.id, 101);
      expect(post.userId, 1);
      expect(post.title, 'Test Title');
      expect(post.body, 'Test Body Content');
    });
  });

  group('ApiService Simulation Tests', () {
    test('Lanza NoInternetException en modo offline simulado', () async {
      final apiService = ApiService(simulationMode: NetworkSimulationMode.offline);
      expect(() => apiService.fetchUsers(), throwsException);
    });
  });
}
