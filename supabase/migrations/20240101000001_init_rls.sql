-- RLS Policies and Helper Functions

-- Helper function to get user role from JWT claims
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT nullif(current_setting('request.jwt.claims', true)::jsonb->>'user_role', '')::TEXT;
$$;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT get_my_role() = 'admin';
$$;

-- Helper function to check if user is bus owner
CREATE OR REPLACE FUNCTION is_bus_owner()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT get_my_role() = 'bus_owner';
$$;

-- Helper function to check if user is traveler
CREATE OR REPLACE FUNCTION is_traveler()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT get_my_role() = 'traveler';
$$;

-- Enable RLS for all relevant tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (if any) before creating new ones
DROP POLICY IF EXISTS "Allow individual user access on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin full access on profiles" ON public.profiles;

DROP POLICY IF EXISTS "Allow public read access on buses" ON public.buses;
DROP POLICY IF EXISTS "Allow bus_owner insert access" ON public.buses;
DROP POLICY IF EXISTS "Allow bus_owner update access" ON public.buses;
DROP POLICY IF EXISTS "Allow bus_owner delete access" ON public.buses;
DROP POLICY IF EXISTS "Allow admin full access on buses" ON public.buses;

DROP POLICY IF EXISTS "Allow public read access on trips" ON public.trips;
DROP POLICY IF EXISTS "Allow bus_owner insert access for their buses" ON public.trips;
DROP POLICY IF EXISTS "Allow bus_owner update access for their trips" ON public.trips;
DROP POLICY IF EXISTS "Allow bus_owner delete access for their trips" ON public.trips;
DROP POLICY IF EXISTS "Allow admin full access on trips" ON public.trips;

DROP POLICY IF EXISTS "Allow traveler read access on own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Allow bus_owner read access on their trip bookings" ON public.bookings;
DROP POLICY IF EXISTS "Allow traveler insert access" ON public.bookings;
DROP POLICY IF EXISTS "Allow traveler update access for cancellation" ON public.bookings;
DROP POLICY IF EXISTS "Allow admin full access on bookings" ON public.bookings;

DROP POLICY IF EXISTS "Allow traveler read access on own passengers" ON public.passengers;
DROP POLICY IF EXISTS "Allow bus_owner read access on their trip passengers" ON public.passengers;
DROP POLICY IF EXISTS "Allow traveler insert access for own bookings" ON public.passengers;
DROP POLICY IF EXISTS "Allow admin full access on passengers" ON public.passengers;

DROP POLICY IF EXISTS "Allow traveler read access on own payments" ON public.payments;
DROP POLICY IF EXISTS "Allow bus_owner read access on their trip payments" ON public.payments;
DROP POLICY IF EXISTS "Allow admin full access on payments" ON public.payments;

DROP POLICY IF EXISTS "Allow individual read access" ON public.notifications;
DROP POLICY IF EXISTS "Allow individual update access" ON public.notifications;
DROP POLICY IF EXISTS "Allow individual delete access" ON public.notifications;
DROP POLICY IF EXISTS "Allow admin read access" ON public.notifications;
DROP POLICY IF EXISTS "Allow admin delete access" ON public.notifications;

DROP POLICY IF EXISTS "Allow bus_owner read access on their trip scans" ON public.scan_logs;
DROP POLICY IF EXISTS "Allow authenticated users insert access" ON public.scan_logs;
DROP POLICY IF EXISTS "Allow scanner update access for sync status" ON public.scan_logs;
DROP POLICY IF EXISTS "Allow admin full access on scan_logs" ON public.scan_logs;


-- *** PROFILES POLICIES ***
CREATE POLICY "Allow individual user access on profiles" ON public.profiles
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow admin full access on profiles" ON public.profiles
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- *** BUSES POLICIES ***
CREATE POLICY "Allow public read access on buses" ON public.buses
  FOR SELECT USING (true);
CREATE POLICY "Allow bus_owner insert access" ON public.buses
  FOR INSERT WITH CHECK (is_bus_owner() AND owner_id = auth.uid());
CREATE POLICY "Allow bus_owner update access" ON public.buses
  FOR UPDATE USING (is_bus_owner() AND owner_id = auth.uid()) WITH CHECK (is_bus_owner() AND owner_id = auth.uid());
CREATE POLICY "Allow bus_owner delete access" ON public.buses
  FOR DELETE USING (is_bus_owner() AND owner_id = auth.uid());
CREATE POLICY "Allow admin full access on buses" ON public.buses
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- *** TRIPS POLICIES ***
CREATE POLICY "Allow public read access on trips" ON public.trips
  FOR SELECT USING (true);
CREATE POLICY "Allow bus_owner insert access for their buses" ON public.trips
  FOR INSERT WITH CHECK (
    is_bus_owner() AND
    EXISTS (SELECT 1 FROM public.buses WHERE id = trips.bus_id AND owner_id = auth.uid())
  );
