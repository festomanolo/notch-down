//
//  UpdateChecker.swift
//  NotchDown
//
//  Looks up the newest GitHub release and compares it with the running build.
//

import Foundation

enum UpdateChecker {

    struct Release {
        let version: String
        let pageURL: URL
    }

    enum Outcome {
        case upToDate(current: String)
        case available(Release)
        case failed(String)
    }

    private static let latestReleaseURL = URL(string: "https://api.github.com/repos/festomanolo/notch-down/releases/latest")!

    /// The running app's marketing version, e.g. "1.2.0".
    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static func check() async -> Outcome {
        var request = URLRequest(url: latestReleaseURL, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .failed("GitHub didn't return a release")
            }

            struct Payload: Decodable {
                let tag_name: String
                let html_url: URL
            }
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            let latest = normalized(payload.tag_name)

            if isVersion(latest, newerThan: currentVersion) {
                return .available(Release(version: latest, pageURL: payload.html_url))
            }
            return .upToDate(current: currentVersion)
        } catch {
            return .failed("Couldn't reach GitHub")
        }
    }

    /// Tags in this repo are written both as "v1.0" and "1.1.0".
    private static func normalized(_ tag: String) -> String {
        tag.hasPrefix("v") || tag.hasPrefix("V") ? String(tag.dropFirst()) : tag
    }

    /// Numeric, component-wise comparison, so "1.10" is newer than "1.9" and
    /// "1.2" equals "1.2.0".
    static func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let a = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let b = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
