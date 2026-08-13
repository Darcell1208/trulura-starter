// src/screens/ExploreScreen.js
import { useCallback, useEffect, useMemo, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { supabase } from '../lib/supabase';
import { useTheme } from '../theme/ThemeProvider';

const FILTERS = ['All', 'Glow', 'Spark', 'Vent'];

export default function ExploreScreen() {
  const { palettes } = useTheme();

  const [active, setActive] = useState('All');
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);

    const [glowsRes, sparksRes, ventsRes] = await Promise.all([
      supabase
        .from('glow_sessions')
        .select('*')
        .order('started_at', { ascending: false })
        .limit(20),
      supabase
        .from('sparks')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(20),
      supabase
        .from('vents')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(20),
    ]);

    const normalized = [
      ...(glowsRes.data ?? []).map(r => ({
        id: `g_${r.id}`,
        type: 'Glow',
        text: r.note || r.mood,
        at: new Date(
          r.started_at || r.completed_at || r.created_at || Date.now()
        ).getTime(),
      })),
      ...(sparksRes.data ?? []).map(r => ({
        id: `s_${r.id}`,
        type: 'Spark',
        text: r.text || r.mood,
        at: new Date(r.created_at || Date.now()).getTime(),
      })),
      ...(ventsRes.data ?? []).map(r => ({
        id: `v_${r.id}`,
        type: 'Vent',
        text: r.text || r.mood,
        at: new Date(r.created_at || Date.now()).getTime(),
      })),
    ].sort((a, b) => b.at - a.at);

    setItems(normalized);
    setLoading(false);
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const filtered = useMemo(() => {
    if (active === 'All') return items;
    return items.filter(i => i.type === active);
  }, [active, items]);

  const bg = palettes.ink || '#0b0f17';
  const cardBg = palettes.card || '#0f1421';
  const textPrimary = palettes.white || '#e7ecff';
  const textSecondary = palettes.dim || '#a5b2d6';
  const pillActive = palettes.explore || '#44D2C3';

  return (
    <View style={[styles.screen, { backgroundColor: bg }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: textPrimary }]}>Explore</Text>
        <Text style={[styles.subtitle, { color: textSecondary }]}>
          A blended stream of Glow, Spark, and Vent activity.
        </Text>

        <View style={styles.filterRow}>
          {FILTERS.map(f => (
            <FilterPill
              key={f}
              label={f}
              active={active === f}
              onPress={() => setActive(f)}
              pillActive={pillActive}
              textPrimary={textPrimary}
              textSecondary={textSecondary}
            />
          ))}
        </View>
      </View>

      <FlatList
        data={filtered}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.listContent}
        renderItem={({ item }) => (
          <View
            style={[
              styles.card,
              {
                backgroundColor: cardBg,
                borderColor: 'rgba(255,255,255,0.06)',
              },
            ]}
          >
            <Text
              style={[
                styles.badge,
                { color: textSecondary },
              ]}
            >
              {item.type}
            </Text>
            <Text
              style={[
                styles.text,
                { color: textPrimary },
              ]}
            >
              {item.text || '(no text)'}
            </Text>
          </View>
        )}
        ListEmptyComponent={
          <Text
            style={[
              styles.empty,
              { color: textSecondary },
            ]}
          >
            {loading ? 'Loading…' : 'Nothing here yet.'}
          </Text>
        }
      />
    </View>
  );
}

function FilterPill({
  label,
  active,
  onPress,
  pillActive,
  textPrimary,
  textSecondary,
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.pill,
        {
          backgroundColor: active
            ? 'rgba(255,255,255,0.08)'
            : 'rgba(255,255,255,0.03)',
          borderColor: active ? pillActive : 'rgba(255,255,255,0.1)',
          transform: [{ scale: pressed ? 0.97 : 1 }],
        },
      ]}
    >
      <Text
        style={[
          styles.pillText,
          { color: active ? pillActive : textSecondary || '#7d8ab7' },
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

/* --- styles --- */

const styles = StyleSheet.create({
  screen: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
  },
  subtitle: {
    fontSize: 13,
    marginTop: 4,
  },
  filterRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 12,
    marginBottom: 8,
    flexWrap: 'wrap',
  },
  pill: {
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
  },
  pillText: {
    fontSize: 12,
    fontWeight: '600',
  },
  listContent: {
    padding: 16,
    gap: 10,
    paddingBottom: 32,
  },
  card: {
    borderRadius: 14,
    padding: 12,
    borderWidth: 1,
  },
  badge: {
    fontSize: 11,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
  },
  text: {
    fontSize: 14,
  },
  empty: {
    padding: 16,
    textAlign: 'left',
    fontSize: 13,
  },
});
