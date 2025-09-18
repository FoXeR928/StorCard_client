import { Stack } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, Text, TextInput, View } from "react-native";

const Settings=()=>{
  const [inputServer,setInputServer]=useState('');
  return (
    <>
      <Stack.Screen options={{ title: "Настройка" }} />
      <View style={styles.block}>
        <Text style={styles.h1}>Сервер</Text>
        <TextInput style={styles.input} onChangeText={server=>setInputServer(server)} value={inputServer} placeholder='Хост:Порт'/>
      </View>
    </>
  );
}

const styles=StyleSheet.create({
  block:{
    padding:20,
    backgroundColor:"white",
    borderRadius:10,
    marginHorizontal:20,
    marginVertical:10,
  },
  h1:{
    fontSize:23,
    fontWeight:"bold",
    marginBottom:10,
  },
  input:{
    padding:10,
    backgroundColor:"rgba(240, 240, 240, 1)",
    borderRadius:10,
  },
})

export default Settings; 