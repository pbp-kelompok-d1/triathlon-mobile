import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/activity/models/activity_model.dart';
import 'package:triathlon_mobile/activity/screens/activity_form.dart';
import 'package:triathlon_mobile/activity/widgets/activity_card.dart';
import 'package:triathlon_mobile/constants.dart';
import 'package:triathlon_mobile/widgets/left_drawer.dart';

class ActivityMenu extends StatefulWidget {
  const ActivityMenu({super.key});

  @override
  State<ActivityMenu> createState() => _ActivityMenuState();
}

class _ActivityMenuState extends State<ActivityMenu> {
  Future<List<Activity>>? _futureActivities;

  // Filter state
  String _selectedSport = 'All sports';
  int? _minDistance;
  int? _maxDistance;

  // Cache last fetched activities to build the sport dropdown list
  List<Activity> _cachedActivities = [];

  @override
  void initState() {
    super.initState();
    // Need context for CookieRequest
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<List<Activity>> fetchActivities(CookieRequest request) async {
    final response = await request.get('$baseUrl/activities/jsonning');

    List<Activity> parsed;
    if (response is Map<String, dynamic> && response.containsKey('results')) {
      final List<dynamic> results = response['results'] as List<dynamic>;
      parsed = results.map((d) => Activity.fromJson(d as Map<String, dynamic>)).toList();
    } else if (response is List) {
      parsed = response.map((d) => Activity.fromJson(d as Map<String, dynamic>)).toList();
    } else {
      throw Exception("Unexpected response format");
    }

    _cachedActivities = parsed;
    return parsed;
  }

  void _refresh() {
    final request = context.read<CookieRequest>();
    setState(() {
      _futureActivities = fetchActivities(request);
    });
  }

  String _sportFor(Activity a) {
    final label = a.sportLabel.trim();
    return label.isNotEmpty ? label : a.sportCategory;
  }

  List<String> _sportOptionsFromCache() {
    final set = <String>{};
    for (final a in _cachedActivities) {
      final s = _sportFor(a).trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All sports', ...list];
  }

  List<Activity> _applyAllFilters({
    required List<Activity> activities,
    required String? username,
  }) {
    // Only the logged-in user's activities
    final userFiltered = (username == null || username.trim().isEmpty)
        ? activities
        : activities.where((a) => a.creatorUsername == username).toList();

    // Sport + distance filters
    return userFiltered.where((a) {
      final sportOk = (_selectedSport == 'All sports') || (_sportFor(a) == _selectedSport);

      final dist = a.distance;
      final minOk = (_minDistance == null) || (dist >= _minDistance!);
      final maxOk = (_maxDistance == null) || (dist <= _maxDistance!);

      return sportOk && minOk && maxOk;
    }).toList();
  }

  Future<void> _openFilterModal() async {
    final sportOptions = _sportOptionsFromCache();

    final minController = TextEditingController(
      text: _minDistance == null ? '' : _minDistance.toString(),
    );
    final maxController = TextEditingController(
      text: _maxDistance == null ? '' : _maxDistance.toString(),
    );

    String tempSport = _selectedSport;
    if (!sportOptions.contains(tempSport)) {
      tempSport = 'All sports';
    }

    final result = await showDialog<_FilterResult>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title + close
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter Activities',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sport dropdown
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sport',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempSport,
                      items: sportOptions
                          .map((s) => DropdownMenuItem<String>(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setDialogState(() {
                          tempSport = v;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Distance range
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Distance range (meters)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Min',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Max',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Leave blank to ignore a bound.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              int? parseOrNull(String s) {
                                final t = s.trim();
                                if (t.isEmpty) return null;
                                return int.tryParse(t);
                              }

                              final minV = parseOrNull(minController.text);
                              final maxV = parseOrNull(maxController.text);

                              Navigator.pop(
                                dialogCtx,
                                _FilterResult(
                                  sport: tempSport,
                                  minDistance: minV,
                                  maxDistance: maxV,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedSport = result.sport;
      _minDistance = result.minDistance;
      _maxDistance = result.maxDistance;
    });
    _refresh();
  }

  Future<void> _goToAddActivity() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActivityFormPage()),
    );

    if (!mounted) return;
    _refresh();
  }

  Widget _topActionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _goToAddActivity,
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _openFilterModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF374151),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Filter',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final String? username = (request.jsonData is Map && request.jsonData['username'] != null)
        ? request.jsonData['username'].toString()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: Column(
        children: [
          _topActionBar(),
          Expanded(
            child: FutureBuilder<List<Activity>>(
              future: _futureActivities,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("Error: ${snapshot.error}"),
                    ),
                  );
                }

                final all = snapshot.data ?? const <Activity>[];
                final filtered = _applyAllFilters(activities: all, username: username);

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        username == null
                            ? "No activities found."
                            : "No activities found for @$username with the current filters.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final activity = filtered[idx];
                      return ActivityCard(
                        activity: activity,
                        onView: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(activity.title),
                              content: Text(
                                activity.notesFull.trim().isNotEmpty
                                    ? activity.notesFull
                                    : (activity.notesShort.trim().isNotEmpty
                                        ? activity.notesShort
                                        : "No notes."),
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
                        onEdit: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => ActivityFormPage(activity: activity,))
                          );
                        },
                        onDelete: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Delete not wired yet.")),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterResult {
  final String sport;
  final int? minDistance;
  final int? maxDistance;

  _FilterResult({
    required this.sport,
    required this.minDistance,
    required this.maxDistance,
  });
}
