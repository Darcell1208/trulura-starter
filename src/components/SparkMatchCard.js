// src/components/SparkMatchCard.js
import { View, StyleSheet } from 'react-native';
import TruCard from './TruCard';
import TruText from './TruText';
import TruButton from './TruButton';

export default function SparkMatchCard({ profile, onPress }) {
  if (!profile) return null;

  const {
    display_name,
    age,
    vibe_status,
    bio,
    compatibility = 92,
  } = profile;

  const vibeLabel = vibe_status || 'Spark vibe';
  const ageAndVibe = age ? `${age} - ${vibeLabel}` : vibeLabel;

  return (
    <TruCard mood="spark" style={styles.card}>
      <View style={styles.headerRow}>
        <View style={{ flex: 1 }}>
          <TruText variant="subtitle">{display_name}</TruText>
          <TruText variant="body" style={{ marginTop: 2 }}>
            {ageAndVibe}
          </TruText>
        </View>

        <View style={styles.chip}>
          <TruText variant="caption" style={{ fontWeight: '700' }}>
            {compatibility}% match
          </TruText>
        </View>
      </View>

      {bio ? (
        <TruText variant="body" style={{ marginTop: 8 }}>
          {bio}
        </TruText>
      ) : null}

      <TruButton
        label="Spark"
        mood="spark"
        style={{ marginTop: 12, minWidth: 110 }}
        onPress={onPress}
      />
    </TruCard>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: 12,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  chip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: 'rgba(251,113,133,0.55)',
    backgroundColor: 'rgba(251,113,133,0.18)',
  },
});
