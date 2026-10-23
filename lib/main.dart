import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image_tools;

String normalizePlateText(String raw) {
  final compact = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final match = RegExp(r'^([A-Z]{2})(\d{1,2})([A-Z]{1,3})(\d{3,4})$').firstMatch(compact);
  if (match == null) return raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return '${match.group(1)} ${match.group(2)} ${match.group(3)} ${match.group(4)}';
}

bool isValidIndianPlate(String value) {
  final compact = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final regular = RegExp(r'^[A-Z]{2}\d{1,2}[A-Z]{1,3}\d{3,4}$');
  final bharat = RegExp(r'^\d{2}BH\d{4}[A-Z]{1,2}$');
  return regular.hasMatch(compact) || bharat.hasMatch(compact);
}

String? extractIndianPlate(RecognizedText recognized) {
  final candidates = recognized.blocks
      .where((block) => block.boundingBox.width / block.boundingBox.height >= 2.2)
      .map((block) => normalizePlateText(block.text))
      .where(isValidIndianPlate)
      .toList();
  return candidates.isEmpty ? null : candidates.first;
}

void main() => runApp(const TruckLoggerApp());

class TruckLoggerApp extends StatelessWidget {
  const TruckLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xff10231f);
    const teal = Color(0xff087866);
    return MaterialApp(
      title: 'Truck logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f7f5),
        colorScheme: ColorScheme.fromSeed(seedColor: teal).copyWith(primary: teal, onSurface: ink),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: ink, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xffdbe2df))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xffdbe2df))),
        ),
      ),
      home: const TruckLogScreen(),
    );
  }
}

enum LogStatus { uploaded, uploading, retry }

class TruckLog {
  const TruckLog({required this.plate, required this.party, required this.time, required this.driver, required this.status, required this.materials});
  final String plate;
  final String party;
  final String time;
  final String driver;
  final LogStatus status;
  final List<String> materials;
}

const sampleLogs = [
  TruckLog(plate: 'GJ 37 V 0562', party: 'Islami Sea Food', time: '10:42 AM', driver: 'Ravi K.', status: LogStatus.uploaded, materials: ['Fish mix · 10 Box', 'Small fish · 60 Box', 'Ice · 200 kg']),
  TruckLog(plate: 'GJ 03 BX 4417', party: 'Sagar Fish Traders', time: '10:15 AM', driver: 'Arif M.', status: LogStatus.uploading, materials: ['Fish mix · 10 Box']),
  TruckLog(plate: 'GJ 11 T 2290', party: 'Veraval Exports', time: '9:58 AM', driver: 'Ravi K.', status: LogStatus.uploading, materials: ['Small fish · 60 Box']),
  TruckLog(plate: 'GJ 37 W 1184', party: 'Blue Wave Seafoods', time: '9:30 AM', driver: 'Arif M.', status: LogStatus.retry, materials: ['Fish mix · 10 Box']),
];

class TruckLogScreen extends StatefulWidget {
  const TruckLogScreen({super.key});
  @override
  State<TruckLogScreen> createState() => _TruckLogScreenState();
}

class _TruckLogScreenState extends State<TruckLogScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Today';
  bool _showUploads = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final logs = sampleLogs.where((log) => log.plate.toLowerCase().contains(query) || log.party.toLowerCase().contains(query)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truck log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [IconButton(tooltip: 'App information', onPressed: () => _openAppInfo(context), icon: const Icon(Icons.more_vert))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('Today, 4 trucks', style: TextStyle(fontSize: 11, color: Color(0xff72807b))))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Search plate number', prefixIcon: Icon(Icons.search, size: 18)))),
            _FilterRow(
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
              onPickDate: () => _pickDate(context),
            ),
            if (_showUploads)
              _UploadBanner(
                onTap: () => _openUploads(context),
                onDismiss: () => setState(() => _showUploads = false),
              ),
            Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), itemCount: logs.length, itemBuilder: (context, index) => _LogTile(log: logs[index], onTap: () => _openDetail(context, logs[index])))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openNewEntry(context), backgroundColor: const Color(0xff087866), foregroundColor: Colors.white, icon: const Icon(Icons.add, size: 18), label: const Text('New truck')),
    );
  }

  void _openNewEntry(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewEntryScreen()));
  void _openUploads(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingUploadsScreen()));
  void _openDetail(BuildContext context, TruckLog log) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(log: log)));
  void _openAppInfo(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppInfoScreen()));

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (!mounted || date == null) return;
    setState(() => _filter = '${date.day}/${date.month}/${date.year}');
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged, required this.onPickDate});
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickDate;
  @override
  Widget build(BuildContext context) => SizedBox(height: 54, child: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), scrollDirection: Axis.horizontal, children: ['Today', 'Yesterday', 'Pick date'].map((label) {
    final active = selected == label;
    return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : const Color(0xff30403a))), selected: active, onSelected: (_) => label == 'Pick date' ? onPickDate() : onChanged(label), selectedColor: const Color(0xff087866), backgroundColor: Colors.white, side: BorderSide.none, showCheckmark: false, visualDensity: VisualDensity.compact));
  }).toList()));
}

