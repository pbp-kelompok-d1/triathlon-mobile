import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:triathlon_mobile/activity/models/activity_model.dart';
import 'package:triathlon_mobile/activity/screens/activity_form.dart';
import 'package:triathlon_mobile/activity/widgets/activity_card.dart';

class ActivityMenu extends StatefulWidget {
  const ActivityMenu({super.key});

  @override
  State<ActivityMenu> createState() => _ActivityMenuState();
}

class _ActivityMenuState extends State<ActivityMenu> {
  Future<List<Activity>> fetchActivities(CookieRequest request) async {
    final response = await request.get('http://127.0.0.1:8000/activities/jsonning');
    
    // The response might be a Map with "results" key or a List depending on pagination.
    // In views.py: return JsonResponse({"results": results, ...})
    
    if (response is Map<String, dynamic> && response.containsKey('results')) {
      List<dynamic> results = response['results'];
      return results.map((d) => Activity.fromJson(d)).toList();
    } else if (response is List) {
      return response.map((d) => Activity.fromJson(d)).toList();
    } else {
      throw Exception("Unexpected response format");
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: fetchActivities(request),
        builder: (context, AsyncSnapshot<List<Activity>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Failed to load activities"),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No activities yet. Click + to add one!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ActivityCard(
                    activity: snapshot.data![index],
                    onRefresh: () {
                      setState(() {});
                    },
                  );
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ActivityFormPage(),
            ),
          );
          setState(() {}); // Refresh after returning
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
