// src/components/TruText.js
import { StyleSheet, Text } from 'react-native';
import { truluraTheme } from '../theme/truluraTheme';

export default function TruText({
  variant = 'body',
  color = truluraTheme.colors.softWhite,
  style,
  children,
  ...rest
}) {
  const baseStyle =
    variant === 'title'
      ? styles.title
      : variant === 'subtitle'
      ? styles.subtitle
      : variant === 'caption'
      ? styles.caption
      : styles.body;

  return (
    <Text style={[baseStyle, { color }, style]} {...rest}>
      {children}
    </Text>
  );
}

const styles = StyleSheet.create({
  title: {
    fontSize: truluraTheme.typography.title,
    fontWeight: '700',
  },
  subtitle: {
    fontSize: truluraTheme.typography.subtitle,
    fontWeight: '600',
  },
  body: {
    fontSize: truluraTheme.typography.body,
    fontWeight: '400',
  },
  caption: {
    fontSize: truluraTheme.typography.caption,
    opacity: 0.8,
  },
});
