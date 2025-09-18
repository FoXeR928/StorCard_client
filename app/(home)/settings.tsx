import AsyncStorage from '@react-native-async-storage/async-storage';
import { Stack } from 'expo-router';
import { useEffect, useState } from 'react';
import { Button, StyleSheet, Text, TextInput, View } from "react-native";

const Settings=()=>{
  const [inputServer,setInputServer]=useState("");
  const getServer=async ()=>{
    try{
      const serverStorage=await AsyncStorage.getItem("server");
      if (serverStorage==null){
        setInputServer("")
      }else{
        setInputServer(serverStorage)
      }
    }catch (error) {
      console.log(error);
      setInputServer("")
    }
  };
  const connectServer=(server:string)=>{
    fetch("http://"+server+"/status",{
      method:"GET",
      headers: {
        'Content-Type': 'application/json',
      },
    }).then(response=>response.json()).then(json=>{
      if (json.status="OK"){
        AsyncStorage.setItem("server",server);
        alert("Сервер добавлен");
      }else{
        alert("Ошибка опроса сервера");
      }
    }).catch((error)=>{
      console.log(error);
      alert("Ошибка опроса сервера");
      getServer()
    });
  };
  useEffect(() => {
      getServer()
  }, []);
  return (
    <>
      <Stack.Screen options={{ title: "Настройка" }} />
      <View style={styles.block}>
        <Text style={styles.h1}>Сервер</Text>
        <TextInput style={styles.input} onChangeText={server=>setInputServer(server)} value={inputServer} placeholder='Хост:Порт'/>
        <Button title='Подключить' onPress={()=>connectServer(inputServer)}/>
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
    marginBottom:10,
  },
})

export default Settings; 