// src/components/SparkGlowTag.js
import { StyleSheet, View } from 'react-native';
import { getMoodPalette } from '../theme/truluraTheme';
import TruText from './TruText';

export default function SparkGlowTag({ mode = 'spark' }) {
  const mood = mode === 'glow' ? 'glow' : 'spark';
  const theme = getMoodPalette(mood);
  const label = mood === 'glow' ? 'Glow Mode' : 'Spark Mode';

  return (
    <View
      style={[
        styles.badge,
        {
          backgroundColor: theme.colors.accentSoft,
          borderColor: theme.colors.accentStrong,
        },
      ]}
    >
      <TruText variant="caption" style={{ fontWeight: '600' }}>
        {label}
      </TruText>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    borderWidth: 1,
  },
});
