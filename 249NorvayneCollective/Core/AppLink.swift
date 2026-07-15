import Foundation

enum AppLink: String {
    case privacyPolicy = "https://norvaynecollective249.site/privacy/326"
    case termsOfUse = "https://norvaynecollective249.site/terms/326"

    var url: URL? {
        URL(string: rawValue)
    }
}
