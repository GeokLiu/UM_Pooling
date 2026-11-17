# UMPooling — Assumptions and Validation Log

**Project:** UMPooling — A Campus Carpooling Application for Sustainable Commuting  
**Course:** WIA2007 Mobile Application Development  
**Phase:** 1 — Validation  
**Last Updated:** 17 November 2026  
**Responsible Member:** Member 6 — Developer and Tester

## 1. Purpose

This document records the assumptions underlying the proposed UMPooling application, particularly those relating to user demand, commuting behaviour, safety, privacy and regulatory considerations.

These assumptions will be evaluated through survey analysis, stakeholder feedback, further research and prototype testing. They should not be treated as confirmed requirements until sufficient supporting evidence is obtained.

## 2. Survey Validation

A Google Forms questionnaire was conducted to understand the commuting habits, difficulties, preferences and carpooling interests of the Universiti Malaya (UM) community.

| Item | Details |
|---|---|
| Survey method | Google Forms questionnaire |
| Target respondents | UM students, lecturers and staff |
| Responses collected | 30 |
| Survey evidence | `evidence/survey-raw.csv` |
| Validation status | Data collection completed; analysis pending |

The survey explores existing commuting difficulties, willingness to participate in carpooling, safety concerns, preferred application features and environmental awareness.

**Limitation:** The survey uses a relatively small, non-random sample. Its findings provide preliminary indications of user preferences but cannot necessarily be generalised to the entire UM population.

## 3. User and Functional Assumptions

| ID | Assumption | Proposed Validation | Status |
|---|---|---|---|
| A01 | UM students and staff experience commuting difficulties that could be addressed through carpooling. | Analyse commuting struggles, travel costs and transport reliability. | Pending analysis |
| A02 | There is sufficient interest among UM users to justify developing a campus carpooling application. | Analyse willingness to use UMPooling and intended driver/passenger roles. | Pending analysis |
| A03 | UM email verification can provide a practical method of restricting access to the university community. | Verify UM account eligibility and test the proposed authentication process. | To verify |
| A04 | Users are willing to contribute towards reasonable fuel-sharing costs. | Analyse survey responses concerning acceptable fuel contributions. | Pending analysis |
| A05 | Ride matching based on location, destination and travel time can improve commuting convenience. | Validate user preferences and conduct prototype usability testing. | To verify |
| A06 | Safety features, including SOS, trip history and user ratings, may increase users' confidence in carpooling. | Analyse feature ratings and safety concerns; conduct usability testing. | Pending analysis |
| A07 | Displaying estimated CO₂ savings may encourage greater awareness of sustainable commuting. | Analyse environmental awareness and CO₂-related survey responses. | Pending analysis |

## 4. Privacy and PDPA Assumptions

UMPooling may process personal information, including university email addresses, user profiles, trip details, location information and emergency contact details.

The following assumptions require further verification:

| ID | Assumption / Issue to Verify | Proposed Approach |
|---|---|---|
| P01 | The applicability of Malaysia's Personal Data Protection Act 2010 (PDPA) depends on the nature and context of the application's data processing activities. | Research the applicable statutory requirements and official guidance. |
| P02 | Only personal information necessary for application functionality and safety should be collected. | Apply data minimisation during registration and trip management. |
| P03 | Users should receive clear information about how their personal data is collected, used, disclosed and retained. | Prepare an appropriate privacy notice. |
| P04 | Location information should only be accessed and disclosed when necessary for authorised application functions. | Implement permission controls and restrict location visibility. |
| P05 | Trip records and personal information should not be retained indefinitely without justification. | Establish and document an appropriate retention policy. |
| P06 | Unauthorised users should not be able to access another user's restricted information. | Implement authentication, database access controls and security testing. |

**Preliminary position:** The application should adopt privacy-by-design principles, including data minimisation, access restrictions and appropriate retention periods. Specific legal obligations remain subject to verification.

## 5. Safety and Regulatory Assumptions

As UMPooling facilitates shared journeys between members of the university community, the following safety and regulatory considerations should be investigated before implementation.

| ID | Assumption / Issue to Verify | Proposed Validation |
|---|---|---|
| S01 | UM-only account verification may reduce the risk of unauthorised participation but does not independently establish user trustworthiness. | Test account verification and assess additional safeguards. |
| S02 | An SOS function using SMS or WhatsApp can provide a convenient way to notify emergency contacts. | Test message generation, location sharing and failure scenarios. |
| S03 | Trip history may support incident reporting and accountability. | Define necessary trip-record fields and appropriate retention periods. |
| S04 | Driver/passenger ratings may help users assess previous ride-sharing experiences. | Test rating functionality and consider misuse or unfair ratings. |
| S05 | Cost-sharing arrangements may be subject to transport, licensing or insurance requirements. | Research relevant Malaysian requirements and verify whether the proposed arrangement is permissible. |
| S06 | Users should understand the limitations of the application's safety functions. | Provide appropriate notices and test emergency scenarios. |

**Important considerations:**

- An SOS message does not guarantee delivery, emergency response or assistance.
- University email verification does not guarantee that a user is safe or reliable.
- The legality of fuel-cost sharing, driver eligibility and applicable insurance coverage must be verified rather than assumed.
- Trip and location information should only be accessible to appropriately authorised users.

## 6. Environmental Impact Assumptions

UMPooling proposes to promote SDG 13.3 through climate awareness and estimated carbon-emission savings.

The environmental impact calculation will require further validation because the actual savings depend on factors such as:

- Journey distance and vehicle type.
- Number of passengers sharing a ride.
- Whether passengers would otherwise have travelled separately by private car, public transport or other means.
- Additional travel distance caused by passenger pickups or detours.
- Appropriate emission factors and calculation methodology.

The application should present CO₂ savings as **estimates based on stated assumptions**, rather than verified reductions in actual emissions.

## 7. Outstanding Validation Tasks

- [ ] Complete descriptive analysis of the 30 survey responses.
- [ ] Identify the most significant commuting problems and user preferences.
- [ ] Determine the highest-priority UMPooling features.
- [ ] Review relevant PDPA provisions and official guidance.
- [ ] Investigate transport, insurance and cost-sharing considerations.
- [ ] Validate proposed SOS functionality and safety limitations.
- [ ] Establish preliminary data access and retention requirements.
- [ ] Review the assumptions with the development team.
- [ ] Update assumption statuses based on research and prototype testing.

## 8. Conclusion

The initial survey provides a basis for evaluating the proposed UMPooling application. However, user preferences, technical feasibility, privacy obligations, safety arrangements and environmental impact calculations require further validation.

These assumptions will be reviewed and refined throughout the requirements, development and testing phases to ensure that UMPooling addresses genuine user needs while incorporating appropriate safety, privacy and sustainability considerations.
