import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('badalaty/updates');
const _feed =
    'https://raw.githubusercontent.com/AMWolfstein/Badalaty/android-preview/artifacts';
const _timeout = Duration(seconds: 20);

class GithubRelease {
  const GithubRelease._(this.version, this.build, this.digest, this.notes);

  final String version;
  final int build;
  final String digest;
  final Map<String, String> notes;

  static const _package = 'com.amwolfstein.badalaty';

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final build = json['build'];
    final digest = json['sha256'];
    if (json['package'] != _package ||
        version is! String ||
        !RegExp(r'^[0-9]{1,4}(\.[0-9]{1,4}){2}$').hasMatch(version) ||
        build is! int ||
        build < 1 ||
        digest is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
      throw const FormatException('Invalid Badalaty update metadata');
    }
    final notes = json['notes'];
    return GithubRelease._(version, build, digest, {
      for (final language in ['en', 'ar'])
        if (notes is Map && notes[language] is String)
          language: notes[language] as String,
    });
  }

  Uri get apk => Uri.parse('$_feed/Badalaty-$version-arm64.apk');
  bool isNewerThan(int installedBuild) => build > installedBuild;
}

typedef UpdateCheck = ({
  String installed,
  GithubRelease? release,
  bool supported,
});

class GithubUpdates {
  Future<UpdateCheck> check() async {
    final installed = (await _channel.invokeMapMethod<String, Object?>(
      'version',
    ))!;
    final version = installed['version'] as String;
    if (installed['arm64'] != true) {
      return (installed: version, release: null, supported: false);
    }
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final response = await _get(client, Uri.parse('$_feed/latest.json'));
      final bytes = <int>[];
      await for (final chunk in response.timeout(_timeout)) {
        if (bytes.length + chunk.length > 16 * 1024) {
          throw const FormatException('Update metadata is too large');
        }
        bytes.addAll(chunk);
      }
      final release = GithubRelease.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
      return (
        installed: version,
        release: release.isNewerThan(installed['build'] as int)
            ? release
            : null,
        supported: true,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> download(
    GithubRelease release,
    void Function(double?) onProgress,
  ) async {
    final temporary = await getTemporaryDirectory();
    final directory = Directory('${temporary.path}/app-updates');
    await directory.create(recursive: true);
    final partial = File('${directory.path}/badalaty.part');
    const maxBytes = 80 * 1024 * 1024;
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final response = await _get(client, release.apk);
      final length = response.contentLength;
      if (length > maxBytes) throw const FormatException('APK is too large');
      var received = 0;
      var lastPercent = -1;
      final output = partial.openWrite();
      try {
        await output.addStream(
          response.timeout(_timeout).map((chunk) {
            received += chunk.length;
            if (received > maxBytes) {
              throw const FormatException('APK is too large');
            }
            if (length > 0) {
              final percent = received * 100 ~/ length;
              if (percent != lastPercent) {
                lastPercent = percent;
                onProgress((received / length).clamp(0.0, 1.0));
              }
            }
            return chunk;
          }),
        );
      } finally {
        await output.close();
      }
      final digest = await sha256.bind(partial.openRead()).first;
      if (digest.toString() != release.digest) {
        throw const FormatException('APK checksum mismatch');
      }
      await partial.rename('${directory.path}/badalaty.apk');
    } finally {
      client.close(force: true);
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<bool> install(GithubRelease release) async =>
      await _channel.invokeMethod<String>('install', release.build) ==
      'installer';

  Future<HttpClientResponse> _get(HttpClient client, Uri url) async {
    final request = await client.getUrl(url).timeout(_timeout);
    request.followRedirects = false;
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub returned ${response.statusCode}', uri: url);
    }
    return response;
  }
}
