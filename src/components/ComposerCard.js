// src/components/ComposerCard.js
import { LinearGradient } from 'expo-linear-gradient';
import { StyleSheet, TextInput, View } from 'react-native';
import TruButton from './TruButton';
import TruText from './TruText';

export default function ComposerCard({
  mood = 'glow',
  title = "What's on your mind?",
  subtitle = 'Share how you are feeling...',
  placeholder = 'Type your post...',
  value,
  onChangeText,
  onSubmit,
  onCancel,
  loading = false,
  colorScheme = 'dark',
  style,
}) {
  return (
    <LinearGradient
      colors={
        colorScheme === 'dark'
          ? ['rgba(255, 198, 102, 0.1)', 'rgba(255, 198, 102, 0.05)']
          : ['rgba(255, 198, 102, 0.15)', 'rgba(255, 198, 102, 0.08)']
      }
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={[styles.glassmorphicContainer, style]}
    >
      {/* Frosted glass effect background */}
      <View
        style={[
          styles.glassBackground,
          {
            backgroundColor:
              colorScheme === 'dark'
                ? 'rgba(11, 16, 32, 0.7)'
                : 'rgba(255, 255, 255, 0.8)',
          },
        ]}
      />

      {/* Content */}
      <View style={styles.content}>
        <TruText variant="subtitle" style={styles.title}>
          {title}
        </TruText>
        <TruText variant="caption" style={styles.subtitle}>
          {subtitle}
        </TruText>

        <TextInput
          style={[
            styles.input,
            {
              borderColor:
                colorScheme === 'dark'
                  ? 'rgba(255, 198, 102, 0.25)'
                  : 'rgba(255, 198, 102, 0.3)',
              backgroundColor:
                colorScheme === 'dark'
                  ? 'rgba(255, 255, 255, 0.05)'
                  : 'rgba(255, 255, 255, 0.15)',
              color: colorScheme === 'dark' ? '#ffffff' : '#000000',
            },
          ]}
          multiline
          placeholder={placeholder}
          placeholderTextColor={
            colorScheme === 'dark' ? 'rgba(255, 255, 255, 0.35)' : 'rgba(0, 0, 0, 0.35)'
          }
          value={value}
          onChangeText={onChangeText}
        />

        <View style={styles.buttonRow}>
          <TruButton
            label="Cancel"
            mood={mood}
            variant="secondary"
            style={{ flex: 1, marginRight: 8 }}
            onPress={onCancel}
          />
          <TruButton
            label="Post"
            mood={mood}
            style={{ flex: 1, marginLeft: 8 }}
            loading={loading}
            onPress={onSubmit}
          />
        </View>
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  glassmorphicContainer: {
    marginTop: 18,
    marginHorizontal: 0,
    borderRadius: 16,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 198, 102, 0.2)',
  },
  glassBackground: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backdropFilter: 'blur(10px)',
  },
  content: {
    padding: 20,
    zIndex: 1,
  },
  title: {
    marginBottom: 4,
  },
  subtitle: {
    marginBottom: 14,
    opacity: 0.8,
  },
  input: {
    borderRadius: 12,
    borderWidth: 1.5,
    paddingHorizontal: 14,
    paddingVertical: 12,
    minHeight: 100,
    textAlignVertical: 'top',
    fontSize: 14,
    marginBottom: 16,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 10,
  },
});
