// src/screens/SignUpScreen.js

import React, { useState } from 'react';
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { supabase } from '../lib/supabaseClient';

export default function SignUpScreen({ navigation }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [infoMsg, setInfoMsg] = useState('');

  const handleSignUp = async () => {
    setErrorMsg('');
    setInfoMsg('');

    if (!email || !password) {
      setErrorMsg('Please enter an email and password.');
      return;
    }

    setLoading(true);

    const { data, error } = await supabase.auth.signUp(
      {
        email: email.trim(),
        password: password,
      },
      {
        // For now, send them back to your dev app after confirming email.
        emailRedirectTo: 'http://localhost:8081',
      }
    );

    setLoading(false);

    if (error) {
      console.log('Sign up error:', error);
      setErrorMsg(error.message || 'Something went wrong. Please try again.');
      return;
    }

    // If "Confirm email" is ON in Supabase, they must check email
    // If it's OFF, they may be logged in immediately.
    if (data?.user && !data.session) {
      setInfoMsg('Check your email to confirm your account, then sign in.');
    } else {
      setInfoMsg('Account created. You can sign in now.');
      // Optionally navigate back to SignIn
      // navigation.replace('SignIn');
    }
  };

  const goToSignIn = () => {
    navigation.replace('SignIn');
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={styles.container}>
        <View style={styles.inner}>
          <Text style={styles.title}>Create Account</Text>

          {errorMsg ? <Text style={styles.errorText}>{errorMsg}</Text> : null}
          {infoMsg ? <Text style={styles.infoText}>{infoMsg}</Text> : null}

          <TextInput
            style={styles.input}
            placeholder="Email"
            placeholderTextColor="#999"
            autoCapitalize="none"
            keyboardType="email-address"
            value={email}
            onChangeText={setEmail}
          />

          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor="#999"
            secureTextEntry
            value={password}
            onChangeText={setPassword}
          />

          <TouchableOpacity
            style={[styles.button, loading && styles.buttonDisabled]}
            onPress={handleSignUp}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Sign Up</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity onPress={goToSignIn} style={styles.linkWrapper}>
            <Text style={styles.linkText}>Already have an account? Sign in</Text>
          </TouchableOpacity>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5FF', // light neutral like your sign-in screen
    justifyContent: 'center',
    alignItems: 'center',
  },
  inner: {
    width: '90%',
    maxWidth: 500,
  },
  title: {
    fontSize: 28,
    fontWeight: '600',
    textAlign: 'center',
    marginBottom: 24,
    color: '#111',
  },
  input: {
    width: '100%',
    height: 48,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#DDD',
    paddingHorizontal: 12,
    backgroundColor: '#fff',
    marginBottom: 12,
    fontSize: 16,
  },
  button: {
    width: '100%',
    height: 50,
    backgroundColor: '#5B3FFF', // Trulura purple-ish
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  buttonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
  linkWrapper: {
    marginTop: 18,
    alignItems: 'center',
  },
  linkText: {
    color: '#5B3FFF',
    fontSize: 14,
  },
  errorText: {
    color: '#D11A2A',
    marginBottom: 8,
    textAlign: 'center',
  },
  infoText: {
    color: '#0F766E',
    marginBottom: 8,
    textAlign: 'center',
  },
});
