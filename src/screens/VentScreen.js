// src/screens/VentScreen.js
import { useCallback, useEffect, useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
} from 'react-native';

import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';

import ScreenContainer from '../components/ScreenContainer';
import AuraHeader from '../components/AuraHeader';
import TruCard from '../components/TruCard';
import TruButton from '../components/TruButton';
import TruText from '../components/TruText';

export default function VentScreen() {
  const mood = 'vent';
  const { session } = useAuth();

  const [vents, setVents] = useState([]);
  const [composerOpen, setComposerOpen] = useState(false);
  const [newText, setNewText] = useState('');
  const [saving, setSaving] = useState(false);

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const mapRowToVent = row => ({
    id: row.id,
    tag: row.tag ?? 'Just needed to vent',
    text: row.text,
    createdAt: row.created_at
      ? new Date(row.created_at).toLocaleString()
      : 'Just now',
  });

  const fetchVents = useCallback(async (opts = { showSpinner: true }) => {
    try {
      if (opts.showSpinner) {
        setLoading(true);
      } else {
        setRefreshing(true);
      }
      setErrorMsg('');

      const { data, error } = await supabase
        .from('vent_posts')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(30);

      if (error) {
        console.error('Error loading vents:', error);
        setErrorMsg('Something went wrong loading your vents.');
        return;
      }

      setVents((data || []).map(mapRowToVent));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchVents();
  }, [fetchVents]);

  const handleOpenComposer = () => {
    setComposerOpen(true);
  };

  const handleCancel = () => {
    setComposerOpen(false);
    setNewText('');
  };

  const handleSave = async () => {
    if (!newText.trim()) return;
    if (!session?.user) {
      setErrorMsg('You must be signed in to save vents.');
      return;
    }

    setSaving(true);
    setErrorMsg('');

    try {
      const { data, error } = await supabase
        .from('vent_posts')
        .insert({
          user_id: session.user.id,
          tag: 'Just needed to vent', // later we can make this selectable
          text: newText.trim(),
        })
        .select()
        .single();

      if (error) {
        console.error('Error saving vent:', error);
        setErrorMsg('Could not save your vent. Try again.');
        return;
      }

      const mapped = mapRowToVent(data);

      setVents(prev => [mapped, ...prev]);
      setNewText('');
      setComposerOpen(false);
    } finally {
      setSaving(false);
    }
  };

  const onRefresh = () => {
    fetchVents({ showSpinner: false });
  };

  return (
    <ScreenContainer mood={mood}>
      <AuraHeader
        title="Vent Space"
        subtitle="Anonymous-feeling emotional space, grounded in safety and support."
        mood={mood}
      />

      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.select({ ios: 'padding', android: undefined })}
      >
        <ScrollView
          contentContainerStyle={styles.content}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor="#fff"
            />
          }
        >
          {/* Intro / safety card */}
          <TruCard mood={mood}>
            <TruText variant="subtitle" style={styles.sectionTitle}>
              This is your unfiltered space
            </TruText>
            <TruText variant="caption" style={{ marginBottom: 12, opacity: 0.9 }}>
              Share what’s sitting on your chest without worrying about aesthetics or
              likes. Vent Space is built for honesty, not performance.
            </TruText>

            <TruButton
              label={composerOpen ? 'Close vent composer' : 'Start a vent'}
              mood={mood}
              onPress={composerOpen ? handleCancel : handleOpenComposer}
            />
          </TruCard>

          {/* Error message */}
          {errorMsg ? (
            <TruText
              variant="caption"
              style={{ marginTop: 10, color: 'rgba(255,150,150,0.9)' }}
            >
              {errorMsg}
            </TruText>
          ) : null}

          {/* Composer */}
          {composerOpen && (
            <TruCard mood={mood} style={{ marginTop: 16 }}>
              <TruText variant="subtitle" style={styles.sectionTitle}>
                What do you need to let out?
              </TruText>
              <TruText variant="caption" style={{ marginBottom: 8 }}>
                You don’t have to make it pretty. Just be honest with yourself. This
                is for you.
              </TruText>

              <TextInput
                style={styles.input}
                placeholder="Type your vent here..."
                placeholderTextColor="rgba(255,255,255,0.45)"
                multiline
                value={newText}
                onChangeText={setNewText}
              />

              <View style={styles.composerButtons}>
                <TruButton
                  label="Cancel"
                  variant="secondary"
                  mood={mood}
                  style={{ flex: 1, marginRight: 8 }}
                  onPress={handleCancel}
                />
                <TruButton
                  label="Save vent"
                  mood={mood}
                  style={{ flex: 1, marginLeft: 8 }}
                  loading={saving}
                  onPress={handleSave}
                />
              </View>
            </TruCard>
          )}

          {/* Vents list */}
          <View style={{ marginTop: 20 }}>
            <TruText variant="subtitle" style={styles.sectionTitle}>
              Your recent vents
            </TruText>

            {loading && vents.length === 0 ? (
              <TruText variant="caption" style={{ marginTop: 8, opacity: 0.8 }}>
                Loading your Vent Space…
              </TruText>
            ) : vents.length === 0 ? (
              <TruText variant="caption" style={{ marginTop: 8, opacity: 0.8 }}>
                You haven’t vented yet. When you’re ready, this will be your private
                emotional trail.
              </TruText>
            ) : (
              vents.map(vent => (
                <TruCard key={vent.id} mood={mood} style={styles.ventCard}>
                  <View style={styles.ventHeader}>
                    <TruText variant="caption" style={styles.tagText}>
                      {vent.tag}
                    </TruText>
                    <TruText variant="caption" style={styles.timeText}>
                      {vent.createdAt}
                    </TruText>
                  </View>

                  <TruText variant="caption" style={styles.ventText}>
                    {vent.text}
                  </TruText>
                </TruCard>
              ))
            )}
            <View style={{ height: 32 }} />
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  content: {
    paddingHorizontal: 16,
    paddingBottom: 24,
  },
  sectionTitle: {
    marginBottom: 8,
  },
  input: {
    marginTop: 8,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.18)',
    paddingHorizontal: 12,
    paddingVertical: 10,
    minHeight: 100,
    textAlignVertical: 'top',
    color: '#FFFFFF',
    fontSize: 14,
  },
  composerButtons: {
    flexDirection: 'row',
    marginTop: 12,
  },
  ventCard: {
    marginBottom: 14,
  },
  ventHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  tagText: {
    opacity: 0.85,
  },
  timeText: {
    opacity: 0.6,
  },
  ventText: {
    marginTop: 4,
  },
});
