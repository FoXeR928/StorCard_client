package com.storcard.client.data.remote

import com.storcard.client.data.remote.models.AuthResponse
import com.storcard.client.data.remote.models.StatusResponse
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.forms.submitForm
import io.ktor.client.request.get
import io.ktor.http.parameters
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ApiService @Inject constructor(
    private val client: HttpClient
) {
    suspend fun checkServerStatus(baseUrl: String): Result<StatusResponse>{
        return runCatching {
            client.get("https://$baseUrl/status").body<StatusResponse>()
        }
    }
    suspend fun login(baseUrl: String,username: String,password: String): Result<AuthResponse>{
        return runCatching {
            client.submitForm(
                url = "https://$baseUrl/auth/login",
                formParameters = parameters {
                    append("username",username)
                    append("password",password)
                }
            ).body<AuthResponse>()
        }
    }
}