class _UploadBanner extends StatelessWidget {
  const _UploadBanner({required this.onTap, required this.onDismiss});
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    height: 30,
    child: Row(children: [
      const SizedBox(width: 2),
      const SizedBox(width: 14, height: 14, child: _UploadSpinner()),
      const SizedBox(width: 7),
      InkWell(
        onTap: onTap,
        child: const Text('2 videos still uploading', style: TextStyle(fontSize: 11, color: Color(0xff765000), decoration: TextDecoration.underline, decorationColor: Color(0xff765000))),
      ),
      const Spacer(),
      IconButton(onPressed: onDismiss, tooltip: 'Dismiss', icon: const Icon(Icons.close, size: 15, color: Color(0xff765000)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24)),
    ]),
  );
}

class _UploadSpinner extends StatefulWidget {
  const _UploadSpinner();
  @override
  State<_UploadSpinner> createState() => _UploadSpinnerState();
}

class _UploadSpinnerState extends State<_UploadSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: _controller, child: const Icon(Icons.sync, size: 14, color: Color(0xff9c6a00)));
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.onTap});
  final TruckLog log;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final status = switch (log.status) {
      LogStatus.uploaded => ('Uploaded', const Color(0xff16805c), const Color(0xffdff2e8)),
      LogStatus.uploading => ('Uploading', const Color(0xff9b6b00), const Color(0xffffedc3)),
      LogStatus.retry => ('Retry upload', const Color(0xffc54235), const Color(0xffffdfdc)),
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xffe3e8e5)))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(log.plate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: status.$3, borderRadius: BorderRadius.circular(10)),
                child: Text(status.$1, style: TextStyle(fontSize: 9, color: status.$2, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(log.party, style: const TextStyle(fontSize: 11, color: Color(0xff40504a))),
            const SizedBox(height: 3),
            Text('${log.time} · ${log.driver}', style: const TextStyle(fontSize: 9, color: Color(0xff7b8782))),
          ],
        ),
      ),
    );
  }
}

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});
  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _plate = TextEditingController(text: 'GJ 37 V 0562');
  final _party = TextEditingController(text: 'Islami Sea Food');
  final _ice = TextEditingController(text: '200');
  bool _recorded = false;
  @override
  void dispose() { _plate.dispose(); _party.dispose(); _ice.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const BackButton(), title: const Text('New truck entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      const _FieldLabel('Plate number'),
      TextField(controller: _plate, decoration: InputDecoration(suffixIcon: IconButton(onPressed: () => _showScanner(context), icon: const Icon(Icons.document_scanner_outlined)))),
      const _Hint('Scan the plate with the camera, or type it'),
      const _FieldLabel('Party name'), TextField(controller: _party),
      const _FieldLabel('Materials'), const _MaterialLine(name: 'Fish mix', quantity: '10'), const _MaterialLine(name: 'Small fish', quantity: '60'),
      TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 15), label: const Text('Add material', style: TextStyle(fontSize: 11)), style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero)),
      const _FieldLabel('Ice (kg)'), TextField(controller: _ice, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: 'kg')),
      const _FieldLabel('Truck video'),
      InkWell(onTap: () => setState(() => _recorded = true), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xffdbe2df)), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(_recorded ? Icons.check_circle : Icons.videocam_outlined, color: const Color(0xff087866)), const SizedBox(width: 10), Expanded(child: Text(_recorded ? '0:14 recorded' : 'Tap to record truck video', style: const TextStyle(fontSize: 11))), TextButton(onPressed: () => setState(() => _recorded = false), child: Text(_recorded ? 'Retake' : 'Record'))]))),
      const _FieldLabel('Note (optional)'), const TextField(decoration: InputDecoration(hintText: 'Anything worth recording')), const SizedBox(height: 24),
      FilledButton(onPressed: () => _save(context), child: const Text('Save entry')),
    ]),
  );
  void _showScanner(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => ScanPlateScreen(onPlate: (plate) { _plate.text = plate; setState(() {}); })));
  void _save(BuildContext context) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved. Video will upload in the background.'))); Navigator.pop(context); }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 17, bottom: 6), child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xff596862))));
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 5), child: Text(text, style: const TextStyle(fontSize: 9, color: Color(0xff85918c))));
}

