import 'dart:convert';
import 'dart:io';

import 'package:cetele/core/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalAuthTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  LocalAuthTestBinding();
  late HttpServer server;
  late List<Map<String, dynamic>> tokenRequests;
  String? linkError;

  Map<String, dynamic> session(String id, bool anonymous) => {
    'access_token': 'test-token',
    'refresh_token': 'test-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': id,
      'aud': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00Z',
      'is_anonymous': anonymous,
    },
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tokenRequests = [];
    linkError = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path.endsWith('/signup')) {
        request.response.write(jsonEncode(session('guest', true)));
      } else if (request.uri.path.endsWith('/token')) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        tokenRequests.add(data);
        if (data['link_identity'] == true && linkError != null) {
          request.response.statusCode = 422;
          request.response.write(
            jsonEncode({'error_code': linkError, 'msg': 'Test auth error'}),
          );
        } else {
          request.response.write(
            jsonEncode(
              session(
                data['link_identity'] == true ? 'guest' : 'existing',
                false,
              ),
            ),
          );
        }
      } else {
        request.response.write('{}');
      }
      await request.response.close();
    });
    await Supabase.initialize(
      url: 'http://127.0.0.1:${server.port}',
      publishableKey: 'test-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  tearDown(() async {
    await Supabase.instance.dispose();
    await server.close(force: true);
  });

  Future<bool> signIn(Future<bool> Function() confirm) =>
      SupabaseService.completeProviderSignIn(
        provider: OAuthProvider.google,
        idToken: 'provider-token',
        accessToken: 'provider-access',
        confirmExistingAccount: confirm,
      );

  test('native sign-in without a session does not try linking', () async {
    expect(await signIn(() async => fail('Unexpected confirmation')), isTrue);
    expect(tokenRequests.single['link_identity'], isNot(true));
    expect(SupabaseService.currentUser?.id, 'existing');
  });

  test(
    'anonymous upgrade retains user id and does not plain-sign-in',
    () async {
      await SupabaseService.ensureSession();
      expect(await signIn(() async => fail('Unexpected confirmation')), isTrue);
      expect(tokenRequests.single['link_identity'], isTrue);
      expect(SupabaseService.currentUser?.id, 'guest');
      expect(SupabaseService.isAnonymous, isFalse);
    },
  );

  test(
    'declining an identity conflict preserves the anonymous session',
    () async {
      await SupabaseService.ensureSession();
      linkError = 'identity_already_exists';
      expect(await signIn(() async => false), isFalse);
      expect(tokenRequests, hasLength(1));
      expect(SupabaseService.currentUser?.id, 'guest');
      expect(SupabaseService.isAnonymous, isTrue);
    },
  );

  test(
    'identity conflict requires confirmation before plain sign-in',
    () async {
      await SupabaseService.ensureSession();
      linkError = 'identity_already_exists';
      expect(
        await signIn(() async {
          expect(tokenRequests, hasLength(1));
          expect(SupabaseService.currentUser?.id, 'guest');
          return true;
        }),
        isTrue,
      );
      expect(tokenRequests, hasLength(2));
      expect(tokenRequests.last['link_identity'], isNot(true));
      expect(SupabaseService.currentUser?.id, 'existing');
    },
  );

  test(
    'unrelated linking errors never trigger fallback or confirmation',
    () async {
      await SupabaseService.ensureSession();
      linkError = 'manual_linking_disabled';
      await expectLater(
        signIn(() async => fail('Unexpected confirmation')),
        throwsA(isA<AuthException>()),
      );
      expect(tokenRequests, hasLength(1));
      expect(SupabaseService.currentUser?.id, 'guest');
    },
  );
}
