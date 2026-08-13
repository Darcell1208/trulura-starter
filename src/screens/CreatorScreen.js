// src/screens/CreatorScreen.js

import { useCallback, useEffect, useState } from 'react';
import {
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { supabase } from '../lib/supabase';
import { useTheme } from '../theme/ThemeProvider';

export default function CreatorScreen() {
  const { palettes } = useTheme();

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState(null);

  const [counts, setCounts] = useState({
    glows: 0,
    sparks: 0,
    vents: 0,
    moods: 0,
  });

  const [recent, setRecent] = useState({
    glows: [],
    sparks: [],
    vents: [],
  });

  const load = useCallback(async () => {
    setError(null);
    setLoading(true);
    try {
      // --- counts (using exact count + head) ---
      const [glowsCountRes, sparksCountRes, ventsCountRes, moodsCountRes] =
        await Promise.all([
          supabase
            .from('glow_sessions')
            .select('*', { count: 'exact', head: true }),
          supabase
            .from('sparks')
            .select('*', { count: 'exact', head: true }),
          supabase
            .from('vents')
            .select('*', { count: 'exact', head: true }),
          supabase
            .from('moods')
            .select('*', { count: 'exact', head: true }),
        ]);

      if (glowsCountRes.error) throw glowsCountRes.error;
      if (sparksCountRes.error) throw sparksCountRes.error;
      if (ventsCountRes.error) throw ventsCountRes.error;
      if (moodsCountRes.error) throw moodsCountRes.error;

      // --- recent lists ---
      const [glowsRecentRes, sparksRecentRes, ventsRecentRes] =
        await Promise.all([
          supabase
            .from('glow_sessions')
            .select('*')
            .order('started_at', { ascending: false })
            .limit(3),
          supabase
            .from('sparks')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(3),
          supabase
            .from('vents')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(3),
        ]);

      if (glowsRecentRes.error) throw glowsRecentRes.error;
      if (sparksRecentRes.error) throw sparksRecentRes.error;
      if (ventsRecentRes.error) throw ventsRecentRes.error;

      setCounts({
        glows: glowsCountRes.count ?? 0,
        sparks: sparksCountRes.count ?? 0,
        vents: ventsCountRes.count ?? 0,
        moods: moodsCountRes.count ?? 0,
      });

      setRecent({
        glows: glowsRecentRes.data ?? [],
        sparks: sparksRecentRes.data ?? [],
        vents: ventsRecentRes.data ?? [],
      });
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  }, [load]);

  const bg = palettes.ink || '#0b0f17';
  const cardBg = palettes.card || '#0f1421';
  const textPrimary = palettes.white || '#e7ecff';
  const textSecondary = palettes.dim || '#a8b2d1';
  const accentSpark = palettes.spark || '#FF5A9E';
  const accentGlow = palettes.glow || '#F5C84C';
  const accentVent = palettes.vent || '#6A7CFF';

  return (
    <ScrollView
      style={[styles.screen, { backgroundColor: bg }]}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      <Text
        style={[
          styles.title,
          { color: textPrimary },
        ]}
      >
        Your creative universe
      </Text>

      <Text
        style={[
          styles.subtitle,
          { color: textSecondary },
        ]}
      >
        Quick snapshot of how you’ve been using Glow, Spark, and Vent.
      </Text>

      <View style={styles.statsRow}>
        <StatCard
          label="Glow sessions"
          value={counts.glows}
          color={accentGlow}
          bg={cardBg}
          textPrimary={textPrimary}
          textSecondary={textSecondary}
        />
        <StatCard
          label="Sparks"
          value={counts.sparks}
          color={accentSpark}
          bg={cardBg}
          textPrimary={textPrimary}
          textSecondary={textSecondary}
        />
      </View>

      <View style={styles.statsRow}>
        <StatCard
          label="Vents"
          value={counts.vents}
          color={accentVent}
          bg={cardBg}
          textPrimary={textPrimary}
          textSecondary={textSecondary}
        />
        <StatCard
          label="Mood logs"
          value={counts.moods}
          color={textSecondary}
          bg={cardBg}
          textPrimary={textPrimary}
          textSecondary={textSecondary}
        />
      </View>

      <Text
        style={[
          styles.sectionHeader,
          { color: textSecondary },
        ]}
      >
        Recent activity
      </Text>

      <View style={styles.sectionStack}>
        <Section
          title="Recent Glows"
          items={recent.glows}
          kind="glow"
          bg={cardBg}
          textPrimary={textPrimary}
          textSecondary={textSecondary}
        />
        <Section
          title="Recent Sparks"
          items={recent.sparks}
          kind="spark"
          bg={cardBg}
          textPrimary={textPrimary}
          textSecondary={textSecondary}
        />
        <Section
          title="Recent Vents"
          items={recent.vents}
          kind="vent"
          bg={cardBg}
          textPrimary={textPrimary}
          textSecondary={textSecondary}
        />
      </View>

      {loading ? (
        <Text style={[styles.loading, { color: textSecondary }]}>Loading…</Text>
      ) : null}

      {!!error && (
        <Text style={[styles.error, { color: '#ff8a8a' }]}>
          Error: {error}
        </Text>
      )}
    </ScrollView>
  );
}

/* --- small components ------------------------------------------------------ */

function StatCard({ label, value, color, bg, textPrimary, textSecondary }) {
  return (
    <View
      style={[
        styles.statCard,
        { backgroundColor: bg, borderColor: 'rgba(255,255,255,0.06)' },
      ]}
    >
      <Text style={[styles.statLabel, { color: textSecondary }]}>{label}</Text>
      <Text style={[styles.statValue, { color }]}>{value}</Text>
    </View>
  );
}

function Section({ title, items, kind, bg, textPrimary, textSecondary }) {
  return (
    <View
      style={[
        styles.sectionCard,
        { backgroundColor: bg, borderColor: 'rgba(255,255,255,0.06)' },
      ]}
    >
      <Text style={[styles.sectionTitle, { color: textPrimary }]}>{title}</Text>
      {items.length === 0 ? (
        <Text style={{ color: textSecondary }}>Nothing yet.</Text>
      ) : (
        items.map(row => {
          const ts = row.created_at || row.started_at;
          const when = ts ? new Date(ts).toLocaleString() : '';
          const primary =
            kind === 'glow'
              ? row.mood || 'Glow session'
              : row.text || row.mood || 'Entry';

          return (
            <View
              key={row.id}
              style={styles.row}
            >
              <Text
                style={[
                  styles.rowText,
                  { color: textPrimary },
                ]}
                numberOfLines={2}
              >
                {primary}
              </Text>
              <Text
                style={[
                  styles.rowMeta,
                  { color: textSecondary },
                ]}
                numberOfLines={1}
              >
                {when}
              </Text>
            </View>
          );
        })
      )}
    </View>
  );
}

/* --- styles ---------------------------------------------------------------- */

const styles = StyleSheet.create({
  screen: {
    flex: 1,
  },
  content: {
    padding: 16,
    paddingBottom: 40,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 6,
  },
  subtitle: {
    fontSize: 13,
    marginBottom: 16,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 12,
  },
  statCard: {
    flex: 1,
    borderRadius: 14,
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderWidth: 1,
  },
  statLabel: {
    fontSize: 12,
    marginBottom: 4,
  },
  statValue: {
    fontSize: 20,
    fontWeight: '700',
  },
  sectionHeader: {
    fontSize: 14,
    fontWeight: '600',
    marginTop: 12,
    marginBottom: 8,
  },
  sectionStack: {
    gap: 10,
  },
  sectionCard: {
    borderRadius: 14,
    padding: 12,
    borderWidth: 1,
  },
  sectionTitle: {
    fontWeight: '700',
    marginBottom: 8,
  },
  row: {
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)',
  },
  rowText: {
    fontSize: 14,
    marginBottom: 2,
  },
  rowMeta: {
    fontSize: 11,
  },
  loading: {
    marginTop: 16,
    fontSize: 13,
  },
  error: {
    marginTop: 12,
    fontSize: 13,
  },
});
