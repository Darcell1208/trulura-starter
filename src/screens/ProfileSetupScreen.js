// src/screens/ProfileSetupScreen.js
import React, { useState } from 'react';
import { View, TextInput, StyleSheet, Alert } from 'react-native';

import { supabase } from '../lib/supabaseClient';
import { useAuth } from '../context/AuthContext';

import ScreenContainer from '../components/ScreenContainer';
import AuraHeader from '../components/AuraHeader';
import TruCard from '../components/TruCard';
import TruText from '../components/TruText';
import TruButton from '../components/TruButton';
import VibeSelector from '../components/VibeSelector';

const VIBES = [
  'Soft & Cozy',
  'Playful & Silly',
  'Deep & Healing',
  'Social & Outgoing',
];

// map vibe → mood for theming
const mapVibeToMood = (vibe) => {
  switch (vibe) {
    case 'Playful & Silly':
      return 'glow';   // playful / teen / friend
    case 'Deep & Healing':
      return 'vent';   // emotional support
    case 'Social & Outgoing':
      return 'spark';  // social / dating
    case 'Soft & Cozy':
    default:
      return 'default';
  }
};

export default function ProfileSetupScreen() {
  const { session, profile, setProfile } = useAuth();

  const [displayName, setDisplayName] = useState(profile?.display_name || '');
  const [username, setUsername] = useState(profile?.username || '');
  const [vibe, setVibe] = useState(profile?.vibe_status || VIBES[0]);
  const [about, setAbout] = useState(profile?.about_me || '');
  const [saving, setSaving] = useState(false);

  const mood = mapVibeToMood(vibe);

  const handleSave = async () => {
    if (!session) {
      Alert.alert('Not signed in', 'Please log in again.');
      return;
    }

    if (!displayName.trim() || !username.trim()) {
      Alert.alert('Missing info', 'Display name and username are required.');
      return;
    }

    setSaving(true);

    try {
      const cleanUsername = username.trim().toLowerCase();

      // unique username check
      const { data: existing, error: usernameError } = await supabase
        .from('profiles')
        .select('id')
        .eq('username', cleanUsername)
        .neq('id', profile?.id || '')
        .maybeSingle();

      if (usernameError && usernameError.code !== 'PGRST116') {
        throw usernameError;
      }

      if (existing) {
        Alert.alert('Username taken', 'Please choose a different username.');
        setSaving(false);
        return;
      }

      const updates = {
        id: session.user.id,
        display_name: displayName.trim(),
        username: cleanUsername,
        vibe_status: vibe,
        about_me: about.trim(),
        updated_at: new Date().toISOString(),
      };

      const { data, error } = await supabase
        .from('profiles')
        .upsert(updates)
        .select()
        .single();

      if (error) throw error;

      // ⬇️ This triggers RootNavigator to switch to MainTabs
      setProfile(data);

      Alert.alert('Saved', 'Your profile has been updated.');
    } catch (err) {
      console.error(err);
      Alert.alert('Error', err.message || 'Something went wrong saving your profile.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScreenContainer mood={mood}>
      <AuraHeader
        title="Set up your Trulura profile"
        subtitle="This is how people will see you across Spark, Glow, and Vent."
        mood={mood}
      />

      <TruCard mood={mood}>
        <TruText variant="subtitle" style={{ marginBottom: 12 }}>
          Basics
        </TruText>

        {/* Display name */}
        <View style={styles.fieldGroup}>
          <TruText variant="body">Display name</TruText>
          <TextInput
            style={styles.input}
            placeholder="How do you want your name to appear?"
            placeholderTextColor="rgba(148,163,184,0.9)"
            value={displayName}
            onChangeText={setDisplayName}
          />
        </View>

        {/* Username */}
        <View style={styles.fieldGroup}>
          <TruText variant="body">Username</TruText>
          <TextInput
            style={styles.input}
            placeholder="username"
            placeholderTextColor="rgba(148,163,184,0.9)"
            autoCapitalize="none"
            value={username}
            onChangeText={setUsername}
          />
          <TruText variant="caption" style={{ marginTop: 4 }}>
            Usernames must be unique. Letters, numbers, and underscores only.
          </TruText>
        </View>

        {/* Vibe selector */}
        <VibeSelector
          label="Your current vibe"
          mood={mood}
          value={vibe}
          vibes={VIBES}
          onChange={setVibe}
        />

        {/* About me */}
        <View style={styles.fieldGroup}>
          <TruText variant="body">About you</TruText>
          <TextInput
            style={[styles.input, styles.multiline]}
            placeholder="Share a little about your energy, what you love, and what you’re open to."
            placeholderTextColor="rgba(148,163,184,0.9)"
            multiline
            value={about}
            onChangeText={setAbout}
          />
        </View>

        <TruButton
          label="Save profile"
          mood={mood}
          loading={saving}
          onPress={handleSave}
          style={{ marginTop: 16 }}
        />
      </TruCard>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  fieldGroup: {
    marginBottom: 14,
  },
  input: {
    marginTop: 6,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(148,163,184,0.45)',
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: '#F9FAFB',
    fontSize: 14,
  },
  multiline: {
    minHeight: 90,
    textAlignVertical: 'top',
  },
});
