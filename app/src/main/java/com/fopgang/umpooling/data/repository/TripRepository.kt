package com.fopgang.umpooling.data.repository

import com.fopgang.umpooling.SupabaseClientProvider
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Trip lifecycle. Each call is a database function that checks who is calling,
 * so the app cannot skip a step (see supabase/migrations/20261115000007_trip_lifecycle.sql).
 */
class TripRepository {

    /** Driver starts the trip for an offer. Returns the new trip id. */
    suspend fun startTrip(tripOfferId: String): Result<String> = suspendRunCatching {
        SupabaseClientProvider.client.postgrest.rpc(
            "start_trip",
            buildJsonObject { put("p_trip_offer_id", tripOfferId) }
        ).decodeAs<String>()
    }

    /** A passenger confirms the trip ended. */
    suspend fun confirmTripEnd(tripId: String): Result<Unit> = suspendRunCatching {
        SupabaseClientProvider.client.postgrest.rpc(
            "confirm_trip_end",
            buildJsonObject { put("p_trip_id", tripId) }
        )
        Unit
    }

    /** Driver completes the trip. Needs one confirmed passenger. Returns the passenger count. */
    suspend fun completeTrip(tripId: String): Result<Int> = suspendRunCatching {
        SupabaseClientProvider.client.postgrest.rpc(
            "complete_trip",
            buildJsonObject { put("p_trip_id", tripId) }
        ).decodeAs<Int>()
    }

    /** Driver cancels a trip that is in progress. */
    suspend fun cancelTrip(tripId: String): Result<Unit> = suspendRunCatching {
        SupabaseClientProvider.client.postgrest.rpc(
            "cancel_trip",
            buildJsonObject { put("p_trip_id", tripId) }
        )
        Unit
    }
}
