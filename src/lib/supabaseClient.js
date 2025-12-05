import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import 'react-native-url-polyfill/auto';

const SUPABASE_URL = 'https://wzcuxarslnbvaosuqduu.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6Y3V4YXJzbG5idmFvc3VxZHV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3MjcyNzcsImV4cCI6MjA3ODMwMzI3N30.D2A8ELxDUH4UM1TQ8JYPm7jVVb28RF_Bz83l_rBZGh0';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
