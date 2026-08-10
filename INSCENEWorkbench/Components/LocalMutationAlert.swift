import SwiftUI

private struct LocalMutationAlertModifier: ViewModifier {
    @Binding var failure: LocalMutationFailure?
    let language: AppLanguage

    func body(content: Content) -> some View {
        content.alert(
            language == .zhHans ? "无法保存" : "Could Not Save",
            isPresented: Binding(
                get: { failure != nil },
                set: { if !$0 { failure = nil } }
            )
        ) {
            Button(language == .zhHans ? "好" : "OK") { failure = nil }
        } message: {
            if let failure {
                Text(failure.message.resolved(for: language))
            }
        }
    }
}

extension View {
    func localMutationAlert(
        failure: Binding<LocalMutationFailure?>,
        language: AppLanguage
    ) -> some View {
        modifier(LocalMutationAlertModifier(failure: failure, language: language))
    }
}
