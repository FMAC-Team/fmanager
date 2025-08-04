package me.aqnya.fmac.ui.screen

@Destination<RootGraph>
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