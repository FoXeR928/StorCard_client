import { FontAwesome } from '@expo/vector-icons';
import { router, Tabs } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';

export default function TabLayout() {
  const [inputSearch,setInputSearch]=useState('');
  const SearchCards=()=>{
    const textData=inputSearch.toUpperCase();
  };
  return (
    <>
      <Tabs>
        <Tabs.Screen name="cards"
          options={{ 
            title: "Карты",
            headerRight:()=>(
              <>
                <TextInput placeholder='Поиск карт' style={styles.input} value={inputSearch} onChangeText={setInputSearch} onChange={SearchCards} />
                <View style={styles.headerBlock}>
                  <FontAwesome name="plus-circle" size={30} onPress={()=>router.navigate("/addCard")}/>
                </View>
              </>
            ), 
          }}  
        />
        <Tabs.Screen name="settings" options={{ title: "Настройка" }}/>
      </Tabs>
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