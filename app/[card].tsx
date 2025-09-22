import AsyncStorage from '@react-native-async-storage/async-storage';
import { router, Stack, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from "react-native";
import { SvgXml } from 'react-native-svg';

const Card=()=> {
    const [cardInfo,setCard]=useState({id: null, name: "Карта", about: "Не надена карта", code_svg: null});
    const { card } = useLocalSearchParams();
    const getCard=async ()=>{
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
        fetch("http://"+serverStorage+"/cards/card/get?card_id="+card,{
            method:"GET",
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer '+tokenStorage,
            },
            }).then(response=>response.json()).then(json=>{
                if (json.result==true){
                    setCard(json.card)
                }
            }).catch((error)=>{
            console.log(error);
            alert("Ошибка опроса сервера");
        })
    };
    useEffect(() => {
        getCard()
    }, []);
    return (
        <>
            <Stack.Screen options={{ title: cardInfo.name }}/>
            <View style={styles.block}>
                <Text style={styles.h3}>Описание:</Text>
                <Text>{cardInfo.about}</Text>
                <Text style={styles.h3}>Штрихкод:</Text>
                <SvgXml xml={cardInfo.code_svg} width="200%"/>
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
    h3:{
        fontSize:17,
        fontWeight:"bold",
        marginBottom:10,
    },
    
})

export default Card;