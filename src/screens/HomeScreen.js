// src/screens/HomeScreen.js
import { ScrollView, StyleSheet, View } from 'react-native';

import AuraHeader from '../components/AuraHeader';
import ScreenContainer from '../components/ScreenContainer';
import TruButton from '../components/TruButton';
import TruCard from '../components/TruCard';
import TruText from '../components/TruText';

const MOCK_POSTS = [
  {
    id: 'spark-1',
    mood: 'spark',
    author: 'Kayla',
    title: 'Soft & Cozy but ready to flirt',
    body: 'Shared a Spark: slow Saturday morning, coffee in bed, open to new connections today.',
  },
  {
    id: 'glow-1',
    mood: 'glow',
    author: 'Milo',
    title: 'Glow check-in',
    body: 'Wrapped a Glow session: practiced breathing and feel lighter. Reminder: hydrate and stretch.',
  },
  {
    id: 'vent-1',
    mood: 'vent',
    author: 'Renee',
    title: 'Letting it out',
    body: 'Needed to vent about school stress. Feeling heard and calmer now.',
  },
  {
    id: 'spark-2',
    mood: 'spark',
    author: 'Sam',
    title: 'Looking for a playful chat',
    body: 'Playful & Silly mood today. Drop your best meme or game rec.',
  },
];

export default function HomeScreen() {
  return (
    <ScreenContainer mood="default">
      <AuraHeader
        title="AuraFeed"
        subtitle="Your mix of Spark, Glow, and Vent energy in one scrolling feed."
        mood="default"
      />

      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.row}>
          <TruCard mood="spark" style={styles.rowCard}>
            <TruText variant="caption">Spark</TruText>
            <TruText variant="subtitle" style={{ marginTop: 4 }}>
              Quick flirty vibes
            </TruText>
            <TruText variant="body" style={{ marginTop: 8 }}>
              Capture a Spark or browse playful, social energy.
            </TruText>
            <TruButton
              label="Open Spark"
              mood="spark"
              style={{ marginTop: 10 }}
              onPress={() => {}}
            />
          </TruCard>

          <TruCard mood="glow" style={styles.rowCard}>
            <TruText variant="caption">Glow</TruText>
            <TruText variant="subtitle" style={{ marginTop: 4 }}>
              Soft & supportive
            </TruText>
            <TruText variant="body" style={{ marginTop: 8 }}>
              Start a Glow session to reset your mood and reflect.
            </TruText>
            <TruButton
              label="Open Glow"
              mood="glow"
              style={{ marginTop: 10 }}
              onPress={() => {}}
            />
          </TruCard>
        </View>

        <TruCard mood="vent">
          <TruText variant="caption">Vent</TruText>
          <TruText variant="subtitle" style={{ marginTop: 4 }}>
            Let it out, feel lighter
          </TruText>
          <TruText variant="body" style={{ marginTop: 8 }}>
            Share what is on your mind. We keep this space calm and supportive.
          </TruText>
          <TruButton
            label="Open Vent"
            mood="vent"
            style={{ marginTop: 10 }}
            onPress={() => {}}
          />
        </TruCard>

        {MOCK_POSTS.map(post => (
          <TruCard key={post.id} mood={post.mood} style={{ marginTop: 12 }}>
            <TruText variant="caption">
              {post.mood.toUpperCase()} • {post.author}
            </TruText>
            <TruText variant="subtitle" style={{ marginTop: 4 }}>
              {post.title}
            </TruText>
            <TruText variant="body" style={{ marginTop: 8 }}>
              {post.body}
            </TruText>
          </TruCard>
        ))}
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  content: {
    paddingBottom: 32,
  },
  row: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 12,
  },
  rowCard: {
    flex: 1,
  },
});
