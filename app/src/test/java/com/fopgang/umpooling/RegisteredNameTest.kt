package com.fopgang.umpooling

import com.fopgang.umpooling.data.repository.resolvedDisplayName
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class RegisteredNameTest {
    @Test fun registrationNameIsUsedWhenProfileHasNoName() {
        assertEquals("Liu", resolvedDisplayName(null, " Liu "))
        assertEquals("Liu", resolvedDisplayName(" ", "Liu"))
    }
    @Test fun editedProfileNameTakesPrecedence() {
        assertEquals("Geok Liu", resolvedDisplayName("Geok Liu", "Liu"))
    }
    @Test fun missingNameDoesNotInventAnotherIdentity() {
        assertNull(resolvedDisplayName(null, null))
        assertNull(resolvedDisplayName(" ", " "))
    }
}
