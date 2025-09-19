import { FontAwesome } from '@expo/vector-icons';
import { router, Stack } from 'expo-router';
import { StyleSheet, View } from 'react-native';

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="index" 
        options={{
          title: "Авторизация",
          headerLeft: () => null,
          headerRight:()=>(
            <View style={styles.headerBlock}>
              <FontAwesome name="database" size={30} onPress={()=>router.navigate("/settingsStart")}/>
            </View>
          ), 
        }}/>
      <Stack.Screen name="(home)" 
        options={{ 
          headerShown: false,
        }}/>
      <Stack.Screen name="settingsStart" options={{ title: "Настройка" }}/>
      <Stack.Screen name="addCard" options={{ title: "Добавление карты" }}/>
    </Stack>
  );
}

const styles=StyleSheet.create({
  headerBlock:{
    marginHorizontal:10,
  },
})