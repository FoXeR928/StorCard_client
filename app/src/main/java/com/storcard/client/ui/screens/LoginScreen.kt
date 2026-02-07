package com.storcard.client.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import com.storcard.client.data.LoginViewModel
import com.storcard.client.network.NetworkClient
import kotlinx.coroutines.launch

@Composable
fun loginScreen(viewModel: LoginViewModel= hiltViewModel()) {
    val savedServerUrl by viewModel.saveUrl.collectAsState(initial = "")
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var showSetting by remember { mutableStateOf(false) }
    var server by remember { mutableStateOf("") }
    val snackbarHostState=remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    LaunchedEffect(savedServerUrl) {
        server=savedServerUrl
    }

    Box(
        modifier= Modifier.fillMaxSize()
    ){
        SnackbarHost(
            hostState = snackbarHostState,
            modifier= Modifier.align(Alignment.TopCenter).padding(top = 50.dp).padding(horizontal = 10.dp)
        ){
                data -> Snackbar(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
            contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
        ){
            Text(data.visuals.message)
        }
        }
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            OutlinedTextField(
                value = username,
                onValueChange = {username=it},
                placeholder = { Text("Логин") }
            )
            OutlinedTextField(
                value = password,
                onValueChange = {password=it},
                placeholder = { Text("Пароль") }
            )
            Button(
                onClick = {
                    println("test")
                }
            ){
                Text(
                    text = "Войти"
                )
            }

        }
        Column(
            modifier= Modifier.align(Alignment.BottomEnd)
        ) {
            AnimatedVisibility(showSetting) {
                Surface(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp),
                    shape = RoundedCornerShape(12.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Настройки сервера", style = MaterialTheme.typography.labelLarge)
                        OutlinedTextField(
                            value = server,
                            modifier= Modifier.fillMaxWidth().padding(vertical = 10.dp),
                            onValueChange = {server=it},
                            placeholder = { Text("Сервер (localhost:11000)") }
                        )
                        Button(
                            modifier = Modifier.align(Alignment.End),
                            onClick = {
                                viewModel.connectToServer(server) { message ->
                                    scope.launch {
                                        snackbarHostState.showSnackbar(message)
                                    }
                                }
                            }
                        ) {
                            Text(
                                text = "Подключить"
                            )
                        }
                    }
                }
            }

            FloatingActionButton(
                shape = CircleShape,
                modifier = Modifier.padding(end = 24.dp, bottom = 24.dp, top = 10.dp).align(Alignment.End),
                onClick = {showSetting=!showSetting}
            ) {
                Icon(Icons.Filled.Settings,"Настройки")
            }
        }

    }
}