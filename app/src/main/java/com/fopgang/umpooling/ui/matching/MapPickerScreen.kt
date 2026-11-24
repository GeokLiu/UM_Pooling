package com.fopgang.umpooling.ui.matching

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SmallFloatingActionButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.fopgang.umpooling.data.CampusLocation
import com.fopgang.umpooling.data.CampusLocationProvider
import com.fopgang.umpooling.data.Haversine
import kotlin.math.roundToInt

import androidx.compose.ui.tooling.preview.Preview
import com.fopgang.umpooling.ui.theme.UMPoolingTheme

// UM Campus Reference Center: FSKTM / Central Campus
private const val UM_CENTER_LAT = 3.1209
private const val UM_CENTER_LNG = 101.6538

// GPS to Canvas Scale: ~1 degree latitude is ~111 km
// At UM latitude, 0.01 deg lat/lng is ~1.1 km
private const val DEFAULT_SCALE = 38000f

/**
 * Interactive Campus Map Picker (FR2.1 / FR2.2).
 * Enables visual location selection across UM campus landmarks & off-campus survey hotspots,
 * as well as custom GPS pin drops for commuter zones lacking predefined centroids.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MapPickerScreen(
    initialLocation: CampusLocation? = null,
    onLocationConfirmed: (CampusLocation) -> Unit,
    onDismiss: () -> Unit
) {
    // Current map center coordinates
    var centerLat by remember { mutableDoubleStateOf(initialLocation?.lat ?: UM_CENTER_LAT) }
    var centerLng by remember { mutableDoubleStateOf(initialLocation?.lng ?: UM_CENTER_LNG) }
    var scale by remember { mutableFloatStateOf(DEFAULT_SCALE) }

    // Selected Pin state
    var selectedLat by remember { mutableDoubleStateOf(initialLocation?.lat ?: UM_CENTER_LAT) }
    var selectedLng by remember { mutableDoubleStateOf(initialLocation?.lng ?: UM_CENTER_LNG) }
    var selectedName by remember { mutableStateOf(initialLocation?.name ?: "UM Campus Center") }
    var selectedCategory by remember { mutableStateOf(initialLocation?.category ?: "Campus Landmark") }
    var isCustomPin by remember { mutableStateOf(initialLocation?.id?.startsWith("custom_") == true) }

    // Find nearest landmark to currently selected pin
    val nearestLandmark = remember(selectedLat, selectedLng) {
        CampusLocationProvider.allLocations
            .filter { it.lat != null && it.lng != null }
            .minByOrNull { Haversine.haversineKm(selectedLat, selectedLng, it.lat!!, it.lng!!) }
    }

    val distanceToNearestKm = remember(nearestLandmark, selectedLat, selectedLng) {
        nearestLandmark?.let {
            if (it.lat != null && it.lng != null) {
                Haversine.haversineKm(selectedLat, selectedLng, it.lat, it.lng)
            } else null
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Pick Location on Map", style = MaterialTheme.typography.titleMedium)
                        Text(
                            "Tap landmark or tap map to drop custom pin",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFFFDEBE3)
                )
            )
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(Color(0xFFF7F2EC))
        ) {
            // Interactive Map Canvas with Pan & Tap Gestures
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(Unit) {
                        detectDragGestures { change, dragAmount ->
                            change.consume()
                            // Convert screen drag (pixels) to lat/lng delta
                            val dLat = (dragAmount.y / scale).toDouble()
                            val dLng = (-dragAmount.x / (scale * 1.05f)).toDouble()
                            centerLat += dLat
                            centerLng += dLng
                        }
                    }
                    .pointerInput(Unit) {
                        detectTapGestures { tapOffset ->
                            // Calculate clicked GPS coordinate from canvas center
                            val width = size.width
                            val height = size.height
                            val clickedLng = centerLng + ((tapOffset.x - width / 2f) / (scale * 1.05f))
                            val clickedLat = centerLat - ((tapOffset.y - height / 2f) / scale)

                            // Check if tapped near any known landmark (within 30 px)
                            val tappedPreset = CampusLocationProvider.allLocations.firstOrNull { loc ->
                                if (loc.lat == null || loc.lng == null) return@firstOrNull false
                                val locX = width / 2f + ((loc.lng - centerLng) * scale * 1.05f).toFloat()
                                val locY = height / 2f - ((loc.lat - centerLat) * scale).toFloat()
                                val dx = tapOffset.x - locX
                                val dy = tapOffset.y - locY
                                (dx * dx + dy * dy) < 900f // 30 px radius
                            }

                            if (tappedPreset != null) {
                                selectedLat = tappedPreset.lat!!
                                selectedLng = tappedPreset.lng!!
                                selectedName = tappedPreset.name
                                selectedCategory = tappedPreset.category
                                isCustomPin = false
                            } else {
                                selectedLat = clickedLat
                                selectedLng = clickedLng
                                selectedName = "Custom Pin (${String.format("%.4f", clickedLat)}, ${String.format("%.4f", clickedLng)})"
                                selectedCategory = "Custom Location"
                                isCustomPin = true
                            }
                        }
                    }
            ) {
                val canvasWidth = size.width
                val canvasHeight = size.height
                val centerX = canvasWidth / 2f
                val centerY = canvasHeight / 2f

                // 1. Draw subtle campus grid lines
                val gridSpacing = 80f
                for (x in 0..(canvasWidth / gridSpacing).toInt()) {
                    drawLine(
                        color = Color(0xFFE2DDD7),
                        start = Offset(x * gridSpacing, 0f),
                        end = Offset(x * gridSpacing, canvasHeight),
                        strokeWidth = 1f
                    )
                }
                for (y in 0..(canvasHeight / gridSpacing).toInt()) {
                    drawLine(
                        color = Color(0xFFE2DDD7),
                        start = Offset(0f, y * gridSpacing),
                        end = Offset(canvasWidth, y * gridSpacing),
                        strokeWidth = 1f
                    )
                }

                // 2. Draw UM Campus perimeter guide circle (~1.5 km campus radius)
                val umCenterX = centerX + ((101.6538 - centerLng) * scale * 1.05f).toFloat()
                val umCenterY = centerY - ((3.1209 - centerLat) * scale).toFloat()
                drawCircle(
                    color = Color(0xFFF08F76).copy(alpha = 0.2f),
                    radius = (0.015f * scale),
                    center = Offset(umCenterX, umCenterY),
                    style = Stroke(
                        width = 2f,
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(15f, 15f))
                    )
                )

                // 3. Draw all predefined campus locations from locations.json
                CampusLocationProvider.allLocations.forEach { loc ->
                    val lat = loc.lat ?: return@forEach
                    val lng = loc.lng ?: return@forEach

                    val pxX = centerX + ((lng - centerLng) * scale * 1.05f).toFloat()
                    val pxY = centerY - ((lat - centerLat) * scale).toFloat()

                    // Only draw if within visible canvas bounds
                    if (pxX in -40f..(canvasWidth + 40f) && pxY in -40f..(canvasHeight + 40f)) {
                        val isSelected = (loc.lat == selectedLat && loc.lng == selectedLng)
                        val markerColor = when {
                            isSelected -> Color(0xFF8A3524) // Deep Accent
                            loc.id.startsWith("kk") -> Color(0xFF2E7D32) // Residential College Green
                            loc.category.contains("Faculties", ignoreCase = true) -> Color(0xFF1976D2) // Faculty Blue
                            loc.category.contains("Off-Campus", ignoreCase = true) -> Color(0xFFF08F76) // Off-Campus Coral
                            loc.category.contains("Gates", ignoreCase = true) -> Color(0xFF7B1FA2) // Gates Purple
                            else -> Color(0xFFE65100) // Transit / Landmark
                        }

                        // Outer ring for selected pin
                        if (isSelected) {
                            drawCircle(
                                color = markerColor.copy(alpha = 0.35f),
                                radius = 22f,
                                center = Offset(pxX, pxY)
                            )
                        }

                        // Landmark Pin Circle
                        drawCircle(
                            color = markerColor,
                            radius = if (isSelected) 12f else 7f,
                            center = Offset(pxX, pxY)
                        )
                        drawCircle(
                            color = Color.White,
                            radius = if (isSelected) 5f else 3f,
                            center = Offset(pxX, pxY)
                        )
                    }
                }

                // 4. Draw Custom Dropped Pin if not matching an exact preset
                if (isCustomPin) {
                    val pinX = centerX + ((selectedLng - centerLng) * scale * 1.05f).toFloat()
                    val pinY = centerY - ((selectedLat - centerLat) * scale).toFloat()

                    drawCircle(
                        color = Color(0xFFD32F2F).copy(alpha = 0.3f),
                        radius = 24f,
                        center = Offset(pinX, pinY)
                    )
                    drawCircle(
                        color = Color(0xFFD32F2F),
                        radius = 14f,
                        center = Offset(pinX, pinY)
                    )
                    drawCircle(
                        color = Color.White,
                        radius = 6f,
                        center = Offset(pinX, pinY)
                    )
                }
            }

            // Map Controls (Zoom In, Zoom Out, Recenter)
            Column(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                SmallFloatingActionButton(
                    onClick = { scale = (scale * 1.25f).coerceAtMost(100000f) },
                    containerColor = Color.White
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Zoom In")
                }

                SmallFloatingActionButton(
                    onClick = { scale = (scale * 0.8f).coerceAtLeast(15000f) },
                    containerColor = Color.White
                ) {
                    Text("-", fontSize = 24.sp, fontWeight = FontWeight.Bold)
                }

                SmallFloatingActionButton(
                    onClick = {
                        centerLat = UM_CENTER_LAT
                        centerLng = UM_CENTER_LNG
                        scale = DEFAULT_SCALE
                    },
                    containerColor = Color(0xFFFDE3D7)
                ) {
                    Icon(Icons.Default.Home, contentDescription = "Recenter on UM Campus")
                }
            }

            // Bottom Confirmation Card
            Card(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .padding(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFFDE3D7)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.Place,
                                contentDescription = null,
                                tint = Color(0xFF8A3524)
                            )
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = selectedName,
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "$selectedCategory • ${String.format("%.4f", selectedLat)}, ${String.format("%.4f", selectedLng)}",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color(0xFF6B5C57)
                            )
                        }
                    }

                    if (isCustomPin && nearestLandmark != null && distanceToNearestKm != null) {
                        Spacer(modifier = Modifier.height(6.dp))
                        val distanceMeters = (distanceToNearestKm * 1000).roundToInt()
                        Text(
                            text = "📍 ~$distanceMeters m from ${nearestLandmark.name}",
                            style = MaterialTheme.typography.labelSmall,
                            color = Color(0xFF2E7D32)
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = {
                            val locationId = if (isCustomPin) {
                                "custom_${System.currentTimeMillis()}"
                            } else {
                                CampusLocationProvider.allLocations.firstOrNull {
                                    it.lat == selectedLat && it.lng == selectedLng
                                }?.id ?: "custom_pin"
                            }

                            val confirmedLocation = CampusLocation(
                                id = locationId,
                                name = selectedName,
                                category = selectedCategory,
                                lat = selectedLat,
                                lng = selectedLng,
                                pickupName = selectedName,
                                pickupLat = selectedLat,
                                pickupLng = selectedLng
                            )
                            onLocationConfirmed(confirmedLocation)
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF08F76)),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(Icons.Default.Check, contentDescription = null, tint = Color.White)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Confirm Location", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

/**
 * Dialog wrapper for MapPickerScreen for seamless modal invocation.
 */
@Composable
fun MapPickerDialog(
    initialLocation: CampusLocation? = null,
    onLocationConfirmed: (CampusLocation) -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(modifier = Modifier.fillMaxSize()) {
            MapPickerScreen(
                initialLocation = initialLocation,
                onLocationConfirmed = { loc ->
                    onLocationConfirmed(loc)
                    onDismiss()
                },
                onDismiss = onDismiss
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
fun MapPickerScreenPreview() {
    UMPoolingTheme {
        MapPickerScreen(
            onLocationConfirmed = {},
            onDismiss = {}
        )
    }
}
