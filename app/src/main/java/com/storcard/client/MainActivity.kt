package com.storcard.client

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.storcard.client.ui.screens.main.MainViewModel
import com.storcard.client.ui.screens.main.MainScreen
import com.storcard.client.ui.screens.auth.loginScreen
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val viewModel: MainViewModel= hiltViewModel()
            val navController= rememberNavController()

            val isAuthorized = viewModel.isAuthorized
            if(isAuthorized==null){
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }else{
                NavHost(
                    navController=navController,
                    startDestination = if (isAuthorized) "main" else "login"
                ){
                    composable("login"){
                        loginScreen(onSuccess={
                            navController.navigate("main"){
                                popUpTo("login"){inclusive=true}
                            }
                        })
                    }
                    composable("main"){
                        MainScreen()
                    }
                }
            }


        }
    }
}
