package com.storcard.client.network

import androidx.datastore.core.DataStore
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.security.cert.X509Certificate
import androidx.datastore.preferences.core.Preferences
import javax.inject.Inject
import javax.inject.Singleton
import javax.net.ssl.SSLContext
import javax.net.ssl.X509TrustManager
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import io.ktor.client.plugins.ResponseException
import io.ktor.client.plugins.expectSuccess
import io.ktor.client.request.forms.submitForm
import io.ktor.client.statement.bodyAsText
import io.ktor.http.parameters
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map


@Serializable
data class StatusServer(
    val status: String,
    val app: String,
    val version: String,
)

@Serializable
data class LoginResponse(
    val result: Boolean?=null,
    val access_token: String?=null,
    val message: String? = null,
)

@Singleton
class NetworkClient @Inject constructor (
    private val dataStore: DataStore<Preferences>
){
    private val SERVER_URL_KEY = stringPreferencesKey("server_url")
    private val TOKEN_KEY = stringPreferencesKey("jwt_token")

    private val trustManager = object : X509TrustManager {
        override fun checkClientTrusted(chain: Array<out X509Certificate?>?, authType: String?){}
        override fun checkServerTrusted(chain: Array<out X509Certificate?>?, authType: String?) {}
        override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
    }
    private val sslContext = SSLContext.getInstance("TLS").apply {
        init(null, arrayOf(trustManager), java.security.SecureRandom())
    }
    val client= HttpClient(OkHttp){
        install(ContentNegotiation){
            json(Json{
                ignoreUnknownKeys=true
                isLenient=true
            })
        }
        engine {
            config {
                sslSocketFactory(sslContext.socketFactory,trustManager)
                hostnameVerifier { _,_->true }
            }
        }
    }
    suspend fun checkConnect(url: String): Result<String>{
        return try {
            val response=client.get("https://$url/status")
            val statusData: StatusServer=response.body()
            if (statusData.app=="storcard"){
                dataStore.edit { preferences ->
                    preferences[SERVER_URL_KEY]=url
                }
                Result.success("Сервер подключен")
            }else{
                Result.success("Сервер не обнаружен")
            }
        }catch (err: Exception){
            Result.failure(err)
        }
    }
    private suspend fun getCurrentUrl(): String? {
        return dataStore.data.map { it[SERVER_URL_KEY] }.first()
    }

    suspend fun login(user: String, password: String): Result<String> {
        val baseUrl = getCurrentUrl() ?: return Result.failure(Exception("URL сервера не задан"))
        return try {
            val response: LoginResponse = client.submitForm(
                url = "https://$baseUrl/auth/login",
                formParameters = parameters {
                    append("username", user)
                    append("password", password)
                }
            ){expectSuccess=false}.body()
            if (response.result!=null && response.result && response.access_token!=null){
                dataStore.edit { it[TOKEN_KEY] = response.access_token }
                Result.success(response.message?:"Успешный вход")
            }else{
                Result.failure(Exception(response.message))
            }

        } catch (e: ResponseException) {
            val errorBody = e.response.bodyAsText()
            Result.failure(Exception("Ошибка сервера: ${e.response.status.value}"))
        }catch (e: Exception) {
            Result.failure(e)
        }
    }
    suspend fun logout() {
        dataStore.edit { preferences ->
            preferences.remove(TOKEN_KEY)
        }
    }
}