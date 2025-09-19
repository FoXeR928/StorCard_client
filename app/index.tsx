import AsyncStorage from "@react-native-async-storage/async-storage";
import { router } from "expo-router";
import { useState } from "react";
import { Button, StyleSheet, Text, TextInput, View } from "react-native";

const Auth=()=>{
  const [inputLogin,setInputLogin]=useState('');
  const [inputPassword,setInputPassword]=useState('');
  const getToken=async ()=>{
    const serverStorage=await AsyncStorage.getItem("server");
    if (serverStorage==null){
      router.navigate("/settingsStart")
    }else{
      if (inputLogin!="" && inputPassword!=""){
        fetch("http://"+serverStorage+"/auth/login",{
          method:"POST",
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body:new URLSearchParams({
            'username':inputLogin,
            'password':inputPassword,
          })
        }).then(response=>response.json()).then(json=>{
          if (json.result==true){
            AsyncStorage.setItem("token",json.access_token)
            router.navigate('/cards')
          }else{
            alert(json.message)
          }
        });
      }else{
        alert('Поля пустые')
      }
    }
  }
  return (
    <View style={styles.container}>
      <View style={styles.block}>
        <Text style={styles.h1}>Авторизация</Text>
        <TextInput style={styles.input} placeholder="Логин" onChangeText={setInputLogin} value={inputLogin}/>
        <TextInput style={styles.input} secureTextEntry placeholder="Пароль" onChangeText={setInputPassword} value={inputPassword}/>
        <Button title="Войти" onPress={getToken}/>
      </View>
    </View>
  );
}


const styles=StyleSheet.create({
  h1:{
    fontSize:23,
    fontWeight:"bold",
    marginBottom:10,
  },
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  block:{
    padding:20,
    backgroundColor:"white",
    borderRadius:10,
  },
  input:{
    padding:10,
    backgroundColor:"rgba(240, 240, 240, 1)",
    borderRadius:10,
    marginBottom:10,
  },
  headerBlock:{
    marginHorizontal:10,
  },
});

export default Auth; 