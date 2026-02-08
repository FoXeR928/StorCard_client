package com.storcard.client.data.local

import androidx.datastore.preferences.core.stringPreferencesKey

object PreferencesKeys {
    val SERVER_URL = stringPreferencesKey("server_url")
    val JWT_TOKEN = stringPreferencesKey("jwt_token")
    val USERNAME = stringPreferencesKey("username")
}