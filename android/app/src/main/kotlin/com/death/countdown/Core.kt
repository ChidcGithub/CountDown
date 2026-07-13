package com.death.countdown

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import java.time.Duration
import java.time.LocalDateTime
import java.util.Base64
import java.util.UUID

// ==================== Constants ====================
object AppConstants {
    const val APP_NAME = "Countdown"
    const val PACKAGE_NAME = "com.death.countdown"
    val VERSION = BuildConfig.VERSION_NAME
    const val DEVELOPER = "ChidcGithub"
    const val DEVELOPER_DEV_MODE = "Death God"
    const val GITHUB_URL = "https://github.com/ChidcGithub/CountDown"
    const val MIN_AGE = 60
    const val MAX_AGE = 100
    const val VERSION_TAP_COUNT = 3
    const val TITLE_TAP_COUNT = 5
}

object StorageKeys {
    const val DEVICE_ID = "deviceId"
    const val USERNAME = "username"
    const val BIRTH_DATE = "birthDate"
    const val DEATH_DATE = "deathDate"
    const val DEV_VERSION_CLICKS = "devModeVersionClicks"
    const val DEV_TITLE_CLICKS = "devModeTitleClicks"
    const val ENCRYPTED_DATA = "encryptedData"
    const val IS_FIRST_LAUNCH = "isFirstLaunch"
}

// ==================== Crypto ====================
object CryptoUtil {
    private val encoder = Base64.getUrlEncoder().withoutPadding()
    private val decoder = Base64.getUrlDecoder()

    fun encode(input: String, key: String): String =
        encoder.encodeToString("$input:$key".toByteArray(Charsets.UTF_8))

    fun decode(input: String, key: String): String? = try {
        val combined = String(decoder.decode(input), Charsets.UTF_8)
        val parts = combined.split(":")
        if (parts.size >= 2 && parts.last() == key)
            parts.subList(0, parts.size - 1).joinToString(":")
        else null
    } catch (e: Exception) { null }

    fun hash(input: String): String {
        var h = 0L
        for (c in input) {
            h = ((h shl 5) - h) + c.code
            h = h and 0xFFFFFFFFL
        }
        return h.toString(16).padStart(8, '0')
    }
}

// ==================== Data Models ====================
data class CountdownData(
    val username: String,
    val birthDate: LocalDateTime,
    val deathDate: LocalDateTime,
) {
    private val diff: Duration
        get() {
            val d = Duration.between(LocalDateTime.now(), deathDate)
            return if (d.isNegative || d.isZero) Duration.ZERO else d
        }

    val years: Long get() = diff.toDays() / 365
    val months: Long get() = (diff.toDays() % 365) / 30
    val days: Long get() = (diff.toDays() % 365) % 30
    val hours: Long get() = diff.toHours() % 24
    val minutes: Long get() = diff.toMinutes() % 60
    val seconds: Long get() = diff.seconds % 60
}

data class SearchUser(
    val username: String,
    var deathDate: LocalDateTime,
) {
    val countdownString: String
        get() {
            val d = Duration.between(LocalDateTime.now(), deathDate)
            if (d.isNegative || d.isZero) return "EXPIRED"
            val days = d.toDays()
            return "${days / 365}Y ${(days % 365) / 30}M ${(days % 365) % 30}D " +
                "${d.toHours() % 24}h ${d.toMinutes() % 60}m ${d.seconds % 60}s"
        }
}

// ==================== Storage (DataStore-backed) ====================
private val Context.dataStore by preferencesDataStore(name = "countdown_prefs")

object StorageService {
    private lateinit var appContext: Context
    private val cache = mutableMapOf<String, Any?>()
    private val writeScope = CoroutineScope(Dispatchers.IO)

    fun init(context: Context) {
        appContext = context.applicationContext
        // Preload all data into memory cache (single blocking read at startup)
        runBlocking {
            appContext.dataStore.data.first().asMap().forEach { (key, value) ->
                cache[key.name] = value
            }
        }
    }

    private fun getString(key: String, default: String? = null): String? = cache[key] as? String ?: default
    private fun getInt(key: String, default: Int = 0): Int = (cache[key] as? Int) ?: default
    private fun getBoolean(key: String, default: Boolean = false): Boolean = (cache[key] as? Boolean) ?: default

