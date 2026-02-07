package com.storcard.client.data

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

    val saveUrl: Flow<String> = dataStore.data.map { it[SERVER_URL_KEY] ?: "" }

    fun getUrl(url: String) {
        viewModelScope.launch {
            dataStore.edit { it[SERVER_URL_KEY] = url }
        }
    }
    fun connectToServer(url: String, onResult: (String) -> Unit) {
        viewModelScope.launch {
            val result = networkClient.checkConnect(url)

            result.onSuccess { message ->
                onResult(message) // Передаем сообщение в UI
            }
            result.onFailure { error ->
                onResult("Ошибка: ${error.localizedMessage}")
            }
        }
    }
}