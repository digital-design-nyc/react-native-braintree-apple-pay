
import { Platform } from 'react-native';

export default Platform.select({
  ios: require('./ios').default,
  android: require('./android').default,
})
