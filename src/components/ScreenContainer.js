// src/components/ScreenContainer.js
import { StatusBar, StyleSheet, View } from 'react-native';
import { getMoodPalette } from '../theme/truluraTheme';

export default function ScreenContainer({ children, mood = 'default', style }) {
  const theme = getMoodPalette(mood);

  return (
    <View style={[styles.root, { backgroundColor: theme.colors.background }, style]}>
      <StatusBar barStyle="light-content" />
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    paddingHorizontal: 18,
    paddingTop: 48,
  },
});
