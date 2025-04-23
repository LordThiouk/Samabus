import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../utils/localization.dart';
import 'passenger_info_screen.dart';

class TripListScreen extends StatelessWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final tripProvider = Provider.of<TripProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('search_results')),
      ),
      body: tripProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tripProvider.searchResults.isEmpty
              ? _buildEmptyState(context, localizations)
              : _buildTripList(context, tripProvider, localizations),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.get('no_trips_found'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            localizations.get('try_different_search'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: Text(localizations.get('back_to_search')),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(
    BuildContext context,
    TripProvider tripProvider,
    AppLocalizations localizations,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tripProvider.searchResults.length,
      itemBuilder: (context, index) {
        final trip = tripProvider.searchResults[index];
        return _buildTripCard(context, trip, tripProvider, localizations);
      },
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    Trip trip,
    TripProvider tripProvider,
    AppLocalizations localizations,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'FCFA ',
      decimalDigits: 0,
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          tripProvider.selectTrip(trip);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PassengerInfoScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route and time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.departureCity} → ${trip.arrivalCity}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(trip.departureDateTime),
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      currencyFormat.format(trip.fare),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Departure and arrival times
              Row(
                children: [
                  _buildTimeColumn(
                    context,
                    DateFormat('HH:mm').format(trip.departureDateTime),
                    localizations.get('departure'),
                    trip.departureCity,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                        ),
                        Text(
                          _getTripDuration(trip),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTimeColumn(
                    context,
                    trip.arrivalDateTime != null
                        ? DateFormat('HH:mm').format(trip.arrivalDateTime!)
                        : '--:--',
                    localizations.get('arrival'),
                    trip.arrivalCity,
                    alignment: CrossAxisAlignment.end,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Available seats and book button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${localizations.get('available_seats')}: ${trip.availableSeats}',
                    style: TextStyle(
                      color: trip.availableSeats < 5 ? Colors.orange[700] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      tripProvider.selectTrip(trip);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PassengerInfoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(localizations.get('book_now')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(
    BuildContext context,
    String time,
    String label,
    String location, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTripDuration(Trip trip) {
    if (trip.arrivalDateTime == null) return '';
    
    final duration = trip.arrivalDateTime!.difference(trip.departureDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    return '$hours${hours == 1 ? 'hr' : 'hrs'} $minutes${minutes == 1 ? 'min' : 'mins'}';
  }
}
