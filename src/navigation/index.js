// src/navigation/index.js
import { NavigationContainer } from '@react-navigation/native';
import Tabs from './Tabs';

export default function Navigation() {
  return (
    <NavigationContainer>
      <Tabs />
    </NavigationContainer>
  );
}
