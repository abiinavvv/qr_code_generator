import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Link QR Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const QRGeneratorScreen(),
    );
  }
}

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _linkController = TextEditingController();
  String qrData = '';
  bool isValidUrl = false;

  bool isValidLink(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void validateAndUpdateQR(String value) {
    setState(() {
      if (value.isEmpty) {
        qrData = '';
        isValidUrl = false;
        return;
      }

      String url = value.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      isValidUrl = isValidLink(url);
      qrData = isValidUrl ? url : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link QR Generator'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: 'Enter website URL',
                        labelText: 'Website Link',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        errorText:
                            _linkController.text.isNotEmpty && !isValidUrl
                                ? 'Please enter a valid URL'
                                : null,
                        helperText:
                            'Example: www.example.com or https://example.com',
                      ),
                      onChanged: validateAndUpdateQR,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (qrData.isNotEmpty && isValidUrl) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Scan to visit:\n$qrData',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final qrValidationResult = QrValidator.validate(
                                data: qrData,
                                version: QrVersions.auto,
                                errorCorrectionLevel: QrErrorCorrectLevel.L,
                              );

                              if (qrValidationResult.status ==
                                  QrValidationStatus.valid) {
                                final qrCode = qrValidationResult.qrCode;
                                final painter = QrPainter.withQr(
                                  qr: qrCode!,
                                  color: const Color(0xFF000000),
                                  emptyColor: const Color(0xFFFFFFFF),
                                  gapless: true,
                                );

                                final tempDir = await getTemporaryDirectory();
                                final ts = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                                final path = '${tempDir.path}/qr_$ts.png';

                                final picData = await painter.toImageData(2048,
                                    format: ui.ImageByteFormat.png);
                                await File(path).writeAsBytes(
                                    picData!.buffer.asUint8List());

                                await ImageGallerySaver.saveFile(path);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('QR Code saved to gallery')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save QR'),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Share.share('Check out this link: $qrData');
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share Link'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}
