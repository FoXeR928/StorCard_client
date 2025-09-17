import { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";

export default function Auth() {
  return (
    <View style={styles.container}>
        <Text>Логин</Text>
        <TextInput onChangeText={login=>setInputLogin(login)} value={inputLogin}/>
        <Text>Пароль</Text>
        <TextInput secureTextEntry onChangeText={password=>setInputPassword(password)} value={inputPassword}/>
    </View>
  );
}
const [inputLogin,setInputLogin]=useState("")
const [inputPassword,setInputPassword]=useState("")

const styles=StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
})