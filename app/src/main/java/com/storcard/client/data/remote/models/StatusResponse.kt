package com.storcard.client.data.remote.models

import kotlinx.serialization.Serializable

@Serializable
data class StatusResponse(
    val status: String,
    val app: String,
    val version: String
)
