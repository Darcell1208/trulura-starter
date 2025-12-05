// src/context/TruluraDataProvider.js
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { supabase } from '../lib/supabase';

// Tables: glows, sparks, vents  (all with id, created_at, ...)

const TruluraDataContext = createContext(null);

// --- helpers to keep field names consistent in the app --- //
function normalizeRow(row) {
  if (!row) return row;
  // copy created_at into createdAt for UI
  if ('created_at' in row && !row.createdAt) {
    return { ...row, createdAt: row.created_at };
  }
  return row;
}

function normalizeList(list) {
  return (list || []).map(normalizeRow);
}

// Apply realtime changes from Supabase into a local array
function applyChange(list, payload) {
  const { eventType, new: newRow, old: oldRow } = payload;

  const n = normalizeRow(newRow);
  const o = normalizeRow(oldRow);

  if (eventType === 'INSERT') {
    return n ? [n, ...list] : list;
  }
  if (eventType === 'UPDATE') {
    return list.map(r => (r.id === n.id ? { ...r, ...n } : r));
  }
  if (eventType === 'DELETE') {
    const deleteId = o?.id ?? -1;
    return list.filter(r => r.id !== deleteId);
  }
  return list;
}

export function TruluraDataProvider({ children }) {
  const [glows, setGlows] = useState([]);
  const [sparks, setSparks] = useState([]);
  const [vents, setVents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // keep a ref so we can clean channels on remounts
  const channelRef = useRef(null);

  const fetchAll = useCallback(async () => {
    setError(null);
    setLoading(true);
    try {
      const [g, s, v] = await Promise.all([
        supabase
          .from('glows')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase
          .from('sparks')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase
          .from('vents')
          .select('*')
          .order('created_at', { ascending: false }),
      ]);

      if (g.error) throw g.error;
      if (s.error) throw s.error;
      if (v.error) throw v.error;

      setGlows(normalizeList(g.data));
      setSparks(normalizeList(s.data));
      setVents(normalizeList(v.data));
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  // Live updates via Postgres changes
  useEffect(() => {
    // clean any previous channel
    if (channelRef.current) {
      supabase.removeChannel(channelRef.current);
      channelRef.current = null;
    }

    const channel = supabase
      .channel('trulura-live')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'glows' },
        payload => {
          setGlows(prev => applyChange(prev, payload));
        },
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'sparks' },
        payload => {
          setSparks(prev => applyChange(prev, payload));
        },
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'vents' },
        payload => {
          setVents(prev => applyChange(prev, payload));
        },
      )
      .subscribe(status => {
        // simple debug hook
        if (status !== 'SUBSCRIBED') {
          console.log('Realtime status:', status);
        }
      });

    channelRef.current = channel;

    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
    };
  }, []);

  const refreshAll = useCallback(() => fetchAll(), [fetchAll]);

  // --- Spark helpers (used by SparkScreen) --- //
  const addSpark = useCallback(async (text, mood) => {
    const body = { text, mood };
    try {
      const { data, error: err } = await supabase
        .from('sparks')
        .insert([body])
        .select();
      if (err) throw err;

      const row = normalizeRow(data?.[0]);
      if (row) {
        // immediate UI update; realtime will keep it in sync
        setSparks(prev => [row, ...prev]);
      }
    } catch (e) {
      console.error('addSpark error', e);
      setError(e.message || String(e));
    }
  }, []);

  const deleteSpark = useCallback(async id => {
    try {
      const { error: err } = await supabase
        .from('sparks')
        .delete()
        .eq('id', id);
      if (err) throw err;

      setSparks(prev => prev.filter(r => r.id !== id));
    } catch (e) {
      console.error('deleteSpark error', e);
      setError(e.message || String(e));
    }
  }, []);

  // --- Vent helpers (used by VentScreen) --- //
  const addVent = useCallback(async (text, mood) => {
    const body = { text, mood };
    try {
      const { data, error: err } = await supabase
        .from('vents')
        .insert([body])
        .select();
      if (err) throw err;

      const row = normalizeRow(data?.[0]);
      if (row) {
        setVents(prev => [row, ...prev]);
      }
    } catch (e) {
      console.error('addVent error', e);
      setError(e.message || String(e));
    }
  }, []);

  const deleteVent = useCallback(async id => {
    try {
      const { error: err } = await supabase
        .from('vents')
        .delete()
        .eq('id', id);
      if (err) throw err;

      setVents(prev => prev.filter(r => r.id !== id));
    } catch (e) {
      console.error('deleteVent error', e);
      setError(e.message || String(e));
    }
  }, []);

  const value = useMemo(
    () => ({
      glows,
      sparks,
      vents,
      loading,
      error,
      refreshAll,
      addSpark,
      deleteSpark,
      addVent,
      deleteVent,
    }),
    [
      glows,
      sparks,
      vents,
      loading,
      error,
      refreshAll,
      addSpark,
      deleteSpark,
      addVent,
      deleteVent,
    ],
  );

  return (
    <TruluraDataContext.Provider value={value}>
      {children}
    </TruluraDataContext.Provider>
  );
}

export function useTruluraData() {
  const ctx = useContext(TruluraDataContext);
  if (!ctx) throw new Error('useTruluraData must be used inside <TruluraDataProvider>');
  return ctx;
}
