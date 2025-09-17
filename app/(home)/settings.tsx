import { Stack } from 'expo-router';
import { StyleSheet, Text, View } from "react-native";

export default function Settings() {
  return (
    <>
      <Stack.Screen options={{ title: "Настройка" }} />
      <View style={styles.container}>
        <Text>Edit app/index.tsx to edit this screen.</Text>
      </View>
    </>
  );
}

const styles=StyleSheet.create({
  container: {
    padding: 20,
  },
})