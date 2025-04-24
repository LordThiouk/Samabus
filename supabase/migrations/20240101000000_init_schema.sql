-- Initial Schema Setup for Bus Booking Platform

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PROFILES Table (Extends Supabase Auth users)
CREATE TABLE public.profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  company_name TEXT,
  is_approved BOOLEAN DEFAULT FALSE,
  approval_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Trigger for profiles updated_at
CREATE TRIGGER set_profiles_timestamp
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- Function to create profile on new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
begin
  INSERT INTO public.profiles (user_id, phone, full_name)
  VALUES (
    new.id,
    new.phone,
    new.raw_user_meta_data->>'full_name'
  );
  -- Attempt to set the user role from metadata if provided during signup
  -- Note: This requires custom logic during signup or a post-signup function
  -- to add the 'user_role' claim needed for RLS helper functions.
  -- Example: UPDATE auth.users SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object('user_role', new.raw_user_meta_data->>'role') WHERE id = new.id;
  return new;
end;
$$;
-- Trigger to create profile on auth user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- BUSES Table
CREATE TABLE public.buses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  capacity INTEGER NOT NULL CHECK (capacity > 0),
  type TEXT,
  license_plate TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Trigger for buses updated_at
CREATE TRIGGER set_buses_timestamp
BEFORE UPDATE ON public.buses
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();


-- TRIPS Table
CREATE TABLE public.trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id UUID REFERENCES public.buses(id) ON DELETE SET NULL,
  departure_city TEXT NOT NULL,
  destination_city TEXT NOT NULL,
  departure_timestamp TIMESTAMPTZ NOT NULL,
  arrival_timestamp TIMESTAMPTZ,
  price_per_seat NUMERIC(10, 2) NOT NULL CHECK (price_per_seat >= 0),
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'departed', 'arrived', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Trigger for trips updated_at
CREATE TRIGGER set_trips_timestamp
BEFORE UPDATE ON public.trips
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();


-- BOOKINGS Table
CREATE TABLE public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
  traveler_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  num_seats INTEGER NOT NULL CHECK (num_seats > 0),
  total_amount NUMERIC(10, 2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'refunded')),
  booked_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Trigger for bookings updated_at
CREATE TRIGGER set_bookings_timestamp
BEFORE UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();


-- PASSENGERS Table
CREATE TABLE public.passengers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
  seat_number TEXT,
  full_name TEXT NOT NULL,
  cni TEXT NOT NULL,
  qr_code_data TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_passengers_booking_id ON public.passengers(booking_id);
CREATE INDEX idx_passengers_qr_code_data ON public.passengers(qr_code_data);


-- PAYMENTS Table
CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  payment_provider TEXT NOT NULL,
  provider_transaction_id TEXT UNIQUE,
  amount NUMERIC(10, 2) NOT NULL,
  commission_amount NUMERIC(10, 2) GENERATED ALWAYS AS (amount * 0.05) STORED,
  status TEXT NOT NULL CHECK (status IN ('initiated', 'success', 'failed', 'refunded')),
  transaction_timestamp TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Trigger for payments updated_at
CREATE TRIGGER set_payments_timestamp
BEFORE UPDATE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();
CREATE INDEX idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX idx_payments_provider_transaction_id ON public.payments(provider_transaction_id);


-- NOTIFICATIONS Table
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  channel TEXT NOT NULL CHECK (channel IN ('email', 'sms', 'push')),
  content TEXT,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ
);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);


-- SCAN_LOGS Table
CREATE TABLE public.scan_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL,
  scanner_user_id UUID NOT NULL,
  scanned_data TEXT NOT NULL,
  scanned_at TIMESTAMPTZ NOT NULL,
  validation_status TEXT NOT NULL CHECK (validation_status IN ('valid', 'invalid', 'duplicate')),
  device_id TEXT,
  is_synced BOOLEAN DEFAULT FALSE,
  synced_at TIMESTAMPTZ
);
CREATE INDEX idx_scan_logs_trip_id ON public.scan_logs(trip_id);
CREATE INDEX idx_scan_logs_scanner_user_id ON public.scan_logs(scanner_user_id);
CREATE INDEX idx_scan_logs_is_synced ON public.scan_logs(is_synced);
CREATE INDEX idx_scan_logs_scanned_at ON public.scan_logs(scanned_at); 