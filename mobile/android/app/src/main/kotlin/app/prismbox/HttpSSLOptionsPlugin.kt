package app.prismbox

import android.util.Base64
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.net.ssl.*

/**
 * HttpSSLOptionsPlugin
 * 用于配置Android平台的SSL/TLS设置
 */
class HttpSSLOptionsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "app.prismbox/http_ssl_options")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "apply" -> {
                try {
                    val allowSelfSigned = call.argument<Boolean>("allowSelfSigned") ?: false
                    val serverHost = call.argument<String>("serverHost")
                    val clientCertData = call.argument<String>("clientCertData")
                    val clientCertPassword = call.argument<String>("clientCertPassword")

                    applySSLOptions(
                        allowSelfSigned = allowSelfSigned,
                        serverHost = serverHost,
                        clientCertData = clientCertData,
                        clientCertPassword = clientCertPassword
                    )

                    result.success(true)
                } catch (e: Exception) {
                    result.error("SSL_CONFIG_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun applySSLOptions(
        allowSelfSigned: Boolean,
        serverHost: String?,
        clientCertData: String?,
        clientCertPassword: String?
    ) {
        // 配置KeyManager（如果有客户端证书）
        val keyManagers = if (clientCertData != null) {
            loadClientCertificate(clientCertData, clientCertPassword)
        } else {
            null
        }

        // 配置TrustManager
        val trustManagers = if (allowSelfSigned && serverHost != null) {
            arrayOf<TrustManager>(AllowSelfSignedTrustManager(serverHost))
        } else {
            null
        }

        // 配置SSLContext
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(
            keyManagers,
            trustManagers ?: getDefaultTrustManagers(),
            null
        )

        // 设置默认配置
        HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.socketFactory)
        HttpsURLConnection.setDefaultHostnameVerifier(
            if (allowSelfSigned && serverHost != null) {
                AllowSelfSignedHostnameVerifier(serverHost)
            } else {
                HttpsURLConnection.getDefaultHostnameVerifier()
            }
        )
    }

    private fun loadClientCertificate(
        certData: String,
        password: String?
    ): Array<KeyManager>? {
        return try {
            val certBytes = Base64.decode(certData, Base64.DEFAULT)
            val keyStore = KeyStore.getInstance("PKCS12")
            val passwordChars = password?.toCharArray()

            keyStore.load(ByteArrayInputStream(certBytes), passwordChars)

            val keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
            keyManagerFactory.init(keyStore, passwordChars)

            keyManagerFactory.keyManagers
        } catch (e: Exception) {
            null
        }
    }

    private fun getDefaultTrustManagers(): Array<TrustManager> {
        val trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        trustManagerFactory.init(null as KeyStore?)
        return trustManagerFactory.trustManagers
    }

    /**
     * 允许自签名证书的TrustManager
     */
    private class AllowSelfSignedTrustManager(private val serverHost: String) : X509TrustManager {
        private val defaultTrustManager = getDefaultTrustManager()

        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            defaultTrustManager.checkClientTrusted(chain, authType)
        }

        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            try {
                defaultTrustManager.checkServerTrusted(chain, authType)
            } catch (e: Exception) {
                // 如果是自签名证书，检查主机名是否匹配
                if (chain != null && chain.isNotEmpty()) {
                    val cert = chain[0]
                    val certHost = cert.subjectDN.name
                    if (certHost.contains(serverHost) || serverHost.contains(certHost)) {
                        // 主机名匹配，接受证书
                        return
                    }
                }
                throw e
            }
        }

        override fun getAcceptedIssuers(): Array<X509Certificate> {
            return defaultTrustManager.acceptedIssuers
        }

        private fun getDefaultTrustManager(): X509TrustManager {
            val trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
            trustManagerFactory.init(null as KeyStore?)
            return trustManagerFactory.trustManagers.first() as X509TrustManager
        }
    }

    /**
     * 允许自签名证书的HostnameVerifier
     */
    private class AllowSelfSignedHostnameVerifier(private val serverHost: String) : HostnameVerifier {
        private val defaultVerifier = HttpsURLConnection.getDefaultHostnameVerifier()

        override fun verify(hostname: String?, session: SSLSession?): Boolean {
            return try {
                defaultVerifier.verify(hostname, session)
            } catch (e: Exception) {
                // 如果默认验证失败，检查主机名是否匹配
                hostname != null && (hostname.contains(serverHost) || serverHost.contains(hostname))
            }
        }
    }
}

