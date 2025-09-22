import AsyncStorage from "@react-native-async-storage/async-storage";
import { Picker } from "@react-native-picker/picker";
import { router } from "expo-router";
import { useState } from "react";
import { Button, StyleSheet, Text, TextInput, View } from "react-native";

const AddCards=()=>{
    const [inputName,setInputName]=useState("")
    const [inputAbout,setInputAbout]=useState("")
    const [inputCode,setInputCode]=useState("")
    const [inputCodeType,setInputCodeType]=useState("code39")
    const createCard=async ()=>{
      const serverStorage=await AsyncStorage.getItem("server");
      const tokenStorage=await AsyncStorage.getItem("token");
      if (serverStorage==null){
        alert("Сервер не настроен")
        return
      }
      if (tokenStorage==null){
        router.navigate("/")
        return
      }
      if (inputName!="" && inputCode!=""){
        fetch("http://"+serverStorage+"/cards/add",{
          method:"POST",
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer '+tokenStorage,
          },
          body:JSON.stringify({
            "name": inputName,
            "about": inputAbout,
            "code": inputCode,
            "code_type": inputCodeType
          })
        }).then(response=>response.json()).then(json=>{
          alert(json.message)
        })
      }else{
        alert('Отсутсвет имя или код')
      }
    };
    return(
        <View style={styles.block}>
            <Text style={styles.h1}>Карта</Text>
            <Text>Имя карты</Text>
            <TextInput style={styles.input} onChangeText={nameCard=>setInputName(nameCard)} value={inputName}/>
            <Text>О карте</Text>
            <TextInput style={styles.input} onChangeText={aboutCard=>setInputAbout(aboutCard)} value={inputAbout} numberOfLines={3}/>
            <Picker 
                selectedValue={inputCodeType}
                onValueChange={(itemValue, itemIndex)=>setInputCodeType(itemValue)}
            >
                <Picker.Item label="Code 39" value="code39"/>
                <Picker.Item label="Code 128" value="code128"/>
                <Picker.Item label="Codabar" value="codabar"/>
                <Picker.Item label="EAN13" value="ean13"/>
                <Picker.Item label="QR Code" value="codeqr"/>
            </Picker>
            <Text>Код карты</Text>
            <TextInput style={styles.input} onChangeText={codeCard=>setInputCode(codeCard)} value={inputCode}/>
            <Button title='Создать' onPress={createCard}/>
        </View>
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

export default AddCards; 