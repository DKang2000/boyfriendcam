import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { MilestoneZeroScreen } from './src/milestone0/MilestoneZeroScreen';

export default function App() {
  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <MilestoneZeroScreen />
    </SafeAreaProvider>
  );
}