CREATE POLICY "Allow bus_owner update access for their trips" ON public.trips
  FOR UPDATE USING (
    is_bus_owner() AND
    EXISTS (SELECT 1 FROM public.buses WHERE id = trips.bus_id AND owner_id = auth.uid())
  ) WITH CHECK (
    is_bus_owner() AND
    EXISTS (SELECT 1 FROM public.buses WHERE id = trips.bus_id AND owner_id = auth.uid())
  );
CREATE POLICY "Allow bus_owner delete access for their trips" ON public.trips
  FOR DELETE USING (
    is_bus_owner() AND
    EXISTS (SELECT 1 FROM public.buses WHERE id = trips.bus_id AND owner_id = auth.uid())
  );
CREATE POLICY "Allow admin full access on trips" ON public.trips
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- *** BOOKINGS POLICIES ***
CREATE POLICY "Allow traveler read access on own bookings" ON public.bookings
  FOR SELECT USING (is_traveler() AND traveler_id = auth.uid());
CREATE POLICY "Allow bus_owner read access on their trip bookings" ON public.bookings
  FOR SELECT USING (
    is_bus_owner() AND
    EXISTS (
      SELECT 1 FROM public.trips t JOIN public.buses b ON t.bus_id = b.id
      WHERE t.id = bookings.trip_id AND b.owner_id = auth.uid()
    )
  );
CREATE POLICY "Allow traveler insert access" ON public.bookings
  FOR INSERT WITH CHECK (is_traveler() AND traveler_id = auth.uid());
CREATE POLICY "Allow traveler update access for cancellation" ON public.bookings
  FOR UPDATE USING (is_traveler() AND traveler_id = auth.uid()) WITH CHECK (is_traveler() AND traveler_id = auth.uid() AND status = 'cancelled');
CREATE POLICY "Allow admin full access on bookings" ON public.bookings
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- *** PASSENGERS POLICIES ***
CREATE POLICY "Allow traveler read access on own passengers" ON public.passengers
  FOR SELECT USING (
    is_traveler() AND
    EXISTS (SELECT 1 FROM public.bookings WHERE id = passengers.booking_id AND traveler_id = auth.uid())
  );
CREATE POLICY "Allow bus_owner read access on their trip passengers" ON public.passengers
  FOR SELECT USING (
    is_bus_owner() AND
    EXISTS (
      SELECT 1 FROM public.bookings bk
      JOIN public.trips t ON bk.trip_id = t.id
      JOIN public.buses b ON t.bus_id = b.id
      WHERE bk.id = passengers.booking_id AND b.owner_id = auth.uid()
    )
  );
CREATE POLICY "Allow traveler insert access for own bookings" ON public.passengers
  FOR INSERT WITH CHECK (
    is_traveler() AND
    EXISTS (SELECT 1 FROM public.bookings WHERE id = passengers.booking_id AND traveler_id = auth.uid())
  );
CREATE POLICY "Allow admin full access on passengers" ON public.passengers
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- *** PAYMENTS POLICIES ***
CREATE POLICY "Allow traveler read access on own payments" ON public.payments
  FOR SELECT USING (
    is_traveler() AND
    EXISTS (SELECT 1 FROM public.bookings WHERE id = payments.booking_id AND traveler_id = auth.uid())
  );
CREATE POLICY "Allow bus_owner read access on their trip payments" ON public.payments
  FOR SELECT USING (
    is_bus_owner() AND
    EXISTS (
      SELECT 1 FROM public.bookings bk
      JOIN public.trips t ON bk.trip_id = t.id
      JOIN public.buses b ON t.bus_id = b.id
      WHERE bk.id = payments.booking_id AND b.owner_id = auth.uid()
    )
  );
CREATE POLICY "Allow admin full access on payments" ON public.payments
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- *** NOTIFICATIONS POLICIES ***
CREATE POLICY "Allow individual read access" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow individual update access" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual delete access" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Allow admin read access" ON public.notifications
  FOR SELECT USING (is_admin());
CREATE POLICY "Allow admin delete access" ON public.notifications
  FOR DELETE USING (is_admin());

-- *** SCAN_LOGS POLICIES ***
CREATE POLICY "Allow bus_owner read access on their trip scans" ON public.scan_logs
  FOR SELECT USING (
    is_bus_owner() AND
    EXISTS (
      SELECT 1 FROM public.trips t JOIN public.buses b ON t.bus_id = b.id
      WHERE t.id = scan_logs.trip_id AND b.owner_id = auth.uid()
    )
  );
CREATE POLICY "Allow authenticated users insert access" ON public.scan_logs
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND scanner_user_id = auth.uid());
CREATE POLICY "Allow scanner update access for sync status" ON public.scan_logs
  FOR UPDATE USING (scanner_user_id = auth.uid() AND NOT is_synced) WITH CHECK (scanner_user_id = auth.uid());
CREATE POLICY "Allow admin full access on scan_logs" ON public.scan_logs
  FOR ALL USING (is_admin()) WITH CHECK (is_admin()); 