import { Stack } from 'expo-router';
import { StyleSheet, View } from "react-native";

export default function Cards() {
  return (
    <>
      <Stack.Screen options={{ title: "Карты" }} />
      <View style={styles.container}>
      </View>
    </>
  );
}

const styles=StyleSheet.create({
  container: {
    gridAutoColumns: "",
    padding: 20,
  },
})