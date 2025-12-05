// src/components/VibeSelector.js
import { ScrollView, StyleSheet, View } from 'react-native';
import TruText from './TruText';
import VibePill from './VibePill';

const DEFAULT_VIBES = [
  'Soft & Cozy',
  'Playful & Silly',
  'Deep & Healing',
  'Social & Outgoing',
];

export default function VibeSelector({
  label = 'Your current vibe',
  mood = 'default',
  value,
  onChange,
  vibes = DEFAULT_VIBES,
}) {
  return (
    <View style={styles.block}>
      <TruText variant="subtitle" style={{ marginBottom: 6 }}>
        {label}
      </TruText>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ paddingRight: 8 }}
      >
        {vibes.map((v) => (
          <VibePill
            key={v}
            label={v}
            mood={mood}
            active={value === v}
            onPress={() => onChange?.(v)}
          />
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  block: {
    marginTop: 12,
    marginBottom: 4,
  },
});
