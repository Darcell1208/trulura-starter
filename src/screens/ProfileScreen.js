// src/screens/ProfileScreen.js
import { useNavigation } from '@react-navigation/native';
import {
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  View,
} from 'react-native';

import { useAuth } from '../context/AuthContext';

import AuraHeader from '../components/AuraHeader';
import ScreenContainer from '../components/ScreenContainer';
import TruButton from '../components/TruButton';
import TruCard from '../components/TruCard';
import TruText from '../components/TruText';

// Same vibe → mood mapping we use everywhere else
const mapVibeToMood = (vibe) => {
  switch (vibe) {
    case 'Playful & Silly':
      return 'glow';
    case 'Deep & Healing':
      return 'vent';
    case 'Social & Outgoing':
      return 'spark';
    case 'Soft & Cozy':
    default:
      return 'default';
  }
};

export default function ProfileScreen() {
  const navigation = useNavigation();
  const { profile, session, signOut } = useAuth();

  const vibe = profile?.vibe_status || 'Soft & Cozy';
  const mood = mapVibeToMood(vibe);

  const displayName = profile?.display_name || null;
  const username = profile?.username || null;
  const email = session?.user?.email || 'Unknown';

  const handleEditProfile = () => {
    // Uses the stack route we already registered earlier
    navigation.navigate('ProfileSetup');
  };

  const handleSignOut = async () => {
    try {
      // optional chaining so it won't crash if signOut isn't defined
      await signOut?.();
    } catch (err) {
      console.warn('Sign out error:', err);
    }
  };

  const renderEditableValue = (value, fallback = 'Not set') => {
    if (!value) {
      return (
        <TouchableOpacity onPress={handleEditProfile}>
          <TruText
            variant="caption"
            style={styles.linkText}
          >
            {fallback}
          </TruText>
        </TouchableOpacity>
      );
    }

    return (
      <TruText variant="caption" style={styles.valueText}>
        {value}
      </TruText>
    );
  };

  return (
    <ScreenContainer mood={mood}>
      <AuraHeader
        title="Your Profile"
        subtitle="This is how you currently show up across Trulura."
        mood={mood}
      />

      <ScrollView showsVerticalScrollIndicator={false}>
        {/* BASICS CARD */}
        <TruCard mood={mood}>
          <TruText variant="subtitle" style={styles.sectionTitle}>
            Basics
          </TruText>

          <View style={styles.row}>
            <TruText variant="caption" style={styles.labelText}>
              Display name
            </TruText>
            {renderEditableValue(displayName)}
          </View>

          <View style={styles.row}>
            <TruText variant="caption" style={styles.labelText}>
              Username
            </TruText>
            {renderEditableValue(username)}
          </View>

          <View style={styles.row}>
            <TruText variant="caption" style={styles.labelText}>
              Email
            </TruText>
            <TruText variant="caption" style={styles.valueText}>
              {email}
            </TruText>
          </View>

          <View style={styles.row}>
            <TruText variant="caption" style={styles.labelText}>
              Current vibe
            </TruText>
            {renderEditableValue(vibe, 'Not set yet')}
          </View>
        </TruCard>

        {/* ABOUT CARD */}
        <TruCard mood={mood}>
          <TruText variant="subtitle" style={styles.sectionTitle}>
            About you
          </TruText>
          <TruText
            variant="caption"
            style={{ marginTop: 6 }}
          >
            {profile?.about_me && profile.about_me.trim().length > 0
              ? profile.about_me
              : "You haven’t written an about me yet. This is where your story, energy, and personality will live."}
          </TruText>

          <TruButton
            label="Edit profile"
            mood={mood}
            variant="secondary"
            style={{ marginTop: 14 }}
            onPress={handleEditProfile}
          />
        </TruCard>

        {/* SIGN OUT */}
        <View style={{ marginTop: 20 }}>
          <TruButton
            label="Sign out"
            mood={mood}
            onPress={handleSignOut}
          />
        </View>

        <View style={{ height: 32 }} />
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  sectionTitle: {
    marginBottom: 10,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 4,
  },
  labelText: {
    opacity: 0.85,
  },
  valueText: {
    textAlign: 'right',
  },
  linkText: {
    textAlign: 'right',
    textDecorationLine: 'underline',
  },
});
