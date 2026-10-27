import Foundation
import Combine

@MainActor
final class ServiceStore: ObservableObject {
    @Published var services: [ServiceEndpoint] = [] {
        didSet { persist() }
    }

    private let defaultsKey = "localbridge.services.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode([ServiceEndpoint].self, from: data) {
            services = saved
        }
    }

    func add(_ service: ServiceEndpoint) throws {
        try service.validate()
        services.append(service)
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { services.remove(at: index) }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(services) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
