// src/theme/auraTheme.js

export const auraTheme = {
  bg: {
    app: '#050715',
    panel: '#0b1020',
    hairline: 'rgba(255,255,255,0.06)',
  },

  text: {
    primary: '#EAF2FF',
    secondary: 'rgba(234,242,255,0.72)',
    mute: 'rgba(234,242,255,0.44)',
  },

  accents: {
    home: '#5ce2c0', // mint
    explore: '#7dd1ff', // sky
    glow: '#ffc666', // gold
    spark: '#ff6aac', // neon pink
    vent: '#ab4eff', // lilac
    profile: '#9f8aff', // soft violet
    creator: '#ffb36b', // peachy orange
  },

  gradients: {
    sunrise: ['#FFB457', '#FF6DD9'],
    aurora: ['#7EEBFA', '#80FF72'],
    orb: ['#6B73FF', '#000DFF'], // default orb gradient
    candy: ['#FF8AE2', '#FFDF6B'],
    moon: ['#9F8AFF', '#6B78FF'],
    ember: ['#FF5D6B', '#FFB45C'],
    royal: ['#8A7BFF', '#4D9CFF'],
  },

  glow: {
    lg: {
      shadowColor: '#9F8AFF',
      shadowOpacity: 0.35,
      shadowRadius: 32,
      elevation: 20,
    },
    pill: {
      shadowColor: '#000000',
      shadowOpacity: 0.5,
      shadowRadius: 16,
      elevation: 10,
    },
  },
};
