import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            Text(termsText)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.primary)
                .padding()
        }
        .navigationTitle("Terms & Conditions")
    }

    private var termsText: String {
        """
        Inner World Terms & Conditions

        Purpose
        Inner World is a self-reflection and wellbeing application designed to promote greater self-understanding. It is NOT a medical, clinical, or professional therapy service.

        No Medical or Crisis Advice
        Content in the app is for informational and educational purposes only. It does not constitute medical, psychological, or crisis advice. If you are in crisis or may harm yourself or others, call your local emergency number or a crisis hotline immediately.

        No Provider-Client Relationship
        Using the app does not create a therapist–client, doctor–patient, or any other professional relationship.

        Eligibility
        You must be at least 13 years of age to use the app. If you are under the age of majority in your jurisdiction, you must have permission from a parent or legal guardian.

        Data and Privacy
        We take reasonable measures to protect your information, but no system is completely secure. By using the app, you consent to our data practices as described in our Privacy Policy.

        Limitation of Liability
        To the maximum extent permitted by law, Inner World and its affiliates are not liable for any indirect, incidental, special, consequential, or exemplary damages, including but not limited to decisions you make based on content in the app.

        Changes
        We may update these Terms from time to time. Continued use of the app constitutes acceptance of the updated Terms.
        """
    }
}