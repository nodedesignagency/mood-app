import { useState } from 'react';
import { useFonts } from 'expo-font';
import {
  InstrumentSerif_400Regular,
  InstrumentSerif_400Regular_Italic,
} from '@expo-google-fonts/instrument-serif';
import {
  SpaceGrotesk_400Regular,
  SpaceGrotesk_500Medium,
  SpaceGrotesk_700Bold,
} from '@expo-google-fonts/space-grotesk';
import { StatusBar } from 'expo-status-bar';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';

import { MoodCheckInScreen } from './src/screens/MoodCheckInScreen';
import { MoodCheckInLightScreen } from './src/screens/MoodCheckInLightScreen';

/** Which design direction opens by default. */
const DEFAULT_VERSION: Version = 'v2';

type Version = 'v1' | 'v2';

export default function App() {
  const [fontsLoaded] = useFonts({
    InstrumentSerif_400Regular,
    InstrumentSerif_400Regular_Italic,
    SpaceGrotesk_400Regular,
    SpaceGrotesk_500Medium,
    SpaceGrotesk_700Bold,
  });

  const [version, setVersion] = useState<Version>(DEFAULT_VERSION);

  return (
    <GestureHandlerRootView style={styles.root}>
      <SafeAreaProvider>
        <StatusBar style={version === 'v1' ? 'light' : 'dark'} />
        {/* Hold on a flat colour rather than flashing an unstyled screen. */}
        {fontsLoaded ? (
          <View style={styles.root}>
            {version === 'v1' ? <MoodCheckInScreen /> : <MoodCheckInLightScreen />}
            <VersionToggle version={version} onChange={setVersion} />
          </View>
        ) : (
          <View style={styles.root} />
        )}
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

/**
 * Temporary review affordance for comparing the two design directions on a
 * real device. Delete once a direction is chosen.
 */
function VersionToggle({
  version,
  onChange,
}: {
  version: Version;
  onChange: (v: Version) => void;
}) {
  const insets = useSafeAreaInsets();
  const dark = version === 'v1';

  return (
    <View style={[styles.toggle, { top: insets.top + 4 }]}>
      {(['v1', 'v2'] as const).map((v) => {
        const active = v === version;
        return (
          <Pressable
            key={v}
            onPress={() => onChange(v)}
            style={[
              styles.toggleItem,
              active && (dark ? styles.toggleActiveDark : styles.toggleActiveLight),
            ]}
          >
            <Text
              style={[
                styles.toggleLabel,
                { color: dark ? '#FFFFFF' : '#1C1A16', opacity: active ? 1 : 0.4 },
              ]}
            >
              {v.toUpperCase()}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#F7F5EF' },
  toggle: {
    position: 'absolute',
    alignSelf: 'center',
    flexDirection: 'row',
    borderRadius: 14,
    overflow: 'hidden',
    backgroundColor: 'rgba(128,128,128,0.18)',
  },
  toggleItem: { paddingHorizontal: 10, paddingVertical: 5 },
  toggleActiveDark: { backgroundColor: 'rgba(255,255,255,0.18)' },
  toggleActiveLight: { backgroundColor: 'rgba(255,255,255,0.75)' },
  toggleLabel: { fontFamily: 'SpaceGrotesk_500Medium', fontSize: 10, letterSpacing: 1.2 },
});
