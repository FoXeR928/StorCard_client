package com.storcard.client.ui.screens.auth

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.storcard.client.network.NetworkClient
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val dataStore: DataStore<Preferences>,
    private val networkClient: NetworkClient
) : ViewModel() {

    private val SERVER_URL_KEY = stringPreferencesKey("server_url")
    private val TOKEN_KEY = stringPreferencesKey("jwt_token")

    val saveUrl: Flow<String> = dataStore.data.map { it[SERVER_URL_KEY] ?: "" }
    val isAuthorized: Flow<Boolean?> = dataStore.data.map { it[TOKEN_KEY] != null }

    fun getUrl(url: String) {
        viewModelScope.launch {
            dataStore.edit { it[SERVER_URL_KEY] = url }
        }
    }
    fun connectToServer(url: String, onResult: (String) -> Unit) {
        viewModelScope.launch {
            val result = networkClient.checkConnect(url)

            result.onSuccess { message ->
                onResult(message)
            }
            result.onFailure { error ->
                onResult("Ошибка: ${error.localizedMessage}")
            }
        }
    }
    fun performLogin(
        user: String,
        pass: String,
        onResult: (String) -> Unit,
        onSuccess: () -> Unit
    ) {
        viewModelScope.launch {
            val result = networkClient.login(user, pass)
            result.onSuccess { message ->
                onResult(message)
                onSuccess()
            }
            result.onFailure { error ->
                onResult("Ошибка: ${error.localizedMessage}")
            }
        }
    }
}