import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';
import '../services/printer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Printer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<PaymentService>(
                      builder: (context, paymentService, child) {
                        return ElevatedButton(
                          onPressed: paymentService.isProcessing
                              ? null
                              : () async {
                                  final success = await paymentService.processPayment(
                                    amount: _amountController.text,
                                    currency: 'USD',
                                    description: _descriptionController.text,
                                  );
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Payment successful!'),
                                      ),
                                    );
                                  }
                                },
                          child: paymentService.isProcessing
                              ? const CircularProgressIndicator()
                              : const Text('Process Payment'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Printer Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Printer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<PrinterService>(
                      builder: (context, printerService, child) {
                        return Column(
                          children: [
                            ElevatedButton(
                              onPressed: printerService.isScanning
                                  ? null
                                  : () => printerService.scanDevices(),
                              child: printerService.isScanning
                                  ? const CircularProgressIndicator()
                                  : const Text('Scan for Printers'),
                            ),
                            if (printerService.error != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  printerService.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (printerService.devices.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: printerService.devices.length,
                                itemBuilder: (context, index) {
                                  final device = printerService.devices[index];
                                  final isSelected = printerService.selectedDevice?.address == device.address;
                                  return ListTile(
                                    title: Text(device.name ?? 'Unknown Device'),
                                    subtitle: Text(device.address ?? 'No Address'),
                                    trailing: isSelected
                                        ? const Icon(Icons.check, color: Colors.green)
                                        : null,
                                    onTap: () async {
                                      if (!isSelected) {
                                        await printerService.connectToPrinter(device);
                                      }
                                      final success = await printerService.printReceipt(
                                        title: 'Payment Receipt',
                                        content: 'Amount: \$${_amountController.text}\n'
                                            'Description: ${_descriptionController.text}',
                                        footer: 'Thank you for your business!',
                                      );
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Receipt printed successfully!'),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 