class _MaterialLine extends StatelessWidget {
  const _MaterialLine({required this.name, required this.quantity});
  final String name;
  final String quantity;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(flex: 2, child: DropdownButtonFormField<String>(initialValue: name, isExpanded: true, items: ['Fish mix', 'Small fish', 'Panfret', 'Prawns', 'Squid', 'Mackerel'].map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(), onChanged: (_) {})), const SizedBox(width: 8), Expanded(flex: 1, child: TextFormField(initialValue: quantity, decoration: const InputDecoration(suffixText: 'Box'), keyboardType: TextInputType.number))]));
}

class ScanPlateScreen extends StatefulWidget {
  const ScanPlateScreen({super.key, required this.onPlate});
  final ValueChanged<String> onPlate;

  @override
  State<ScanPlateScreen> createState() => _ScanPlateScreenState();
}

class _ScanPlateScreenState extends State<ScanPlateScreen> with WidgetsBindingObserver {
  CameraController? _camera;
  TextRecognizer? _recognizer;
  TextEditingController? _plateController;
  String? _imagePath;
  String? _error;
  bool _capturing = false;
  bool _streaming = false;
  bool _processingFrame = false;
  Rect? _livePlateBox;
  Size? _liveImageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('No camera', 'No camera was found on this device.');
      final camera = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await camera.initialize();
      if (!mounted) {
        await camera.dispose();
        return;
      }
      setState(() => _camera = camera);
      await camera.startImageStream(_processLiveFrame);
      if (mounted) setState(() => _streaming = true);
    } on CameraException catch (exception) {
      if (mounted) setState(() => _error = exception.description ?? exception.code);
    } catch (exception) {
      if (mounted) setState(() => _error = exception.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      camera.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _recognizer?.close();
    _plateController?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final camera = _camera;
    final recognizer = _recognizer;
    if (camera == null || !camera.value.isInitialized || _capturing || recognizer == null) return;
    setState(() => _capturing = true);
    try {
      if (_streaming) {
        await camera.stopImageStream();
        _streaming = false;
      }
      final image = await camera.takePicture();
      final ocrPath = await _createGuideRegionImage(image.path);
      final result = await recognizer.processImage(InputImage.fromFilePath(ocrPath));
      final plate = extractIndianPlate(result);
      if (plate == null) {
        throw const FormatException('No valid Indian plate found');
      }
      if (!mounted) return;
      setState(() {
        _imagePath = image.path;
        _plateController?.dispose();
        _plateController = TextEditingController(text: plate);
        _capturing = false;
      });
    } catch (exception) {
      if (mounted) setState(() { _capturing = false; _error = 'Could not scan the plate. Try again or type it instead.'; });
    }
  }

  Future<void> _processLiveFrame(CameraImage frame) async {
    final recognizer = _recognizer;
    if (recognizer == null || _processingFrame || _capturing || _imagePath != null) return;
    if (frame.format.group != ImageFormatGroup.nv21 || frame.planes.isEmpty) return;
    _processingFrame = true;
    try {
      final bytes = frame.planes.first.bytes;
      final input = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(frame.width.toDouble(), frame.height.toDouble()),
          rotation: _imageRotation(),
          format: InputImageFormat.nv21,
          bytesPerRow: frame.planes.first.bytesPerRow,
        ),
      );
      final result = await recognizer.processImage(input);
      final candidates = result.blocks.where(_looksLikePlate).toList();
      if (!mounted) return;
      setState(() {
        _liveImageSize = Size(frame.width.toDouble(), frame.height.toDouble());
        _livePlateBox = candidates.isEmpty ? null : candidates.first.boundingBox;
      });
    } catch (_) {
      // Live detection is best effort; capture and manual entry remain available.
    } finally {
      _processingFrame = false;
    }
  }

  InputImageRotation _imageRotation() {
    final orientation = _camera?.description.sensorOrientation ?? 90;
    return switch (orientation) {
      0 => InputImageRotation.rotation0deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _ => InputImageRotation.rotation90deg,
    };
  }

  bool _looksLikePlate(TextBlock block) {
    final width = block.boundingBox.width;
    final height = block.boundingBox.height;
    final aspectRatio = width / height;
    final plate = normalizePlateText(block.text);
    return aspectRatio >= 2.2 && aspectRatio <= 12 && isValidIndianPlate(plate);
  }

  Future<String> _createGuideRegionImage(String sourcePath) async {
    final source = image_tools.decodeImage(await File(sourcePath).readAsBytes());
    if (source == null) return sourcePath;

    // The yellow guide is centered in the preview and occupies this same
    // normalized region, independent of the camera sensor resolution.
    final cropWidth = (source.width * .78).round();
    final cropHeight = (source.height * .38).round();
    final crop = image_tools.copyCrop(
      source,
      x: (source.width - cropWidth) ~/ 2,
      y: (source.height - cropHeight) ~/ 2,
      width: cropWidth,
      height: cropHeight,
    );
    final ocrPath = '${sourcePath}_ocr.jpg';
    await File(ocrPath).writeAsBytes(image_tools.encodeJpg(crop, quality: 95));
    return ocrPath;
  }

  void _retake() {
    _plateController?.dispose();
    setState(() { _imagePath = null; _plateController = null; _error = null; });
    final camera = _camera;
    if (camera != null && camera.value.isInitialized && !_streaming) {
      camera.startImageStream(_processLiveFrame).then((_) {
        if (mounted) setState(() => _streaming = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCapture = _imagePath != null && _plateController != null;
    return Scaffold(
      backgroundColor: const Color(0xff0b1714),
      appBar: AppBar(backgroundColor: const Color(0xff0b1714), foregroundColor: Colors.white, title: const Text('Scan plate', style: TextStyle(fontSize: 16))),
      body: Column(children: [
        Expanded(child: Stack(alignment: Alignment.center, children: [
          if (_imagePath != null) Positioned.fill(child: Image.file(File(_imagePath!), fit: BoxFit.cover)),
          if (_imagePath == null && _camera?.value.isInitialized == true) Positioned.fill(child: CameraPreview(_camera!)),
          if (_imagePath == null && _camera == null && _error == null) const CircularProgressIndicator(color: Colors.white),
          if (_imagePath == null && _camera == null && _error != null) Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))),
          if (_imagePath == null && _camera?.value.isInitialized == true) IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _CameraOverlayPainter(box: _livePlateBox, imageSize: _liveImageSize, sensorOrientation: _camera!.description.sensorOrientation))),
        ])),
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 16, 16, 26), child: hasCapture ? _confirmationPanel(context) : _capturePanel(context)),
      ]),
    );
  }
  Widget _capturePanel(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Fit the whole plate inside the box', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xff596862))),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _capturing ? null : _capture, icon: const Icon(Icons.camera_alt_outlined), label: Text(_capturing ? 'Reading plate...' : _livePlateBox == null ? 'Capture plate' : 'Plate detected · Capture')),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.red))),
  ]);

  Widget _confirmationPanel(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Detected plate', style: TextStyle(fontSize: 10)),
    const SizedBox(height: 8),
    TextField(controller: _plateController, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'Type plate number')),
    const SizedBox(height: 6),
    const Text('Check it matches the truck before continuing.', style: TextStyle(fontSize: 10, color: Color(0xff72807b))),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: OutlinedButton(onPressed: _retake, child: const Text('Retake'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () { final plate = _plateController!.text.trim(); if (plate.isEmpty) return; widget.onPlate(plate); Navigator.pop(context); }, child: const Text('Use this plate')))]),
  ]);
}

