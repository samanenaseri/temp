import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterService extends ChangeNotifier {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  String? _error;
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  List<BluetoothDevice> get devices => _devices;
  bool get isScanning => _isScanning;
  String? get error => _error;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;

  PrinterService() {
    _initPrinter();
  }

  void _initPrinter() {
    _printer.isConnected.then((connected) {
      _isConnected = connected!;
      notifyListeners();
    });
  }

  Future<void> scanDevices() async {
    try {
      setState(() {
        _isScanning = true;
        _error = null;
        _devices = [];
      });

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        throw Exception('Required permissions not granted');
      }

      // Get paired devices
      final pairedDevices = await _printer.getBondedDevices();
      setState(() {
        _devices = pairedDevices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isScanning = false;
      });
    }
  }

  Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      final connected = await _printer.connect(device);
      setState(() {
        _selectedDevice = device;
        _isConnected = connected;
        _error = connected ? null : 'Failed to connect to printer';
      });
      return connected;
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isConnected = false;
      });
      return false;
    }
  }

  Future<bool> printReceipt({
    required String title,
    required String content,
    required String footer,
  }) async {
    try {
      if (!_isConnected || _selectedDevice == null) {
        throw Exception('No printer connected');
      }

      // Print header
      await _printer.printCustom(title, 1, 1);
      await _printer.printCustom('--------------------------------', 1, 0);
      
      // Print content
      await _printer.printCustom(content, 1, 0);
      await _printer.printCustom('--------------------------------', 1, 0);
      
      // Print footer
      await _printer.printCustom(footer, 1, 0);
      
      // Cut paper
      await _printer.paperCut();
      
      return true;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return false;
    }
  }

  void setState(Function() fn) {
    fn();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isConnected) {
      _printer.disconnect();
    }
    super.dispose();
  }
} 