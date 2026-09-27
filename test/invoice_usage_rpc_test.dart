import 'dart:convert';
import 'dart:io';

import 'package:cetele/features/invoices/data/invoices_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late List<({String path, String method, String body, String query})> requests;
  Object response = 4;
  int statusCode = 200;

  setUp(() async {
    response = 4;
    statusCode = 200;
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add((
        path: request.uri.path,
        method: request.method,
        body: await utf8.decoder.bind(request).join(),
        query: request.uri.query,
      ));
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('monthly count uses one RPC without user or date parameters', () async {
    expect(await InvoicesRepository(client).countMonthlySalesInvoices(), 4);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/rest/v1/rpc/count_monthly_sales_invoices');
    expect(request.query, isEmpty);
    expect(jsonDecode(request.body), isNull);
  });

  test('failed count does not silently become zero usage', () async {
    statusCode = 403;
    response = {'code': '42501', 'message': 'Oturum gerekli'};
    await expectLater(
      InvoicesRepository(client).countMonthlySalesInvoices(),
      throwsA(isA<PostgrestException>()),
    );
  });

  test('malformed server count is rejected', () async {
    response = -1;
    await expectLater(
      InvoicesRepository(client).countMonthlySalesInvoices(),
      throwsStateError,
    );
  });
}