class _CameraOverlayPainter extends CustomPainter {
  const _CameraOverlayPainter({required this.box, required this.imageSize, required this.sensorOrientation});
  final Rect? box;
  final Size? imageSize;
  final int sensorOrientation;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = const Color(0xffffc800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final detectedPaint = Paint()
      ..color = const Color(0xff38d39f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final guide = Rect.fromLTWH(size.width * .1, size.height * .35, size.width * .8, size.height * .3);
    canvas.drawRRect(RRect.fromRectAndRadius(guide, const Radius.circular(8)), guidePaint);

    final detected = box;
    final source = imageSize;
    if (detected == null || source == null || source.width == 0 || source.height == 0) return;
    final rotated = switch (sensorOrientation) {
      0 => detected,
      180 => Rect.fromLTRB(source.width - detected.right, source.height - detected.bottom, source.width - detected.left, source.height - detected.top),
      270 => Rect.fromLTRB(source.height - detected.bottom, detected.left, source.height - detected.top, detected.right),
      _ => Rect.fromLTRB(detected.top, source.width - detected.right, detected.bottom, source.width - detected.left),
    };
    final rotatedSize = sensorOrientation == 90 || sensorOrientation == 270 ? Size(source.height, source.width) : source;
    final scale = math.max(size.width / rotatedSize.width, size.height / rotatedSize.height);
    final offsetX = (size.width - rotatedSize.width * scale) / 2;
    final offsetY = (size.height - rotatedSize.height * scale) / 2;
    final mapped = Rect.fromLTRB(
      rotated.left * scale + offsetX,
      rotated.top * scale + offsetY,
      rotated.right * scale + offsetX,
      rotated.bottom * scale + offsetY,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(mapped, const Radius.circular(6)), detectedPaint);
  }

  @override
  bool shouldRepaint(covariant _CameraOverlayPainter oldDelegate) => oldDelegate.box != box || oldDelegate.imageSize != imageSize || oldDelegate.sensorOrientation != sensorOrientation;
}

class PendingUploadsScreen extends StatelessWidget {
  const PendingUploadsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pending uploads', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), body: ListView(padding: const EdgeInsets.all(16), children: const [_UploadItem(plate: 'GJ 03 BX 4417', progress: 'Uploading 62%', value: .62), _UploadItem(plate: 'GJ 11 T 2290', progress: 'Uploading 18%', value: .18), _UploadItem(plate: 'GJ 37 W 1184', progress: 'Failed · Retry when you’re online', value: 0, failed: true)]));
}

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('App information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: const Color(0xff10231f), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 20),
          const Text('Truck logger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Version 0.0.1', style: TextStyle(fontSize: 12, color: Color(0xff72807b))),
          const SizedBox(height: 24),
          const Text('A simple way to record and track truck entries.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xff596862))),
        ]),
      ),
    ),
  );
}

