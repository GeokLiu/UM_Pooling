package com.fopgang.umpooling.data

/** Builds the EWKT text PostgREST accepts for PostGIS geography columns. */
object GeoPoint {
    fun ewkt(lng: Double, lat: Double): String {
        require(lng in -180.0..180.0 && lat in -90.0..90.0) { "Invalid coordinates" }
        return "SRID=4326;POINT($lng $lat)"
    }
}
