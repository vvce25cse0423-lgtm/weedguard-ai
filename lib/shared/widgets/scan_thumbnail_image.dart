import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
    final raw = widget.imageUrl;
    if (raw != null && raw.isNotEmpty && !raw.startsWith('http')) {
      final clean = raw.replaceFirst(RegExp(r'^file://'), '');
      final direct = File(clean);
      if (direct.existsSync()) {
        _resolvedFile = direct;
      }
    }
    _tryResolveImage();
  }

  @override
  void didUpdateWidget(ScanThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.createdAt != widget.createdAt) {
      final raw = widget.imageUrl;
      if (raw != null && raw.isNotEmpty && !raw.startsWith('http')) {
        final clean = raw.replaceFirst(RegExp(r'^file://'), '');
        final direct = File(clean);
        if (direct.existsSync()) {
          _resolvedFile = direct;
        }
      }
      _tryResolveImage();
    }
  }

  Future<void> _tryResolveImage() async {
    final raw = widget.imageUrl;

    // Fast-path: Synchronous local file check
    if (raw != null && raw.isNotEmpty && !raw.startsWith('http')) {
      final clean = raw.replaceFirst(RegExp(r'^file://'), '');
      final directFile = File(clean);
      if (directFile.existsSync()) {
        if (mounted) {
          setState(() {
            _resolvedFile = directFile;
          });
        }
        return;
      }
    }

    // Async-path: Search scans folder or match by createdAt
    if (_isCheckingDisk) return;
    _isCheckingDisk = true;

    try {
      final found = await resolveScanFile(raw, widget.createdAt);
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
    Widget content;

    if (_resolvedFile != null && _resolvedFile!.existsSync()) {
      content = Image.file(
        _resolvedFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: (widget.width != null && widget.width!.isFinite)
            ? (widget.width! * 2.5).round()
            : null,
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
        cacheWidth: (widget.width != null && widget.width!.isFinite)
            ? (widget.width! * 2.5).round()
            : null,
        errorBuilder: (_, __, ___) {
          // If network 404s (e.g. Supabase bucket missing), display resolved file or placeholder
          if (_resolvedFile != null && _resolvedFile!.existsSync()) {
            return Image.file(
              _resolvedFile!,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              cacheWidth: (widget.width != null && widget.width!.isFinite)
                  ? (widget.width! * 2.5).round()
                  : null,
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
    if (rawPath != null && rawPath.isNotEmpty && !rawPath.startsWith('http')) {
      final clean = rawPath.replaceFirst(RegExp(r'^file://'), '');
      final f = File(clean);
      if (f.existsSync()) return f;

      // Extract filename and check standard app directories
      final parts = clean.split(RegExp(r'[/\\]'));
      final filename = parts.isNotEmpty ? parts.last : '';
      if (filename.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final inScans = File('${appDir.path}/scans/$filename');
        if (inScans.existsSync()) return inScans;

        final inRoot = File('${appDir.path}/$filename');
        if (inRoot.existsSync()) return inRoot;

        final tempDir = await getTemporaryDirectory();
        final inTemp = File('${tempDir.path}/$filename');
        if (inTemp.existsSync()) return inTemp;
      }
    }

    // 2. Scan documents directory scans folder + temporary directory
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();
    final candidateDirs = [
      Directory('${appDir.path}/scans'),
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

    if (createdAt != null) {
      final targetMs = createdAt.millisecondsSinceEpoch;
      File? bestMatch;
      int minDiff = 86400000; // 24 hours max threshold

      for (final f in files) {
        final name = f.path.split(RegExp(r'[/\\]')).last;
        // Check if filename contains timestamp: scan_1728848800000.jpg
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
