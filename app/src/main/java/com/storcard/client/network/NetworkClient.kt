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


@Serializable
data class StatusServer(
    val status: String,
    val app: String,
    val version: String,
)

@Singleton
class NetworkClient @Inject constructor (
    private val dataStore: DataStore<Preferences>
){
    private val SERVER_URL_KEY = stringPreferencesKey("server_url")
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
}