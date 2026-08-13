// src/screens/SparkScreen.js
import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import AuraHeader from '../components/AuraHeader';
import ScreenContainer from '../components/ScreenContainer';
import TruButton from '../components/TruButton';
import TruCard from '../components/TruCard';
import TruText from '../components/TruText';

const INITIAL_MATCHES = [
  {
    id: '1',
    name: 'Kayla',
    age: 29,
    vibe: 'Playful & Silly',
    location: 'Interior designer • City nights',
    matchPercent: 92,
    bio: 'Loves cozy coffee dates, vinyl, and spontaneous trips. Looking for someone who actually texts back.',
  },
  {
    id: '2',
    name: 'Riley',
    age: 31,
    vibe: 'Soft & Cozy',
    location: 'Weekend hiker • Morning yoga',
    matchPercent: 89,
    bio: 'Soft-hearted, sarcastic, and big on peaceful homes. If you like breakfast foods and deep talks, we might click.',
  },
  {
    id: '3',
    name: 'Noah',
    age: 27,
    vibe: 'Deep & Healing',
    location: 'Therapy girly era • Journals',
    matchPercent: 86,
    bio: 'Learning to communicate better and unlearn old habits. Wants a gentle, grown connection, not games.',
  },
];

export default function SparkScreen() {
  const mood = 'spark';
  const [matches] = useState(INITIAL_MATCHES);

  const handleSpark = (match) => {
    // For now, just log or later trigger a Spark action / modal
    console.log('Spark tapped for:', match.name);
  };

  return (
    <ScreenContainer mood={mood}>
      <AuraHeader
        title="Spark Mode"
        subtitle="Romantic + social discovery for adults who want real chemistry, not just swipes."
        mood={mood}
      />

      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Your Spark space overview card */}
        <TruCard mood={mood}>
          <TruText variant="subtitle" style={styles.sectionTitle}>
            Your Spark space
          </TruText>
          <TruText variant="caption" style={{ marginBottom: 12, opacity: 0.9 }}>
            Discover people whose vibe matches your Spark energy. This is a mock list
            while we build the real match flow.
          </TruText>

          <TruButton
            label="Refine matches (coming soon)"
            mood={mood}
            variant="secondary"
          />
        </TruCard>

        {/* Match cards */}
        <View style={{ marginTop: 20 }}>
          {matches.map((match) => (
            <TruCard key={match.id} mood={mood} style={styles.matchCard}>
              <View style={styles.headerRow}>
                <TruText variant="subtitle">
                  {match.name}, {match.age}
                </TruText>
                <TruText variant="caption" style={styles.matchPercent}>
                  {match.matchPercent}% match
                </TruText>
              </View>

              <TruText variant="caption" style={styles.locationText}>
                {match.location}
              </TruText>

              <TruText variant="caption" style={styles.bioText}>
                {match.bio}
              </TruText>

              <View style={styles.footerRow}>
                <TruText variant="caption" style={styles.vibePill}>
                  {match.vibe}
                </TruText>

                <TruButton
                  label="Spark"
                  mood={mood}
                  style={styles.sparkButton}
                  onPress={() => handleSpark(match)}
                />
              </View>
            </TruCard>
          ))}
        </View>

        <View style={{ height: 32 }} />
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  content: {
    paddingHorizontal: 16,
    paddingBottom: 24,
  },
  sectionTitle: {
    marginBottom: 8,
  },
  matchCard: {
    marginBottom: 14,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  matchPercent: {
    opacity: 0.8,
  },
  locationText: {
    opacity: 0.8,
    marginBottom: 6,
  },
  bioText: {
    marginBottom: 10,
  },
  footerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  vibePill: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    alignSelf: 'flex-start',
    fontSize: 11,
    opacity: 0.9,
  },
  sparkButton: {
    minWidth: 90,
  },
});
