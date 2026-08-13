// src/components/Page.js
import { SafeAreaView, StyleSheet } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';

/**
 * Generic page wrapper giving consistent background + padding.
 *
 * Usage:
 *   <Page>
 *     ...screen content...
 *   </Page>
 */
export default function Page({ children, style }) {
  const { palettes } = useTheme();

  return (
    <SafeAreaView
      style={[
        styles.page,
        { backgroundColor: palettes.ink || '#020316' },
        style,
      ]}
    >
      {children}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
  },
});
