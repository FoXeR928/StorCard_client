import { useState } from "react";
import { Button, StyleSheet, Text, TextInput, View } from "react-native";

const Auth=()=>{
  const [inputLogin,setInputLogin]=useState('');
  const [inputPassword,setInputPassword]=useState('');

  return (
    <View style={styles.container}>
      <View style={styles.block}>
        <Text style={styles.h1}>Авторизация</Text>
        <TextInput style={styles.input} placeholder="Логин" onChangeText={setInputLogin} value={inputLogin}/>
        <TextInput style={styles.input} secureTextEntry placeholder="Пароль" onChangeText={setInputPassword} value={inputPassword}/>
        <Button title="Войти" onPress={()=>alert(inputLogin+inputPassword)}/>
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
  button:{
    borderRadius:10,
  }
});

export default Auth; 