import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/letting_event_model.dart';
import '../../providers/events_provider.dart';
import '../../widgets/app_widgets.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _searchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  // Client-side registered event tracker for current user session
  static final Set<String> _registeredEventIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<EventsProvider>(context, listen: false).fetchUpcomingEvents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleRegistration(String eventId, String title) {
    setState(() {
      if (_registeredEventIds.contains(eventId)) {
        _registeredEventIds.remove(eventId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration cancelled for $title'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.primaryNavy,
          ),
        );
      } else {
        _registeredEventIds.add(eventId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully registered for $title!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter list
    final filtered = eventsProvider.events.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.activity.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venue.fullAddress.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      final isPast = e.details.date.isBefore(today);
      final isRegistered = _registeredEventIds.contains(e.id);

      if (_selectedFilter == 'Upcoming') return !isPast;
      if (_selectedFilter == 'Past') return isPast;
      if (_selectedFilter == 'Registered') return isRegistered;
      return true; // 'All'
    }).toList();

    // Sort: newest / upcoming first
    filtered.sort((a, b) => a.details.date.compareTo(b.details.date));

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppTopBar(),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => eventsProvider.fetchUpcomingEvents(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title & Search Icon Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Milk Letting Events',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _searchExpanded ? Icons.close : Icons.search,
                      color: AppColors.primaryNavy,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchExpanded = !_searchExpanded;
                        if (!_searchExpanded) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),

              // Expandable Search Field
              if (_searchExpanded) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by title or venue...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ],
              const SizedBox(height: 12),

              // Filter Chips
              FilterChips(
                options: const ['All', 'Upcoming', 'Past', 'Registered'],
                selected: _selectedFilter,
                onSelected: (val) => setState(() => _selectedFilter = val),
              ),
              const SizedBox(height: 16),

              // Content List
              if (eventsProvider.status == EventsStatus.loading && eventsProvider.events.isEmpty)
                ...List.generate(3, (i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LoadingSkeleton(height: 110, radius: 20),
                    ))
              else if (filtered.isEmpty)
                const EmptyState(message: 'No events found')
              else
                ...filtered.map((e) {
                  final isRegistered = _registeredEventIds.contains(e.id);
                  final isPast = e.details.date.isBefore(today);
                  final status = isPast ? 'Past' : (isRegistered ? 'Registered' : 'Upcoming');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildEventCard(context, e, status, isRegistered, isPast),
                  );
                }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    LettingEventModel event,
    String status,
    bool isRegistered,
    bool isPast,
  ) {
    final dayStr = DateFormat('d').format(event.details.date);
    final monthStr = DateFormat('MMM').format(event.details.date).toUpperCase();
    final timeStr = '${event.details.time.start} – ${event.details.time.end}';

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              event: event,
              isRegistered: isRegistered,
              onToggleRegistration: () => _toggleRegistration(event.id, event.activity),
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Block on the left (Day big, Month small, softBlue square)
          Container(
            width: 52,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthStr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  dayStr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.activity,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.venue.fullAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    if (!isPast)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _toggleRegistration(event.id, event.activity),
                        child: Text(
                          isRegistered ? 'Registered' : 'Register',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isRegistered ? AppColors.success : AppColors.primaryBlue,
                          ),
                        ),
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
}
