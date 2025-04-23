import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Bus Reservation',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone Number',
      'full_name': 'Full Name',
      'traveler': 'Traveler',
      'transporteur': 'Bus Operator',
      'admin': 'Administrator',
      'search': 'Search',
      'departure': 'Departure',
      'arrival': 'Arrival',
      'date': 'Date',
      'time': 'Time',
      'book_now': 'Book Now',
      'passenger_info': 'Passenger Information',
      'cni_number': 'ID Card Number',
      'payment': 'Payment',
      'orange_money': 'Orange Money',
      'wave': 'Wave',
      'card': 'Credit/Debit Card',
      'my_bookings': 'My Bookings',
      'profile': 'Profile',
      'logout': 'Log Out',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'fleet': 'Fleet',
      'trips': 'Trips',
      'reservations': 'Reservations',
      'scanner': 'Ticket Scanner',
      'analytics': 'Analytics',
      'add_bus': 'Add Bus',
      'create_trip': 'Create Trip',
      'bus_name': 'Bus Name',
      'capacity': 'Capacity',
      'bus_type': 'Bus Type',
      'fare': 'Fare',
      'available_seats': 'Available Seats',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'status': 'Status',
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'cancelled': 'Cancelled',
      'completed': 'Completed',
      'refunded': 'Refunded',
      'sync_now': 'Sync Now',
      'download': 'Download',
      'offline_mode': 'Offline Mode',
      'scan_ticket': 'Scan Ticket',
      'enter_cni': 'Enter ID Number',
      'validation_success': 'Ticket Validated Successfully',
      'validation_error': 'Validation Failed',
      'no_internet': 'No Internet Connection',
      'syncing': 'Syncing Data...',
      'sync_complete': 'Sync Complete',
      'sync_error': 'Sync Error',
      'pending_sync': 'Pending Sync',
    },
    'fr': {
      'app_name': 'Réservation de Bus',
      'login': 'Connexion',
      'signup': 'Inscription',
      'email': 'Email',
      'password': 'Mot de passe',
      'phone': 'Numéro de téléphone',
      'full_name': 'Nom complet',
      'traveler': 'Voyageur',
      'transporteur': 'Transporteur',
      'admin': 'Administrateur',
      'search': 'Rechercher',
      'departure': 'Départ',
      'arrival': 'Arrivée',
      'date': 'Date',
      'time': 'Heure',
      'book_now': 'Réserver maintenant',
      'passenger_info': 'Informations passager',
      'cni_number': 'Numéro de CNI',
      'payment': 'Paiement',
      'orange_money': 'Orange Money',
      'wave': 'Wave',
      'card': 'Carte bancaire',
      'my_bookings': 'Mes réservations',
      'profile': 'Profil',
      'logout': 'Déconnexion',
      'settings': 'Paramètres',
      'notifications': 'Notifications',
      'fleet': 'Flotte',
      'trips': 'Voyages',
      'reservations': 'Réservations',
      'scanner': 'Scanner de billets',
      'analytics': 'Analyses',
      'add_bus': 'Ajouter un bus',
      'create_trip': 'Créer un voyage',
      'bus_name': 'Nom du bus',
      'capacity': 'Capacité',
      'bus_type': 'Type de bus',
      'fare': 'Tarif',
      'available_seats': 'Places disponibles',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'status': 'Statut',
      'pending': 'En attente',
      'confirmed': 'Confirmé',
      'cancelled': 'Annulé',
      'completed': 'Terminé',
      'refunded': 'Remboursé',
      'sync_now': 'Synchroniser',
      'download': 'Télécharger',
      'offline_mode': 'Mode hors ligne',
      'scan_ticket': 'Scanner le billet',
      'enter_cni': 'Entrer le numéro CNI',
      'validation_success': 'Billet validé avec succès',
      'validation_error': 'Échec de la validation',
      'no_internet': 'Pas de connexion Internet',
      'syncing': 'Synchronisation des données...',
      'sync_complete': 'Synchronisation terminée',
      'sync_error': 'Erreur de synchronisation',
      'pending_sync': 'Synchronisation en attente',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
