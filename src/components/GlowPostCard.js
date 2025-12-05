// src/components/GlowPostCard.js
import { StyleSheet } from 'react-native';
import TruCard from './TruCard';
import TruText from './TruText';

export default function GlowPostCard({ post, style }) {
  const formatDate = (dateString) => {
    if (!dateString) return 'Just now';
    try {
      return new Date(dateString).toLocaleString();
    } catch {
      return 'Just now';
    }
  };

  return (
    <TruCard mood="glow" style={[styles.container, style]}>
      <TruText variant="caption" style={styles.circle}>
        {post.circle || 'Cozy Calm'}
      </TruText>
      <TruText variant="body" style={styles.text}>
        {post.text}
      </TruText>
      {post.vibe && (
        <TruText variant="caption" style={styles.vibe}>
          {post.vibe}
        </TruText>
      )}
      <TruText variant="caption" style={styles.timestamp}>
        {formatDate(post.created_at)}
      </TruText>
    </TruCard>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 14,
  },
  circle: {
    opacity: 0.8,
  },
  text: {
    marginTop: 6,
  },
  vibe: {
    marginTop: 6,
    opacity: 0.7,
    fontStyle: 'italic',
  },
  timestamp: {
    marginTop: 8,
    opacity: 0.6,
  },
});
