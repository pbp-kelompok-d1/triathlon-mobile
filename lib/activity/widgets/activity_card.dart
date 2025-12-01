import 'package:flutter/material.dart';
import 'package:triathlon_mobile/activity/models/activity_model.dart';
import 'package:triathlon_mobile/activity/screens/activity_form.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onRefresh;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onRefresh,
  });

  Future<void> _deleteActivity(BuildContext context, CookieRequest request) async {
    final response = await request.postJson(
      "http://127.0.0.1:8000/activities/delete/${activity.id}",
      jsonEncode({}),
    );

    if (context.mounted) {
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Activity deleted successfully!")),
        );
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to delete")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Owner/Place and Kcal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "@${activity.creatorUsername}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (activity.placeName != null)
                        Text(
                          activity.placeName!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${activity.sportLabel} • ${activity.doneAtDisplay}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${activity.caloriesBurned.round()} kcal",
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid Stats
            Row(
              children: [
                Expanded(child: _buildStatBox("Duration", _formatDuration(activity.duration))),
                const SizedBox(width: 8),
                Expanded(child: _buildStatBox("Distance", "${activity.distance} m")),
                const SizedBox(width: 8),
                Expanded(child: _buildStatBox("Sport", activity.sportLabel)),
              ],
            ),
            if (activity.notesShort.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                activity.notesShort,
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Implement View Modal if needed, or just show full notes in a dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(activity.title),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Sport: ${activity.sportLabel}"),
                                Text("Date: ${activity.doneAtDisplay}"),
                                Text("Duration: ${_formatDuration(activity.duration)}"),
                                Text("Distance: ${activity.distance} m"),
                                Text("Calories: ${activity.caloriesBurned} kcal"),
                                const SizedBox(height: 10),
                                const Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(activity.notesFull),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("View"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                       await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityFormPage(activity: activity),
                        ),
                      );
                      onRefresh();
                    },
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                       showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Activity"),
                          content: Text("Are you sure you want to delete '${activity.title}'?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteActivity(context, request);
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("Delete"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDuration(String duration) {
    // Expecting "HH:MM:SS" or "D day, HH:MM:SS"
    // Simple parser for "HH:MM:SS"
    try {
      final parts = duration.split(':');
      if (parts.length == 3) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return "${h}h ${m.toString().padLeft(2, '0')}m";
      }
    } catch (e) {
      // Fallback
    }
    return duration;
  }
}