    private fun putString(key: String, value: String) {
        cache[key] = value
        writeScope.launch { appContext.dataStore.edit { it[stringPreferencesKey(key)] = value } }
    }

    private fun putInt(key: String, value: Int) {
        cache[key] = value
        writeScope.launch { appContext.dataStore.edit { it[intPreferencesKey(key)] = value } }
    }

    private fun putBoolean(key: String, value: Boolean) {
        cache[key] = value
        writeScope.launch { appContext.dataStore.edit { it[booleanPreferencesKey(key)] = value } }
    }

    fun getDeviceId(): String {
        var id = getString(StorageKeys.DEVICE_ID)
        if (id == null) {
            id = UUID.randomUUID().toString()
            putString(StorageKeys.DEVICE_ID, id)
        }
        return id
    }

    fun saveUserData(username: String, birthDate: LocalDateTime, deathDate: LocalDateTime) {
        val key = CryptoUtil.hash(getDeviceId())
        val dataJson = "$username|$birthDate|$deathDate"
        val encrypted = CryptoUtil.encode(dataJson, key)
        putString(StorageKeys.ENCRYPTED_DATA, encrypted)
        putString(StorageKeys.USERNAME, username)
        putString(StorageKeys.BIRTH_DATE, birthDate.toString())
        putString(StorageKeys.DEATH_DATE, deathDate.toString())
    }

    fun loadUserData(): CountdownData? {
        val username = getString(StorageKeys.USERNAME) ?: return null
        val birthStr = getString(StorageKeys.BIRTH_DATE) ?: return null
        val deathStr = getString(StorageKeys.DEATH_DATE) ?: return null
        return parseData(username, birthStr, deathStr)
    }

    fun loadEncryptedUserData(): CountdownData? {
        val key = CryptoUtil.hash(getDeviceId())
        val encrypted = getString(StorageKeys.ENCRYPTED_DATA) ?: return null
        val decrypted = CryptoUtil.decode(encrypted, key) ?: return null
        val parts = decrypted.split("|")
        if (parts.size != 3) return null
        return parseData(parts[0], parts[1], parts[2])
    }

    private fun parseData(username: String, birthStr: String, deathStr: String): CountdownData? = try {
        CountdownData(username, LocalDateTime.parse(birthStr), LocalDateTime.parse(deathStr))
    } catch (e: Exception) { null }

    fun isFirstLaunch(): Boolean {
        if (!cache.containsKey(StorageKeys.IS_FIRST_LAUNCH)) {
            putBoolean(StorageKeys.IS_FIRST_LAUNCH, false)
            return true
        }
        return false
    }

    fun getDevVersionClicks() = getInt(StorageKeys.DEV_VERSION_CLICKS, 0)
    fun getDevTitleClicks() = getInt(StorageKeys.DEV_TITLE_CLICKS, 0)
    fun setDevVersionClicks(n: Int) = putInt(StorageKeys.DEV_VERSION_CLICKS, n)
    fun setDevTitleClicks(n: Int) = putInt(StorageKeys.DEV_TITLE_CLICKS, n)
    fun clearAllData() {
        cache.clear()
        writeScope.launch { appContext.dataStore.edit { it.clear() } }
    }
}

// ==================== Algorithm ====================
fun calculateDeathDate(username: String, birthDate: LocalDateTime, deviceId: String): LocalDateTime {
    val birthStr = "%04d-%02d-%02d".format(birthDate.year, birthDate.monthValue, birthDate.dayOfMonth)
    val combined = "$username:$birthStr:$deviceId"
    var h = 0L
    for (c in combined) {
        h = ((h shl 5) - h) + c.code
        h = h and 0xFFFFFFFFL
    }
    val age = (h % (AppConstants.MAX_AGE - AppConstants.MIN_AGE)).toInt() + AppConstants.MIN_AGE
    val hash2 = (h shr 10) and 0xFFFFFF
    val ms = (h % 1000).toInt()
    val totalSec = (hash2 % (24 * 60 * 60)).toInt()
    val hours = totalSec / 3600
    val minutes = (totalSec % 3600) / 60
    val seconds = totalSec % 60
    return LocalDateTime.of(
        birthDate.year + age, birthDate.month, birthDate.dayOfMonth,
        hours, minutes, seconds, ms * 1_000_000
    )
}
