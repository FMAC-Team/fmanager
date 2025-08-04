package me.aqnya.fmac.ui.screen

import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DeveloperMode
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import com.ramcosta.composedestinations.annotation.RootGraph
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import me.aqnya.fmac.R

@OptIn(ExperimentalMaterial3Api::class)
@Destination<RootGraph>(start = true)
@Composable
fun DeveloperModeScreen(navigator: DestinationsNavigator) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
    var developerMode by rememberSaveable {
        mutableStateOf(prefs.getBoolean("developer_mode", false))
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.settings_developer_mode)) },
                navigationIcon = {
                    IconButton(onClick = { navigator.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = null)
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            ListItem(
                headlineContent = { Text(stringResource(id = R.string.enabled)) },
                modifier = Modifier.clickable {
                    developerMode = true
                    prefs.edit().putBoolean("developer_mode", true).apply()
                },
                trailingContent = {
                    if (developerMode) {
                        Icon(Icons.Filled.Check, contentDescription = null)
                    }
                }
            )
            ListItem(
                headlineContent = { Text(stringResource(id = R.string.disabled)) },
                modifier = Modifier.clickable {
                    developerMode = false
                    prefs.edit().putBoolean("developer_mode", false).apply()
                },
                trailingContent = {
                    if (!developerMode) {
                        Icon(Icons.Filled.Check, contentDescription = null)
                    }
                }
            )
        }
    }
}