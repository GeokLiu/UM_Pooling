package com.fopgang.umpooling.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.fopgang.umpooling.R
import com.fopgang.umpooling.data.repository.PersonalImpact

/** Authenticated routes use persisted totals; sample charts stay in explicit demo mode. */
@Composable
fun PersonalImpactScreen(impact: PersonalImpact?, loaded: Boolean, back: () -> Unit) {
    Column(Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        TextButton(back) { Text(stringResource(R.string.booking_back)) }
        Text(stringResource(R.string.carbon_footprint), style = MaterialTheme.typography.headlineMedium)
        if (!loaded) {
            Text(stringResource(R.string.account_stats_unavailable))
        } else {
            Text("${stringResource(R.string.rides)}: ${impact?.totalTrips ?: 0}")
            Text("${stringResource(R.string.co2_saved)}: ${impact?.co2Kg ?: 0.0} kg")
            Text(impact?.tierName ?: "No Badge")
            if ((impact?.totalTrips ?: 0) == 0) Text(stringResource(R.string.account_no_activity))
        }
    }
}
