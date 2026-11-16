package com.fopgang.umpooling

import com.fopgang.umpooling.data.GeoPoint
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class GeoPointTest {
    @Test
    fun longitudeComesFirst() {
        assertEquals("SRID=4326;POINT(101.6569 3.1209)", GeoPoint.ewkt(101.6569, 3.1209))
    }

    @Test
    fun rejectsOutOfRangeCoordinates() {
        assertThrows(IllegalArgumentException::class.java) { GeoPoint.ewkt(200.0, 3.0) }
        assertThrows(IllegalArgumentException::class.java) { GeoPoint.ewkt(101.0, 91.0) }
    }
}
