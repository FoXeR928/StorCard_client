import { FontAwesome } from '@expo/vector-icons';
import { Stack } from 'expo-router';
import { useState } from 'react';
import { FlatList, StyleSheet, Text, TextInput, View } from "react-native";

export default function Cards() {
  const [inputSearch,setInputSearch]=useState('');
  const SearchCards=()=>{
    const textData=inputSearch.toUpperCase();

  }
  return (
    <>
      <Stack.Screen 
        options={{ 
          title: "Карты",
          headerRight:()=>(
            <>
              <TextInput placeholder='Поиск карт' style={styles.input} value={inputSearch} onChangeText={setInputSearch} onChange={SearchCards} />
              <View style={styles.headerBlock}>
                <FontAwesome name="plus-circle" size={30} onPress={()=>alert(1)}/>
              </View>
            </>
          ), 
        }} 
      />
      <FlatList columnWrapperStyle={{justifyContent:"space-between"}} data={[1,249846516879846516359877496546987984653241687984654,"500000000000000000000000000000000000000099",1]} numColumns={2} renderItem={({item})=><Text style={styles.block}>{item}</Text>}/>
    </>
  );
}



const styles=StyleSheet.create({
  block:{
    width:"100%",
    height:150,
    textAlign:"center",
    padding:20,
    backgroundColor:"white",
    borderRadius:10,
    fontSize:30,
    marginHorizontal:20,
    marginVertical:10,
    overflow:"hidden"
  },
  headerBlock:{
    marginHorizontal:10,
  },
  input:{
    flex:1,
    padding:10,
    backgroundColor:"rgba(240, 240, 240, 1)",
    borderRadius:10,
    alignItems: "center",
    justifyContent: "center",
  },
})