import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/milk_request_model.dart';

class MyMilkRequestsScreen extends StatefulWidget {
  const MyMilkRequestsScreen({super.key});

  @override
  State<MyMilkRequestsScreen> createState() => _MyMilkRequestsScreenState();
}

class _MyMilkRequestsScreenState extends State<MyMilkRequestsScreen> {
  bool _isLoading = true;
  String? _error;
  List<MilkRequestModel> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get(ApiConstants.myMilkRequests);
      final items = response is Map && response['requests'] is List ? response['requests'] as List : const [];
      final requests = items
          .whereType<Map>()
          .map((item) => MilkRequestModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (mounted) setState(() => _requests = requests);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Milk Requests'),
        actions: [IconButton(onPressed: _loadRequests, icon: const Icon(Icons.refresh))],
      ),
      backgroundColor: AppColors.pageBackground,
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [Text('Unable to load requests: $_error')],
                  )
                : _requests.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [Center(child: Text('No milk requests submitted yet.'))],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (_, index) => _buildRequestCard(_requests[index]),
                      ),
      ),
    );
  }

  Widget _buildRequestCard(MilkRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.requestNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                ),
                Chip(label: Text(request.status), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 8),
            Text('Recipient: ${request.recipientName}'),
            Text('Volume: ${request.formattedVolumeRequested}'),
            Text('Date: ${request.formattedDate}'),
            Text('Reason: ${request.reasonForRequest}', maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
