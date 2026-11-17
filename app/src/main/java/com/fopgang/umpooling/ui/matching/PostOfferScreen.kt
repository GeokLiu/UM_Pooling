package com.fopgang.umpooling.ui.matching

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.fopgang.umpooling.SupabaseClientProvider
import com.fopgang.umpooling.data.CampusLocation
import com.fopgang.umpooling.data.GeoPoint
import com.fopgang.umpooling.data.NewTripOffer
import com.fopgang.umpooling.data.repository.RideRepository
import io.github.jan.supabase.auth.auth
import kotlinx.coroutines.launch

/**
 * Screen for drivers to post a ride offer (FR2.1 / FR3.1).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PostOfferScreen(
    repository: RideRepository = remember { RideRepository() },
    onOfferCreated: (() -> Unit)? = null
) {
    val coroutineScope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    var originLocation by remember { mutableStateOf<CampusLocation?>(null) }
    var destinationLocation by remember { mutableStateOf<CampusLocation?>(null) }
    var departureTime by remember { mutableStateOf("08:15") }
    var seats by remember { mutableIntStateOf(3) }
    var costInput by remember { mutableStateOf("3.00") }
    var isPosting by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Offer a Ride (Driver)") }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Trip Route Details",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    LocationSelectorField(
                        label = "Starting Point / Pickup Area",
                        selectedLocation = originLocation,
                        onLocationSelected = { originLocation = it }
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    LocationSelectorField(
                        label = "Destination Campus Zone",
                        selectedLocation = destinationLocation,
                        onLocationSelected = { destinationLocation = it }
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedTextField(
                        value = departureTime,
                        onValueChange = { departureTime = it },
                        label = { Text("Departure Time (e.g. 08:15)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Seats & Cost-Share (FR3.1)",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(text = "Available Seats:")
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            OutlinedButton(
                                onClick = { if (seats > 1) seats-- },
                                modifier = Modifier.size(40.dp)
                            ) { Text("-") }
                            Text(
                                text = "$seats",
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.padding(horizontal = 16.dp)
                            )
                            OutlinedButton(
                                onClick = { if (seats < 6) seats++ },
                                modifier = Modifier.size(40.dp)
                            ) { Text("+") }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = costInput,
                        onValueChange = { costInput = it },
                        label = { Text("Cost Share Per Seat (RM)") },
                        supportingText = { Text("Capped at RM 5.00 for non-profit cost sharing") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            Button(
                onClick = {
                    val user = SupabaseClientProvider.client.auth.currentUserOrNull()
                    if (user == null) {
                        coroutineScope.launch {
                            snackbarHostState.showSnackbar("Please sign in first.")
                        }
                        return@Button
                    }
                    val orig = originLocation
                    val dest = destinationLocation
                    if (orig == null || dest == null) {
                        coroutineScope.launch {
                            snackbarHostState.showSnackbar("Please pick both origin and destination.")
                        }
                        return@Button
                    }
                    val parsedCost = costInput.toDoubleOrNull()
                    if (parsedCost == null || parsedCost < 0.0 || parsedCost > 10.0) {
                        coroutineScope.launch {
                            snackbarHostState.showSnackbar("Cost must be between RM 0 and RM 10.")
                        }
                        return@Button
                    }

                    isPosting = true
                    coroutineScope.launch {
                        val offer = NewTripOffer(
                            driverId = user.id,
                            originGeo = orig.ewkt ?: GeoPoint.ewkt(101.6505, 3.1280),
                            destinationGeo = dest.ewkt ?: GeoPoint.ewkt(101.6505, 3.1280),
                            costPerSeat = parsedCost,
                            availableSeats = seats,
                            departureTime = departureTime,
                            originZone = orig.id,
                            destinationZone = dest.id
                        )

                        repository.createTripOffer(offer).fold(
                            onSuccess = {
                                isPosting = false
                                snackbarHostState.showSnackbar("Trip offer published successfully!")
                                onOfferCreated?.invoke()
                            },
                            onFailure = { err ->
                                isPosting = false
                                snackbarHostState.showSnackbar("Failed: ${err.message}")
                            }
                        )
                    }
                },
                enabled = !isPosting && originLocation != null && destinationLocation != null,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
            ) {
                if (isPosting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(Icons.Default.PlayArrow, contentDescription = null)
                    Spacer(modifier = Modifier.size(8.dp))
                    Text("Publish Trip Offer")
                }
            }
        }
    }
}
