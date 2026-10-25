import 'package:flutter/material.dart';

/// New service order form. Pushed over the shell, so it has no bottom bar.
///
/// Fields will follow the client's OS template.
class ServiceOrderFormPage extends StatelessWidget {
  const ServiceOrderFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova OS')),
      body: const Center(child: Text('Formulário em construção')),
    );
  }
}
