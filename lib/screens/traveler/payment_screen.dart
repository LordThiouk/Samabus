import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../utils/localization.dart';
import 'booking_confirmation_screen.dart';
import '../../models/enums.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.orangeMoney;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    if (bookingProvider.currentBooking == null) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final success = await bookingProvider.processPayment(
      bookingId: bookingProvider.currentBooking!.id!,
      paymentMethod: _selectedPaymentMethod,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BookingConfirmationScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? 'Payment failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    if (bookingProvider.currentBooking == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.get('payment')),
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
        title: Text(localizations.get('payment')),
      ),
      body: Column(
        children: [
          // Booking summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.get('booking_summary'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.passengers.length} ${booking.passengers.length == 1 ? 'passenger' : 'passengers'}',
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(booking.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Payment methods
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  localizations.get('select_payment_method'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // Orange Money
                _buildPaymentMethodCard(
                  context,
                  PaymentMethod.orangeMoney,
                  'assets/images/orange_money.png',
                  localizations.get('orange_money'),
                ),
                
                // Wave
                _buildPaymentMethodCard(
                  context,
                  PaymentMethod.wave,
                  'assets/images/wave.png',
                  localizations.get('wave'),
                ),
                
                // Credit/Debit Card
                _buildPaymentMethodCard(
                  context,
                  PaymentMethod.creditCard,
                  'assets/images/credit_card.png',
                  localizations.get('card'),
                ),
                
                const SizedBox(height: 24),
                
                // Phone number input
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: localizations.get('phone'),
                    hintText: '+221 XX XXX XX XX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 24),
                
                // Payment summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.get('payment_summary'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localizations.get('subtotal')),
                            Text(currencyFormat.format(booking.totalAmount - (booking.platformFee ?? 0.0))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localizations.get('platform_fee')),
                            Text(currencyFormat.format(booking.platformFee ?? 0.0)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localizations.get('total'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currencyFormat.format(booking.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                onPressed: _isProcessing || bookingProvider.isLoading
                    ? null
                    : _processPayment,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing || bookingProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        localizations.get('pay_now'),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    PaymentMethod method,
    String imagePath,
    String title,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 40,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        method == PaymentMethod.orangeMoney
                            ? Icons.account_balance_wallet
                            : method == PaymentMethod.wave
                                ? Icons.waves
                                : Icons.credit_card,
                        color: Colors.grey[700],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Radio<PaymentMethod>(
                value: method,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
