// src/components/TruCard.js
import { StyleSheet, View } from 'react-native';
import { getMoodPalette } from '../theme/truluraTheme';

export default function TruCard({ children, mood = 'default', style }) {
  const theme = getMoodPalette(mood);

  return (
    <View
      style={[
        styles.card,
        {
          backgroundColor: theme.colors.card,
          borderRadius: theme.radius.lg,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(148,163,184,0.3)',
  },
});
