import Foundation

struct UserDefaultsProvider : ProviderProtocol {
    
    let userDefaults: UserDefaults
    let key: String
    
    init(userDefaults: UserDefaults, key: String) {
        self.userDefaults = userDefaults
        self.key = key
    }
    
    func get() -> [String: Any]? {
        return userDefaults.dictionary(forKey: key)
    }
    
    func set(_ dictionary: [String: Any]) throws {
        userDefaults.set(dictionary, forKey: key)
    }
    
    var provider: Provider<[String : Any]?, [String : Any]> {
        return Provider(get: self.get, set: self.set)
    }
    
}

func here() {
    let provider = UserDefaultsProvider(userDefaults: .standard, key: "some-shit-key")
        .provider
        .mapOutput({ $0 ?? [:] })
}
