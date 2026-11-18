import 'package:badalaty/updates/github_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final metadata = {
    'package': 'com.amwolfstein.badalaty',
    'version': '1.0.4',
    'build': 5,
    'sha256': 'a' * 64,
    'notes': {'en': 'New update screen', 'ar': 'شاشة تحديثات جديدة'},
  };

  test('build numbers control upgrades and APK stays on the Badalaty feed', () {
    final release = GithubRelease.fromJson(metadata);
    expect(release.isNewerThan(4), isTrue);
    expect(release.isNewerThan(5), isFalse);
    expect(release.isNewerThan(6), isFalse);
    expect(release.notes['ar'], 'شاشة تحديثات جديدة');
    expect(
      release.apk.toString(),
      'https://raw.githubusercontent.com/AMWolfstein/Badalaty/android-preview/artifacts/Badalaty-1.0.4-arm64.apk',
    );
  });

  test('rejects a mismatched package, unsafe path, or incomplete metadata', () {
    for (final invalid in [
      {'package': 'com.badalaty.badalaty'},
      {'version': '../release'},
      {'build': '5'},
      {'build': 0},
      {'sha256': 'wrong'},
    ]) {
      expect(
        () => GithubRelease.fromJson({...metadata, ...invalid}),
        throwsFormatException,
      );
    }
  });
}
