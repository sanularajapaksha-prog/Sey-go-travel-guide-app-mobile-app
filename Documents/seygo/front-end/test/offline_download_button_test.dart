import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seygo_travel_app/data/models/offline_cache_item.dart';
import 'package:seygo_travel_app/providers/offline_provider.dart';
import 'package:seygo_travel_app/widgets/offline_download_button.dart';
import 'package:sizer/sizer.dart';

/// Wraps a widget in the required providers, Sizer, and MaterialApp.
/// Sizer must be in the tree because OfflineDownloadButton uses .h / .w.
Widget _wrap(Widget child, {OfflineProvider? provider}) {
  return ChangeNotifierProvider<OfflineProvider>.value(
    value: provider ?? OfflineProvider(),
    child: Sizer(
      builder: (context, orientation, deviceType) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

OfflineCacheItem _item(String id) => OfflineCacheItem(
      id: id,
      type: OfflineCacheType.destination,
      title: 'Test Place',
      savedAt: DateTime(2025, 1, 1),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OfflineDownloadButton — idle state (not cached)', () {
    testWidgets('shows "Save Offline" text', (tester) async {
      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'uncached',
          onBuild: () async => _item('uncached'),
        ),
      ));

      expect(find.text('Save Offline'), findsOneWidget);
    });

    testWidgets('shows download icon when not cached', (tester) async {
      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'uncached',
          onBuild: () async => _item('uncached'),
        ),
      ));

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });
  });

  group('OfflineDownloadButton — cached state', () {
    testWidgets('shows "Saved Offline" text when item is in provider',
        (tester) async {
      final provider = OfflineProvider();
      await provider.save(_item('cached-id'));

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'cached-id',
          onBuild: () async => _item('cached-id'),
        ),
        provider: provider,
      ));

      expect(find.text('Saved Offline'), findsOneWidget);
    });

    testWidgets('shows offline bolt icon when cached', (tester) async {
      final provider = OfflineProvider();
      await provider.save(_item('cached-id'));

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'cached-id',
          onBuild: () async => _item('cached-id'),
        ),
        provider: provider,
      ));

      expect(find.byIcon(Icons.offline_bolt_rounded), findsOneWidget);
    });
  });

  group('OfflineDownloadButton — tapping download', () {
    testWidgets('tapping idle button saves item to provider', (tester) async {
      final provider = OfflineProvider();

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'new-item',
          onBuild: () async => _item('new-item'),
        ),
        provider: provider,
      ));

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(provider.isCached('new-item'), isTrue);
      expect(find.text('Saved Offline'), findsOneWidget);
    });

    testWidgets('tapping cached button removes item from provider',
        (tester) async {
      final provider = OfflineProvider();
      await provider.save(_item('remove-me'));

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'remove-me',
          onBuild: () async => _item('remove-me'),
        ),
        provider: provider,
      ));

      // Starts as cached → "Saved Offline"
      expect(find.text('Saved Offline'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(provider.isCached('remove-me'), isFalse);
      expect(find.text('Save Offline'), findsOneWidget);
    });
  });

  group('OfflineDownloadButton — error state', () {
    testWidgets('shows "Retry Download" when onBuild returns null',
        (tester) async {
      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'fail-id',
          onBuild: () async => null, // simulate build failure
        ),
      ));

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(find.text('Retry Download'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('shows "Retry Download" when onBuild throws', (tester) async {
      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'throw-id',
          onBuild: () async => throw Exception('Network error'),
        ),
      ));

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(find.text('Retry Download'), findsOneWidget);
    });
  });

  group('OfflineDownloadButton — compact mode', () {
    testWidgets('compact mode renders IconButton not OutlinedButton',
        (tester) async {
      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'cmp',
          onBuild: () async => _item('cmp'),
          compact: true,
        ),
      ));

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('compact idle shows download_outlined icon', (tester) async {
      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'cmp-idle',
          onBuild: () async => _item('cmp-idle'),
          compact: true,
        ),
      ));

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('compact cached shows offline_bolt_rounded icon',
        (tester) async {
      final provider = OfflineProvider();
      await provider.save(_item('cmp-cached'));

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'cmp-cached',
          onBuild: () async => _item('cmp-cached'),
          compact: true,
        ),
        provider: provider,
      ));

      expect(find.byIcon(Icons.offline_bolt_rounded), findsOneWidget);
    });

    testWidgets('tapping compact button saves item', (tester) async {
      final provider = OfflineProvider();

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'cmp-save',
          onBuild: () async => _item('cmp-save'),
          compact: true,
        ),
        provider: provider,
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(provider.isCached('cmp-save'), isTrue);
    });

    testWidgets('compact error shows error_outline_rounded', (tester) async {
      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'cmp-err',
          onBuild: () async => null,
          compact: true,
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('OfflineDownloadButton — reactive to provider changes', () {
    testWidgets('updates to cached state when provider saves externally',
        (tester) async {
      final provider = OfflineProvider();

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'reactive-id',
          onBuild: () async => _item('reactive-id'),
        ),
        provider: provider,
      ));

      // Initially idle
      expect(find.text('Save Offline'), findsOneWidget);

      // External save
      await provider.save(_item('reactive-id'));
      await tester.pump();

      expect(find.text('Saved Offline'), findsOneWidget);
    });

    testWidgets('updates to idle when provider deletes externally',
        (tester) async {
      final provider = OfflineProvider();
      await provider.save(_item('reactive-del'));

      await tester.pumpWidget(_wrap(
        OfflineDownloadButton(
          itemId: 'reactive-del',
          onBuild: () async => _item('reactive-del'),
        ),
        provider: provider,
      ));

      expect(find.text('Saved Offline'), findsOneWidget);

      // External delete
      await provider.deleteById('reactive-del');
      await tester.pump();

      expect(find.text('Save Offline'), findsOneWidget);
    });
  });
}