class _UploadItem extends StatelessWidget {
  const _UploadItem({required this.plate, required this.progress, required this.value, this.failed = false});
  final String plate;
  final String progress;
  final double value;
  final bool failed;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xffe0e7e3)))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(plate, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), const Spacer(), Text(progress, style: TextStyle(fontSize: 10, color: failed ? Colors.red : const Color(0xff9c6a00)))]), const SizedBox(height: 10), LinearProgressIndicator(value: value, color: failed ? Colors.red : const Color(0xff087866), backgroundColor: const Color(0xffdce4df)), if (failed) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Retry')))]));
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.log});
  final TruckLog log;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Truck entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), body: ListView(padding: const EdgeInsets.all(16), children: [Container(height: 190, decoration: BoxDecoration(color: const Color(0xff10231f), borderRadius: BorderRadius.circular(8)), child: const Center(child: CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.play_arrow, color: Color(0xff10231f), size: 28)))), const SizedBox(height: 8), const Text('0:00 / 0:14 · uploaded 10:43 AM', style: TextStyle(fontSize: 9, color: Color(0xff72807b))), const SizedBox(height: 12), Row(children: [Text(log.plate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(width: 10), const _StatusPill()]), const Divider(height: 32), _DetailRow('Party name', log.party), _DetailRow('Logged by', '${log.driver} · ${log.time}'), const SizedBox(height: 14), const Text('Materials', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 6), ...log.materials.map((material) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(material, style: const TextStyle(fontSize: 11))))]));
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xffdff2e8), borderRadius: BorderRadius.circular(10)), child: const Text('Uploaded', style: TextStyle(fontSize: 9, color: Color(0xff16805c))));
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xff72807b)))), Expanded(child: Text(value, style: const TextStyle(fontSize: 11)))]));
}