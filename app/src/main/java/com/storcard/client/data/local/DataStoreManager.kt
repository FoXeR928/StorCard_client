package com.storcard.client.data.local

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DataStoreManager @Inject constructor(
    private val dataStore:  DataStore<Preferences>
){
    suspend fun  saveString(key: Preferences.Key<String>,values: String){
        dataStore.edit { preferences -> preferences[key]=values }
    }
    suspend fun getString(key: Preferences.Key<String>): String?{
        return dataStore.data.map { it[key] }.first()
    }
    suspend fun remove(key: Preferences.Key<String>){
        dataStore.edit { preferences -> preferences.remove(key) }
    }
    fun getStringFlow(key: Preferences.Key<String>): Flow<String?>{
        return dataStore.data.map { it[key] }
    }
    suspend fun saveServerUrl(url: String)=saveString(PreferencesKeys.SERVER_URL,url)
    suspend fun saveToken(token: String) = saveString(PreferencesKeys.JWT_TOKEN, token)
    suspend fun saveUsername(username: String) = saveString(PreferencesKeys.USERNAME, username)

    suspend fun getServerUrl(): String? = getString(PreferencesKeys.SERVER_URL)
    suspend fun getToken(): String? = getString(PreferencesKeys.JWT_TOKEN)
    suspend fun getUsername(): String? = getString(PreferencesKeys.USERNAME)

    suspend fun clearAuthData() {
        remove(PreferencesKeys.JWT_TOKEN)
        remove(PreferencesKeys.USERNAME)
    }
}

