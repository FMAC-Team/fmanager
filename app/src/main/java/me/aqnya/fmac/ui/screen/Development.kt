package me.aqnya.fmac.ui.screen

import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DeveloperMode
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import com.ramcosta.composedestinations.annotation.RootGraph
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import android.util.Log
import me.aqnya.fmac.Natives
import me.aqnya.fmac.R

@OptIn(ExperimentalMaterial3Api::class)
@Destination<RootGraph>
@Composable
fun DeveloperModeScreen(navigator: DestinationsNavigator) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
    var developerMode by rememberSaveable {
        mutableStateOf(prefs.getBoolean("developer_mode", false))
    }
    LaunchedEffect(Unit) {
        val isRoot = Natives.isroot()
        Log.d("Native root check: $isRoot")
    }

    

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.settings_developer_mode)) },
                navigationIcon = {
                    IconButton(onClick = { navigator.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
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
        //Enable Dev mode.
            ListItem(
                leadingContent = {
                    Icon(Icons.Filled.DeveloperMode, contentDescription = null)
                },
                headlineContent = {
                    Text(stringResource(id = R.string.settings_developer_mode))
                },
                supportingContent = {
                    Text(
                        stringResource(id = R.string.settings_developer_mode_summary) + " · " +
                                stringResource(
                                    id = if (developerMode)
                                        R.string.enabled
                                    else
                                        R.string.disabled
                                )
                    )
                },
                trailingContent = {
                    Switch(
                        checked = developerMode,
                        onCheckedChange = {
                            developerMode = it
                            prefs.edit().putBoolean("developer_mode", it).apply()
                        }
                    )
                }
            )
            // Fake version
  var fakeVersionEnabled by rememberSaveable {
    mutableStateOf(prefs.getBoolean("fake_version", false))
}

ListItem(
    modifier = Modifier.alpha(if (developerMode) 1f else 0.5f),
    headlineContent = {
        Text("Fake Version")
    },
    supportingContent = {
        Text("Simulate a fake version number for testing purposes")
    },
    trailingContent = {
        Switch(
            checked = fakeVersionEnabled,
            onCheckedChange = {
                if (developerMode) {
                    fakeVersionEnabled = it
                    prefs.edit().putBoolean("fake_version", it).apply()
                }
            },
            enabled = developerMode
        )
    }
)
        }
    }
}