package com.death.countdown

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        StorageService.init(applicationContext)
        setContent {
            CountdownTheme {
                CountdownApp(initial = Screen.Loading)
            }
        }
    }
}
