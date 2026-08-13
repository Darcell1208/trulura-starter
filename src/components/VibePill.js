// src/components/VibePill.js
import { StyleSheet, TouchableOpacity } from 'react-native';
import { getMoodPalette } from '../theme/truluraTheme';
import TruText from './TruText';

export default function VibePill({
  label,
  active = false,
  mood = 'default',
  onPress,
}) {
  const theme = getMoodPalette(mood);

  return (
    <TouchableOpacity
      style={[
        styles.pill,
        {
          backgroundColor: active ? theme.colors.accentSoft : 'transparent',
          borderColor: active ? theme.colors.accentStrong : theme.colors.neutral,
        },
      ]}
      onPress={onPress}
      activeOpacity={0.85}
    >
      <TruText
        variant="caption"
        style={{ fontWeight: active ? '700' : '500' }}
        color={active ? theme.colors.softWhite : theme.colors.neutral}
      >
        {label}
      </TruText>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  pill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
    borderWidth: 1,
    marginRight: 8,
    marginBottom: 6,
  },
});
