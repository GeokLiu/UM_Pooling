package com.fopgang.umpooling

import com.fopgang.umpooling.data.UmEmail
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UmEmailTest {
    @Test
    fun acceptsStudentAndStaffDomains() {
        assertTrue(UmEmail.isValid("25005876@siswa.um.edu.my"))
        assertTrue(UmEmail.isValid("lecturer@um.edu.my"))
    }

    @Test
    fun ignoresCaseAndSurroundingSpaces() {
        assertTrue(UmEmail.isValid("  A@SISWA.UM.EDU.MY "))
        assertEquals("a@siswa.um.edu.my", UmEmail.normalize("  A@SISWA.UM.EDU.MY "))
    }

    @Test
    fun rejectsLookAlikeDomains() {
        assertFalse(UmEmail.isValid("x@um.edu.my.evil.com"))
        assertFalse(UmEmail.isValid("x@evil-um.edu.my"))
        assertFalse(UmEmail.isValid("x@mail.um.edu.my"))
        assertFalse(UmEmail.isValid("x@gmail.com"))
    }

    @Test
    fun rejectsMalformedAddresses() {
        assertFalse(UmEmail.isValid(""))
        assertFalse(UmEmail.isValid("@um.edu.my"))
        assertFalse(UmEmail.isValid("um.edu.my"))
        assertFalse(UmEmail.isValid("a@b@um.edu.my"))
        assertFalse(UmEmail.isValid("a b@um.edu.my"))
    }
}
