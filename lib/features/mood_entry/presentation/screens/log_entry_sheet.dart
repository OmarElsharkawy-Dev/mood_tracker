import 'package:flutter/material.dart';

class LogEntrySheet extends StatelessWidget {
  const LogEntrySheet({super.key, this.editEntryId});
  final String? editEntryId;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Log entry (placeholder)')));
}
