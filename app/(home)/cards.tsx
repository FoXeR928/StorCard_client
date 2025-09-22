import AsyncStorage from '@react-native-async-storage/async-storage';
import { Link, router } from 'expo-router';
import { useEffect, useState } from 'react';
import { FlatList, StyleSheet } from "react-native";

const Cards=()=> {
  const [columnsNumber,setColumnsNumber]=useState(2);
  const [cards,setCards]=useState([{ id: null,name: "Карты не найдены",own_login: null}]);
  const getCards=async ()=>{
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
    fetch("http://"+serverStorage+"/cards/get",{
      method:"GET",
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer '+tokenStorage,
      },
    }).then(response=>response.json()).then(json=>setCards(json.cards)).catch((error)=>{
      console.log(error);
      alert("Ошибка опроса сервера");
    })
  };
  useEffect(() => {
    getCards()
  }, []);
  return (
    <FlatList columnWrapperStyle={{justifyContent:"space-between"}} data={cards} numColumns={columnsNumber} renderItem={({item})=>
      <Link href={{pathname:'/[card]',params:{card:Number(item.id)}}} style={styles.block}>{item.name}</Link>}
    />
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
  }
})

export default Cards