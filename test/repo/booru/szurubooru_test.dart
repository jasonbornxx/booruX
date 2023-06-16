import 'package:boorusphere/data/provider.dart';
import 'package:boorusphere/data/repository/booru/entity/page_option.dart';
import 'package:boorusphere/data/repository/booru/parser/szurubooru_json_parser.dart';
import 'package:boorusphere/data/repository/server/entity/server.dart';
import 'package:boorusphere/data/repository/server/user_server_repo.dart';
import 'package:boorusphere/domain/provider.dart';
import 'package:boorusphere/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../presentation/state/app_version_test.dart';
import '../../utils/dio.dart';
import '../../utils/hive.dart';
import '../../utils/mocktail.dart';
import '../../utils/riverpod.dart';

void main() async {
  setupLogger(test: true);
  setupMocktailFallbacks();
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Szurubooru', () async {
    final ref = ProviderContainer(overrides: [
      defaultServersProvider.overrideWithValue(await provideDefaultServers()),
      envRepoProvider.overrideWithValue(FakeEnvRepo()),
    ]);

    initializeTestHive();
    addTearDown(() async {
      await destroyTestHive();
      ref.dispose();
    });

    await UserServerRepo.prepare();
    ref.setupTestFor(dioProvider);
    final adapter = DioAdapterMock(ref.read(dioProvider));

    final parser = SzurubooruJsonParser();
    final server = Server(
        homepage: 'https://homestuck.net/resources/booru',
        searchUrl: parser.searchQuery,
        tagSuggestionUrl: parser.suggestionQuery);

    const option = PageOption(limit: 5);

    const fakePage = 'szurubooru/posts.json';
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => FakeResponseBody.fromFakeData(fakePage, 200));

    expect(
      await ref.read(imageboardRepoProvider(server)).getPage(option, 1),
      isA<Iterable>().having((x) => x.length, 'total', option.limit - 2),
      reason: 'expecting 2 invalid post',
    );

    const fakeTags = 'szurubooru/tags.json';
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => FakeResponseBody.fromFakeData(fakeTags, 403));

    await expectLater(
      ref.read(imageboardRepoProvider(server)).getSuggestion('book'),
      throwsA(isA<DioException>()),
      reason: 'expecting error because not logged in',
    );

    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => FakeResponseBody.fromFakeData(fakeTags, 200));

    expect(
      await ref.read(imageboardRepoProvider(server)).getSuggestion('book'),
      isA<Iterable>().having((x) => x.length, 'total', 4 - 1),
      reason: 'expecting 4 result with 1 tags having zero post_count',
    );
  });
}
