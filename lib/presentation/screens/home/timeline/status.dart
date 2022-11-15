import 'package:boorusphere/data/repository/booru/entity/booru_error.dart';
import 'package:boorusphere/presentation/i18n/strings.g.dart';
import 'package:boorusphere/presentation/provider/booru/page_state_producer.dart';
import 'package:boorusphere/presentation/provider/settings/server/server_settings.dart';
import 'package:boorusphere/presentation/widgets/error_info.dart';
import 'package:boorusphere/presentation/widgets/notice_card.dart';
import 'package:boorusphere/utils/extensions/buildcontext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TimelineStatus extends ConsumerWidget {
  const TimelineStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverActive = ref.watch(ServerSettingsProvider.active);

    final pageState = ref.watch(pageStateProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        pageState.when(
          data: (data) {
            return Container(
              height: 50,
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(pageStateProvider.notifier).loadMore(),
                child: Text(t.loadMore),
              ),
            );
          },
          loading: (data) {
            return Container(
              height: 50,
              alignment: Alignment.topCenter,
              child: SpinKitFoldingCube(
                size: 24,
                color: context.colorScheme.primary,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          error: (data, error, stackTrace, code) {
            final query = data.option.query;
            final size = data.posts.length;
            return Center(
              child: NoticeCard(
                icon: const Icon(Icons.search),
                margin: const EdgeInsets.all(16),
                children: Column(
                  children: [
                    if (error == BooruError.httpError)
                      ErrorInfo(
                        error: t.pageStatus.httpError(
                          n: code,
                          serverName: serverActive.name,
                        ),
                      )
                    else if (error == BooruError.empty)
                      ErrorInfo(
                        error: query.isEmpty
                            ? t.pageStatus.noResult(n: size)
                            : t.pageStatus
                                .noResultForQuery(n: size, query: query),
                      )
                    else if (error == BooruError.noParser)
                      ErrorInfo(
                        error: t.pageStatus
                            .noParser(serverName: serverActive.name),
                      )
                    else
                      ErrorInfo(error: error, stackTrace: stackTrace),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (error == BooruError.empty && data.option.safeMode)
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .watch(
                                      ServerSettingsProvider.safeMode.notifier)
                                  .update(false)
                                  .then((value) => ref
                                      .read(pageStateProvider.notifier)
                                      .load());
                            },
                            style: ElevatedButton.styleFrom(elevation: 0),
                            child: Text(t.disableSafeMode),
                          ),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(pageStateProvider.notifier).load(),
                          style: ElevatedButton.styleFrom(elevation: 0),
                          child: Text(t.retry),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
