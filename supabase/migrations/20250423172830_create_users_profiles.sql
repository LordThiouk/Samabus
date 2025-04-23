-- Migration: Create initial database schema (users, profiles, buses, trips, bookings, etc.)
-- Timestamp: Replace YYYYMMDDHHMMSS with actual timestamp

-- 1. Create the public.users table to store role and link to auth.users
CREATE TABLE public.users (
  id UUID PRIMARY KEY NOT NULL,
  -- email TEXT UNIQUE NOT NULL, -- Email is in auth.users, no need to duplicate unless for specific query optimization
  role TEXT NOT NULL CHECK (role IN ('traveler','bus_owner','admin')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add comments explaining the table's purpose
COMMENT ON TABLE public.users IS 'Stores user roles and references the master authentication user.';
COMMENT ON COLUMN public.users.id IS 'References the internal Supabase auth user id.';
COMMENT ON COLUMN public.users.role IS 'Defines the user role within the application (traveler, bus_owner, admin).';

-- 2. Add foreign key constraint from public.users.id to auth.users.id
ALTER TABLE public.users 
ADD CONSTRAINT users_id_fkey 
FOREIGN KEY (id) REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- 3. Create the public.profiles table for additional user information
CREATE TABLE public.profiles (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT UNIQUE, -- Consider adding constraint for format if needed
  company_name TEXT, -- Specific to bus owners
  approved BOOLEAN DEFAULT FALSE, -- Bus owners need approval
  approval_date TIMESTAMPTZ
);

-- Add comments for profiles table
COMMENT ON TABLE public.profiles IS 'Stores user profile information, extending the base user data.';
COMMENT ON COLUMN public.profiles.user_id IS 'Links profile to the corresponding user in public.users.';
COMMENT ON COLUMN public.profiles.phone IS 'User contact phone number, should be unique.';
COMMENT ON COLUMN public.profiles.company_name IS 'Company name for users with the bus_owner role.';
COMMENT ON COLUMN public.profiles.approved IS 'Flag indicating if a bus_owner account has been approved by an admin.';

-- 4. Consider indexes for frequently queried columns
-- CREATE INDEX idx_profiles_phone ON public.profiles (phone);
-- CREATE INDEX idx_profiles_company_name ON public.profiles (company_name) WHERE role = 'bus_owner'; -- Example conditional index

-- 5. Define BUSES table
CREATE TABLE public.buses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  capacity INTEGER NOT NULL CHECK (capacity > 0),
  type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
COMMENT ON TABLE public.buses IS 'Stores information about buses registered by transporteurs (bus_owners).';
COMMENT ON COLUMN public.buses.owner_id IS 'Links the bus to its owner in the users table.';

-- 6. Define TRIPS table
CREATE TABLE public.trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id UUID NOT NULL REFERENCES public.buses(id) ON DELETE RESTRICT,
  departure_city TEXT NOT NULL,
  destination_city TEXT NOT NULL,
  departure_time TIMESTAMPTZ NOT NULL,
  arrival_time TIMESTAMPTZ,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  total_seats INTEGER NOT NULL CHECK (total_seats > 0),
  available_seats INTEGER NOT NULL CHECK (available_seats >= 0 AND available_seats <= total_seats),
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'departed', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
COMMENT ON TABLE public.trips IS 'Represents scheduled bus trips created by transporteurs.';
COMMENT ON COLUMN public.trips.available_seats IS 'Number of seats currently available for booking.';
COMMENT ON COLUMN public.trips.status IS 'Current status of the trip.';

-- 7. Define BOOKINGS table
CREATE TABLE public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE RESTRICT,
  traveler_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  num_seats INTEGER NOT NULL CHECK (num_seats > 0),
  total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','cancelled','refunded')),
  booked_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
COMMENT ON TABLE public.bookings IS 'Records reservations made by travelers for specific trips.';
COMMENT ON COLUMN public.bookings.status IS 'Current status of the booking (pending until payment).';

-- 8. Define PASSENGERS table
CREATE TABLE public.passengers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  cni TEXT NOT NULL,
  qr_code TEXT UNIQUE
);
COMMENT ON TABLE public.passengers IS 'Stores details for each passenger included in a booking.';
COMMENT ON COLUMN public.passengers.cni IS 'National Identity Card number, required for validation.';
COMMENT ON COLUMN public.passengers.qr_code IS 'Unique QR code identifier generated for this passenger seat.';

-- 9. Define PAYMENTS table
CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE RESTRICT,
  provider TEXT NOT NULL,
  provider_ref TEXT UNIQUE,
  amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
  commission_amount NUMERIC(10, 2) NOT NULL CHECK (commission_amount >= 0),
  status TEXT NOT NULL CHECK (status IN ('initiated','success','failed', 'refunded')),
  transaction_date TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  processed_at TIMESTAMPTZ
);
COMMENT ON TABLE public.payments IS 'Tracks payment transactions related to bookings.';
COMMENT ON COLUMN public.payments.provider_ref IS 'Unique transaction ID from the payment gateway.';
COMMENT ON COLUMN public.payments.commission_amount IS 'The 5% commission calculated for this payment.';

-- 10. Define NOTIFICATIONS table
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  channel TEXT NOT NULL CHECK (channel IN ('email', 'sms', 'push', 'in_app')),
  content TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
COMMENT ON TABLE public.notifications IS 'Logs notifications sent to users.';

-- 11. Define SCAN_LOGS table
CREATE TABLE public.scan_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE RESTRICT,
  validator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
  scanned_data_type TEXT NOT NULL CHECK (scanned_data_type IN ('qr_code', 'cni')),
  scanned_value TEXT NOT NULL,
  validation_status BOOLEAN NOT NULL,
  scanned_at TIMESTAMPTZ NOT NULL,
  synced BOOLEAN DEFAULT FALSE NOT NULL,
  synced_at TIMESTAMPTZ
);
COMMENT ON TABLE public.scan_logs IS 'Stores logs of offline ticket validation attempts.';
COMMENT ON COLUMN public.scan_logs.validator_id IS 'The user (driver/agent) who performed the scan.';
COMMENT ON COLUMN public.scan_logs.validation_status IS 'Result of the validation check against local data.';
COMMENT ON COLUMN public.scan_logs.synced IS 'Indicates if this offline log has been successfully uploaded.';

-- 12. Ensure RLS is enabled for all tables (can be done in Supabase UI or separate migration)
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY; -- Already mentioned
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY; -- Already mentioned
-- ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.scan_logs ENABLE ROW LEVEL SECURITY;

-- RLS policies themselves will be defined later or in a separate migration file. 