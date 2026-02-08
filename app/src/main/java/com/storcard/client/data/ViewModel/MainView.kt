package com.storcard.client.data.ViewModel

import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class  MainViewModel @Inject constructor(
    private val dataStore: DataStore<Preferences>
) : ViewModel() {
    private val TOKEN_KEY = stringPreferencesKey("jwt_token")
    var isAuthorized by mutableStateOf<Boolean?>(null)
        private set
    init {
        viewModelScope.launch {
            val token = dataStore.data.map { it[TOKEN_KEY] }.first()
            isAuthorized = !token.isNullOrEmpty()
        }
    }
}
