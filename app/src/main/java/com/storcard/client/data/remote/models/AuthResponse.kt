package com.storcard.client.data.remote.models

import kotlinx.serialization.Serializable

@Serializable
data class AuthResponse(
    val result: Boolean,
    val access_token: String,
    val message: String
)
