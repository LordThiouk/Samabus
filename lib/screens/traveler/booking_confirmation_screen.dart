import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../utils/localization.dart';
import '../traveler/traveler_home_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    if (bookingProvider.currentBooking == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.get('booking_confirmation')),
        ),
        body: const Center(
          child: Text('No booking found'),
        ),
      );
    }
    
    final booking = bookingProvider.currentBooking!;
    final currencyFormat = NumberFormat.currency(
      symbol: 'FCFA ',
      decimalDigits: 0,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('booking_confirmation')),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Success message
                  Text(
                    localizations.get('booking_successful'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.get('booking_confirmation_message'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Code
                  if (booking.qrCode != null) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              localizations.get('scan_this_code'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            QrImageView(
                              data: booking.qrCode!,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${localizations.get('booking_id')}: ${booking.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Booking details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.get('booking_details'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            context,
                            localizations.get('status'),
                            _getStatusText(booking.status, localizations),
                            _getStatusColor(booking.status),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            context,
                            localizations.get('payment_method'),
                            _getPaymentMethodText(booking.paymentMethod, localizations),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            context,
                            localizations.get('total_amount'),
                            currencyFormat.format(booking.totalAmount),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            context,
                            localizations.get('passengers'),
                            '${booking.passengers.length}',
                          ),
                          const SizedBox(height: 16),
                          
                          // Passenger list
                          ...booking.passengers.map((passenger) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 8),
                              child: Text('• ${passenger.fullName}'),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const TravelerHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations.get('back_to_home'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, [
    Color? valueColor,
  ]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _getStatusText(BookingStatus status, AppLocalizations localizations) {
    switch (status) {
      case BookingStatus.pending:
        return localizations.get('pending');
      case BookingStatus.confirmed:
        return localizations.get('confirmed');
      case BookingStatus.cancelled:
        return localizations.get('cancelled');
      case BookingStatus.completed:
        return localizations.get('completed');
      case BookingStatus.refunded:
        return localizations.get('refunded');
      default:
        return '';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.refunded:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  String _getPaymentMethodText(PaymentMethod? method, AppLocalizations localizations) {
    if (method == null) return '-';
    
    switch (method) {
      case PaymentMethod.orangeMoney:
        return localizations.get('orange_money');
      case PaymentMethod.wave:
        return localizations.get('wave');
      case PaymentMethod.card:
        return localizations.get('card');
      default:
        return '';
    }
  }
}
