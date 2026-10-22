import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

String? normalizeLocalPath(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return null;
  var p = raw.trim();
  try {
    final uri = Uri.tryParse(p);
    if (uri != null && uri.scheme == 'file') {
      p = uri.toFilePath();
    }
  } catch (_) {}
  p = p.replaceFirst(RegExp(r'^file://'), '');
  if (Platform.isWindows && p.startsWith('/') && p.length > 2 && p[2] == ':') {
    p = p.substring(1);
  }
  return p;
}

class ScanThumbnailImage extends StatefulWidget {
  final String? imageUrl;
  final DateTime? createdAt;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final IconData defaultIcon;

  const ScanThumbnailImage({
    super.key,
    this.imageUrl,
    this.createdAt,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.defaultIcon = Icons.photo_camera_rounded,
  });

  @override
  State<ScanThumbnailImage> createState() => _ScanThumbnailImageState();
}

class _ScanThumbnailImageState extends State<ScanThumbnailImage> {
  File? _resolvedFile;
  bool _isCheckingDisk = false;

  @override
  void initState() {
    super.initState();
    _checkInitial();
  }

  void _checkInitial() {
    final direct = _checkDirectFile(widget.imageUrl);
    if (direct != null) {
      _resolvedFile = direct;
    }
    _tryResolveImage();
  }

  @override
  void didUpdateWidget(ScanThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.createdAt != widget.createdAt) {
      final direct = _checkDirectFile(widget.imageUrl);
      if (direct != null) {
        _resolvedFile = direct;
      }
      _tryResolveImage();
    }
  }

  File? _checkDirectFile(String? raw) {
    final clean = normalizeLocalPath(raw);
    if (clean != null && clean.isNotEmpty) {
      try {
        final f = File(clean);
        if (f.existsSync()) return f;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _tryResolveImage() async {
    final direct = _checkDirectFile(widget.imageUrl);
    if (direct != null) {
      if (mounted && _resolvedFile?.path != direct.path) {
        setState(() => _resolvedFile = direct);
      }
      return;
    }

    if (_isCheckingDisk) return;
    _isCheckingDisk = true;

    try {
      final found = await resolveScanFile(widget.imageUrl, widget.createdAt);
      if (mounted && found != null) {
        setState(() {
          _resolvedFile = found;
        });
      }
    } catch (_) {
      // Ignored
    } finally {
      _isCheckingDisk = false;
    }
  }

  Widget _buildPlaceholder() {
    return widget.fallback ??
        Center(
          child: Icon(
            widget.defaultIcon,
            color: const Color(0xFF2D6A4F),
            size: (widget.width != null && widget.width!.isFinite)
                ? (widget.width! * 0.48).clamp(16.0, 36.0)
                : 24.0,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final direct = _checkDirectFile(widget.imageUrl);
    final activeFile = direct ?? _resolvedFile;

    Widget content;
    if (activeFile != null && activeFile.existsSync()) {
      content = Image.file(
        activeFile,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else if (widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty &&
        widget.imageUrl!.startsWith('http')) {
      content = Image.network(
        widget.imageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) {
          if (_resolvedFile != null && _resolvedFile!.existsSync()) {
            return Image.file(
              _resolvedFile!,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            );
          }
          return _buildPlaceholder();
        },
      );
    } else {
      content = _buildPlaceholder();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFFE8F5E9),
          child: content,
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFE8F5E9),
      child: content,
    );
  }
}

/// Helper method to locate a scan image on device storage
Future<File?> resolveScanFile(String? rawPath, DateTime? createdAt) async {
  try {
    // 1. Direct path check
    final direct = normalizeLocalPath(rawPath);
    if (direct != null && direct.isNotEmpty) {
      final f = File(direct);
      if (f.existsSync()) return f;
    }

    // Extract filename if available
    String? targetFilename;
    if (rawPath != null && rawPath.isNotEmpty) {
      if (rawPath.startsWith('http')) {
        try {
          final uri = Uri.tryParse(rawPath);
          if (uri != null && uri.pathSegments.isNotEmpty) {
            targetFilename = uri.pathSegments.last;
          }
        } catch (_) {}
      } else {
        final clean = normalizeLocalPath(rawPath) ?? rawPath;
        final parts = clean.split(RegExp(r'[/\\]'));
        if (parts.isNotEmpty) targetFilename = parts.last;
      }
    }

    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();

    if (targetFilename != null && targetFilename.isNotEmpty) {
      final inScans = File('${appDir.path}/scans/$targetFilename');
      if (inScans.existsSync()) return inScans;

      final inRoot = File('${appDir.path}/$targetFilename');
      if (inRoot.existsSync()) return inRoot;

      final inTempScans = File('${tempDir.path}/scans/$targetFilename');
      if (inTempScans.existsSync()) return inTempScans;

      final inTemp = File('${tempDir.path}/$targetFilename');
      if (inTemp.existsSync()) return inTemp;
    }

    // 2. Scan candidate directories
    final candidateDirs = [
      Directory('${appDir.path}/scans'),
      Directory('${tempDir.path}/scans'),
      appDir,
      tempDir,
    ];

    final files = <File>[];
    for (final dir in candidateDirs) {
      if (dir.existsSync()) {
        try {
          files.addAll(
            dir
                .listSync()
                .whereType<File>()
                .where((f) =>
                    f.path.toLowerCase().endsWith('.jpg') ||
                    f.path.toLowerCase().endsWith('.jpeg') ||
                    f.path.toLowerCase().endsWith('.png')),
          );
        } catch (_) {}
      }
    }

    if (files.isEmpty) return null;

    // Check if any file matches targetFilename
    if (targetFilename != null && targetFilename.isNotEmpty) {
      final cleanTarget = targetFilename.toLowerCase();
      for (final f in files) {
        final fname = f.path.split(RegExp(r'[/\\]')).last.toLowerCase();
        if (fname == cleanTarget || fname.contains(cleanTarget)) {
          return f;
        }
      }
    }

    if (createdAt != null) {
      final targetMs = createdAt.millisecondsSinceEpoch;
      File? bestMatch;
      int minDiff = 86400000; // 24 hours max threshold

      for (final f in files) {
        final name = f.path.split(RegExp(r'[/\\]')).last;
        final match = RegExp(r'scan_(\d+)').firstMatch(name);
        int fileMs = 0;
        if (match != null) {
          fileMs = int.tryParse(match.group(1) ?? '') ?? 0;
        } else {
          try {
            fileMs = f.lastModifiedSync().millisecondsSinceEpoch;
          } catch (_) {}
        }

        if (fileMs > 0) {
          final diff = (fileMs - targetMs).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestMatch = f;
          }
        }
      }

      if (bestMatch != null) return bestMatch;
    }

    // Default to the most recent scan image on disk
    files.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });
    return files.first;
  } catch (_) {
    return null;
  }
}
