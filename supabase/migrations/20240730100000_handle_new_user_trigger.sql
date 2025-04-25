-- Function to handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  -- Insert into public.profiles
  insert into public.profiles (user_id, email, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'role' -- Extract role from metadata
  );
  
  return new;
end;
$$;

-- Trigger to call the function after user creation
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user(); 