import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offline_sync_provider.dart';
import '../../utils/localization.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _isScanning = true;
  String? _scannedCode;
  String? _validationMessage;
  bool _isValidationSuccess = false;
  final TextEditingController _cniController = TextEditingController();

  @override
  void dispose() {
    _controller?.dispose();
    _cniController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_controller != null) {
      _controller!.pauseCamera();
      _controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });
    
    final authProvider = context.read<AuthProvider>();
    controller.scannedDataStream.listen((scanData) async {
      if (!_isScanning) return;
      
      setState(() {
        _isScanning = false;
        _scannedCode = scanData.code;
      });
      
      if (_scannedCode != null && _scannedCode!.isNotEmpty) {
        controller.pauseCamera();
        final bookingId = _scannedCode!.split(':')[0];
        final validatedBy = authProvider.user?.id ?? 'unknown_operator';
        _validateTicket(bookingId, validatedBy);
      }
    });
  }

  Future<void> _validateTicket(String bookingId, String validatedBy) async {
    final offlineSyncProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
    
    final success = await offlineSyncProvider.validateTicketOffline(
      bookingId: bookingId,
      validatedBy: validatedBy,
    );
    
    setState(() {
      _isValidationSuccess = success;
      _validationMessage = success
          ? AppLocalizations.of(context).get('validation_success')
          : offlineSyncProvider.errorMessage ?? AppLocalizations.of(context).get('validation_error');
    });
  }

  Future<void> _validateByCNI() async {
    if (_cniController.text.isEmpty) return;
    
    // In a real app, this would search the offline database for a booking with this CNI
    // For now, we'll just show an error
    
    setState(() {
      _isValidationSuccess = false;
      _validationMessage = 'CNI validation not implemented in this demo';
    });
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _scannedCode = null;
      _validationMessage = null;
      _cniController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final offlineSyncProvider = Provider.of<OfflineSyncProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('scanner')),
        actions: [
          IconButton(
            icon: offlineSyncProvider.isSyncing
                ? const Icon(Icons.sync)
                : const Icon(Icons.sync),
            onPressed: offlineSyncProvider.isSyncing
                ? null
                : () => offlineSyncProvider.syncOfflineData(),
            tooltip: localizations.get('sync_now'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline status indicator
          if (offlineSyncProvider.isOffline)
            Container(
              color: Colors.red[100],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    localizations.get('no_internet'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          
          // Sync status indicator
          if (offlineSyncProvider.pendingSyncCount > 0)
            Container(
              color: Colors.amber[100],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.sync_problem, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '${localizations.get('pending_sync')}: ${offlineSyncProvider.pendingSyncCount}',
                    style: TextStyle(color: Colors.amber[800]),
                  ),
                ],
              ),
            ),
          
          // Scanner or validation result
          Expanded(
            child: _validationMessage != null
                ? _buildValidationResult()
                : _buildScanner(),
          ),
          
          // Manual CNI entry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations.get('enter_cni'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cniController,
                        decoration: InputDecoration(
                          hintText: 'CNI Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _validateByCNI,
                      child: Text(localizations.get('validate')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      alignment: Alignment.center,
      children: [
        QRView(
          key: _qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Theme.of(context).primaryColor,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: 300,
          ),
        ),
        const Positioned(
          bottom: 16,
          child: Text(
            'Scan QR code on ticket',
            style: TextStyle(
              color: Colors.white,
              backgroundColor: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isValidationSuccess ? Icons.check_circle : Icons.error,
              color: _isValidationSuccess ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              _validationMessage!,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (_scannedCode != null) ...[
              const SizedBox(height: 16),
              Text(
                'Booking ID: ${_scannedCode!.split(':')[0]}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
