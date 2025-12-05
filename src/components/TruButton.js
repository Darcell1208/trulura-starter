// src/components/TruButton.js
import { ActivityIndicator, StyleSheet, TouchableOpacity } from 'react-native';
import { getMoodPalette } from '../theme/truluraTheme';
import TruText from './TruText';

export default function TruButton({
  label,
  mood = 'default',
  variant = 'primary',
  loading = false,
  disabled = false,
  style,
  onPress,
}) {
  const theme = getMoodPalette(mood);

  const bgColor =
    variant === 'ghost'
      ? 'transparent'
      : variant === 'secondary'
      ? theme.colors.accentSoft
      : theme.colors.accentStrong;

  return (
    <TouchableOpacity
      activeOpacity={0.85}
      onPress={onPress}
      disabled={disabled || loading}
      style={[
        styles.button,
        { backgroundColor: bgColor, opacity: disabled ? 0.5 : 1 },
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={theme.colors.softWhite} />
      ) : (
        <TruText
          variant="body"
          style={{ fontWeight: '600', textAlign: 'center' }}
        >
          {label}
        </TruText>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    borderRadius: 999,
    paddingVertical: 12,
    paddingHorizontal: 18,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 6,
  },
});
