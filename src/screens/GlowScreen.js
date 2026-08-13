// src/screens/GlowScreen.js
import { useCallback, useEffect, useState } from 'react';
import { RefreshControl, ScrollView, StyleSheet } from 'react-native';

import ComposerCard from '../components/ComposerCard';
import GlowPostCard from '../components/GlowPostCard';
import ScreenContainer from '../components/ScreenContainer';
import TruButton from '../components/TruButton';
import TruCard from '../components/TruCard';
import TruText from '../components/TruText';
import { supabase } from '../lib/supabase';

export default function GlowScreen() {
  const mood = 'glow';

  const [glows, setGlows] = useState([]);
  const [refreshing, setRefreshing] = useState(false);
  const [composerOpen, setComposerOpen] = useState(false);
  const [text, setText] = useState('');
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const fetchGlows = useCallback(async () => {
    setRefreshing(true);
    setErrorMsg('');
    try {
      const { data, error } = await supabase
        .from('glow_posts')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(30);

      if (error) {
        console.error('Glow load error:', error);
        setErrorMsg(error.message || 'Something went wrong loading Glow posts.');
        return;
      }

      setGlows(data ?? []);
    } catch (err) {
      console.error('Unexpected error loading Glow posts:', err);
      setErrorMsg('An unexpected error occurred.');
    } finally {
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchGlows();
  }, [fetchGlows]);

  const handleSubmit = async () => {
    if (!text.trim()) return;

    try {
      setSaving(true);
      setErrorMsg('');

      const { error } = await supabase.from('glow_posts').insert([
        {
          text: text.trim(),
          circle: 'Cozy Calm',
          vibe: 'Soft & Cozy',
        },
      ]);

      if (error) {
        console.error('Glow insert error:', error);
        setErrorMsg(error.message || 'Could not save your Glow post. Try again.');
        return;
      }

      setText('');
      setComposerOpen(false);
      fetchGlows();
    } catch (err) {
      console.error('Unexpected error during submit:', err);
      setErrorMsg('An unexpected error occurred.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScreenContainer mood={mood}>
      <TruCard mood={mood}>
        <TruText variant="subtitle">Glow is not dating</TruText>
        <TruText variant="caption" style={{ marginTop: 6 }}>
          Glow is for friendships, fandoms, anime, gaming, and gentle social energy. No
          romantic intent, with extra safety layers for younger users.
        </TruText>

        <TruButton
          mood={mood}
          label={composerOpen ? 'Close composer' : 'Create Glow post'}
          onPress={() => setComposerOpen((open) => !open)}
          style={{ marginTop: 14 }}
        />
      </TruCard>

      {errorMsg ? (
        <TruText variant="caption" style={styles.error}>
          {errorMsg}
        </TruText>
      ) : null}

      {composerOpen && (
        <ComposerCard
          mood={mood}
          title="What's on your mind?"
          subtitle="Share how you're feeling, what you're into, or what kind of support or vibe you're looking for."
          placeholder="Type your Glow post..."
          value={text}
          onChangeText={setText}
          onSubmit={handleSubmit}
          onCancel={() => {
            setComposerOpen(false);
            setText('');
          }}
          loading={saving}
        />
      )}

      <TruText variant="subtitle" style={{ marginTop: 24 }}>
        Recent Glow posts
      </TruText>

      <ScrollView
        style={{ marginTop: 10 }}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={fetchGlows} />}
      >
        {glows.length === 0 ? (
          <TruText variant="caption">
            No Glow posts yet. Be the first to start a soft space.
          </TruText>
        ) : (
          glows.map((g) => <GlowPostCard key={g.id} post={g} />)
        )}

        <TruText variant="caption" style={{ marginTop: 10, opacity: 0.75 }}>
          Pull to refresh or tap create to share.
        </TruText>
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  error: {
    color: '#ff7a7a',
    marginTop: 10,
  },
});
