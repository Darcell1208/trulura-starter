// eslint.config.mjs

import js from '@eslint/js';
import importPlugin from 'eslint-plugin-import';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import reactNative from 'eslint-plugin-react-native';
import globals from 'globals';

export default [
  // 1️⃣ Global ignore rules (skip unused template files)
  {
    ignores: [
      'node_modules',
      'dist',
      'build',
      '.expo',
      '.expo-shared',
      'android',
      'ios',

      // 🚫 Ignore Expo starter TSX files we don't use in Trulura
      'components/external-link.tsx',
      'components/haptic-tab.tsx',
      'components/ui/**',

      // 🚫 Ignore the example screen that references missing UI
      'src/screens/TemplateScreen.js',
    ],
  },

  // 2️⃣ Actual ESLint rules
  {
    files: ['**/*.js', '**/*.jsx', '**/*.mjs'],

    languageOptions: {
      ecmaVersion: 2021,
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },

    plugins: {
      react,
      'react-hooks': reactHooks,
      'react-native': reactNative,
      import: importPlugin,
    },

    rules: {
      ...js.configs.recommended.rules,

      // React rules
      'react/react-in-jsx-scope': 'off',
      'react/prop-types': 'off',

      // Hooks rules
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',

      // Import cleanup
      'import/no-unresolved': 'error',
      'import/order': [
        'warn',
        {
          groups: ['builtin', 'external', 'internal', 'parent', 'sibling', 'index'],
          'newlines-between': 'always',
        },
      ],

      // General JS cleanup
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'no-console': 'warn',
    },
  },
];
