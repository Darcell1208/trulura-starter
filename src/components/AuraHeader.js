// src/components/AuraHeader.js
import { StyleSheet, View } from 'react-native';
import { getMoodPalette } from '../theme/truluraTheme';
import TruText from './TruText';

export default function AuraHeader({ title, subtitle, mood = 'default', right }) {
  const theme = getMoodPalette(mood);

  return (
    <View style={styles.row}>
      <View style={styles.textBlock}>
        <TruText variant="caption" color={theme.colors.neutral}>
          TRULURA · {mood.toUpperCase()}
        </TruText>
        <TruText variant="title" style={{ marginTop: 4 }}>
          {title}
        </TruText>
        {subtitle ? (
          <TruText
            variant="body"
            color={theme.colors.neutral}
            style={{ marginTop: 4 }}
          >
            {subtitle}
          </TruText>
        ) : null}
      </View>
      {right ? <View style={styles.right}>{right}</View> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 24,
  },
  textBlock: {
    flex: 1,
    paddingRight: 12,
  },
  right: {
    alignItems: 'flex-end',
  },
});
