-- Migration: Enable RLS and define initial policies
-- Timestamp: Replace YYYYMMDDHHMMSS with actual timestamp

BEGIN;

-- 1. Enable RLS for all relevant tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_logs ENABLE ROW LEVEL SECURITY;

-- 2. Trips Policies
-- Allow public read access for trips (anyone can search)
DROP POLICY IF EXISTS "Allow public read access for trips" ON public.trips;
CREATE POLICY "Allow public read access for trips" ON public.trips
FOR SELECT USING (true);

-- Allow bus owners to manage trips associated with their buses
DROP POLICY IF EXISTS "Allow bus_owner access to own trips" ON public.trips;
CREATE POLICY "Allow bus_owner access to own trips" ON public.trips
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.buses
    WHERE buses.id = trips.bus_id AND buses.owner_id = auth.uid() AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.buses
    WHERE buses.id = trips.bus_id AND buses.owner_id = auth.uid() AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner'
  )
);

-- 3. Users Policies
-- Allow authenticated users to read their own user record
DROP POLICY IF EXISTS "Allow individual user read access" ON public.users;
CREATE POLICY "Allow individual user read access" ON public.users
FOR SELECT USING (auth.uid() = id);

-- 4. Profiles Policies
-- Allow authenticated users to read their own profile
DROP POLICY IF EXISTS "Allow individual profile read access" ON public.profiles;
CREATE POLICY "Allow individual profile read access" ON public.profiles
FOR SELECT USING (auth.uid() = user_id);

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Allow individual profile update" ON public.profiles;
CREATE POLICY "Allow individual profile update" ON public.profiles
FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 5. Bookings Policies
-- Allow travelers to manage their own bookings
DROP POLICY IF EXISTS "Allow traveler access to own bookings" ON public.bookings;
CREATE POLICY "Allow traveler access to own bookings" ON public.bookings
FOR ALL USING (auth.uid() = traveler_id) WITH CHECK (auth.uid() = traveler_id);

-- Allow bus owners to view bookings for their trips
DROP POLICY IF EXISTS "Allow bus_owner read access to their trip bookings" ON public.bookings;
CREATE POLICY "Allow bus_owner read access to their trip bookings" ON public.bookings
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.trips t JOIN public.buses b ON t.bus_id = b.id
    WHERE t.id = bookings.trip_id AND b.owner_id = auth.uid() AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner'
  )
);

-- 6. Passengers Policies
-- Allow travelers to view passengers associated with their own bookings
DROP POLICY IF EXISTS "Allow traveler read access to own passengers" ON public.passengers;
CREATE POLICY "Allow traveler read access to own passengers" ON public.passengers
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.bookings
    WHERE bookings.id = passengers.booking_id AND bookings.traveler_id = auth.uid()
  )
);

-- Allow bus owners to view passengers for their trip bookings
DROP POLICY IF EXISTS "Allow bus_owner read access to their trip passengers" ON public.passengers;
CREATE POLICY "Allow bus_owner read access to their trip passengers" ON public.passengers
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.bookings bk JOIN public.trips t ON bk.trip_id = t.id JOIN public.buses b ON t.bus_id = b.id
    WHERE bk.id = passengers.booking_id AND b.owner_id = auth.uid() AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner'
  )
);

-- 7. Buses Policies
-- Allow bus owners to manage their own buses
DROP POLICY IF EXISTS "Allow bus_owner access to own buses" ON public.buses;
CREATE POLICY "Allow bus_owner access to own buses" ON public.buses
FOR ALL USING (auth.uid() = owner_id AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner')
WITH CHECK (auth.uid() = owner_id AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner');

-- 8. Scan Logs Policies
-- Allow bus owners/validators to create scan logs for their trips
DROP POLICY IF EXISTS "Allow bus_owner/validator create access for scan logs" ON public.scan_logs;
CREATE POLICY "Allow bus_owner/validator create access for scan logs" ON public.scan_logs
FOR INSERT WITH CHECK (
  validator_id = auth.uid() AND
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner' AND -- Simplification: Only bus_owner can scan for now
  EXISTS (
    SELECT 1 FROM public.trips t JOIN public.buses b ON t.bus_id = b.id
    WHERE t.id = scan_logs.trip_id AND b.owner_id = auth.uid()
  )
);

-- Allow bus owners to read scan logs for their trips
DROP POLICY IF EXISTS "Allow bus_owner read access for own scan logs" ON public.scan_logs;
CREATE POLICY "Allow bus_owner read access for own scan logs" ON public.scan_logs
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.trips t JOIN public.buses b ON t.bus_id = b.id
    WHERE t.id = scan_logs.trip_id AND b.owner_id = auth.uid() AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'bus_owner'
  )
);

-- 9. Admin Policies (Example - Consider using service_role for true bypass)
DROP POLICY IF EXISTS "Allow admin full access" ON public.users; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.profiles; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.buses; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.trips; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.bookings; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.passengers; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.payments; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.notifications; 
DROP POLICY IF EXISTS "Allow admin full access" ON public.scan_logs; 

CREATE POLICY "Allow admin full access" ON public.users FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.profiles FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.buses FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.trips FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.bookings FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.passengers FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.payments FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.notifications FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Allow admin full access" ON public.scan_logs FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

-- Note: Policies for 'payments' and 'notifications' might need further refinement based on specific logic.

COMMIT; 