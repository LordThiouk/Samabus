/// Represents the status of a booking.
enum BookingStatus {
  pending,    // Booking initiated but not confirmed (e.g., awaiting payment)
  confirmed,  // Booking paid and confirmed
  cancelled,  // Booking cancelled by user or operator
  completed,  // Trip completed
  refunded,   // Booking cancelled and refunded
  error       // An error occurred during booking/payment
}

/// Represents the available payment methods.
enum PaymentMethod {
  orangeMoney,
  wave,
  creditCard, // Or specify Visa/Mastercard if needed
  unknown     // Default or error case
} 