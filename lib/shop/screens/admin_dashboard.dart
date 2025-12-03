// lib/shop/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/constants.dart';
import '../services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late AdminService _adminService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _adminService = AdminService(request, baseUrl);
  }

  Future<void> _loadDataset(String type) async {
    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    switch (type) {
      case 'cycling':
        result = await _adminService.loadDatasetCycling();
        break;
      case 'running':
        result = await _adminService.loadDatasetRunning();
        break;
      case 'swimming':
        result = await _adminService.loadDatasetSwimming();
        break;
      default:
        result = {'success': false, 'message': 'Unknown dataset type'};
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Done'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteAllProducts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Products'),
        content: const Text(
          'Are you sure you want to delete ALL products?\nThis action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final result = await _adminService.deleteAllProducts();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Done'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Load Datasets',
              icon: Icons.upload_file,
              children: [
                _buildActionButton(
                  label: 'Load Cycling Dataset',
                  icon: Icons.directions_bike,
                  color: Colors.blue,
                  onPressed: () => _loadDataset('cycling'),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: 'Load Running Dataset',
                  icon: Icons.directions_run,
                  color: Colors.orange,
                  onPressed: () => _loadDataset('running'),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: 'Load Swimming Dataset',
                  icon: Icons.pool,
                  color: Colors.cyan,
                  onPressed: () => _loadDataset('swimming'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Danger Zone',
              icon: Icons.warning,
              children: [
                _buildActionButton(
                  label: 'Delete All Products',
                  icon: Icons.delete_forever,
                  color: Colors.red,
                  onPressed: _deleteAllProducts,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}