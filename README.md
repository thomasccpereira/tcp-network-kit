# tcp-network-kit

A lightweight Swift networking layer built with protocol-oriented design and Clean Architecture principles. Supports async/await, response caching with TTL, download progress tracking, XML envelope requests, and structured error handling. Fully testable via dependency injection.

## Requirements

- iOS 18.0+
- Swift 6.1+

## Dependencies

- [tcp-core-resources](https://github.com/thomasccpereira/tcp-core-resources)

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/thomasccpereira/tcp-network-kit", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and enter the repository URL.

---

## Usage

### Basic fetch

Implement `NetworkRequestConfig` to describe your request:

```swift
struct GetUserRequest: NetworkRequestConfig {
    var host: String { "api.example.com" }
    var path: String { "/users/me" }
}
```

Then use `NetworkFactory` to execute it:

```swift
let factory = NetworkFactory()
let user: User = try await factory.fetch(requestConfig: GetUserRequest())
```

### Fetch with custom cache TTL

```swift
let user: User = try await factory.fetch(
    requestConfig: GetUserRequest(),
    cacheTTL: .seconds(60)
)
```

### Download data with progress

```swift
let progress = NetworkProgress()
let data = try await factory.downloadData(
    requestConfig: DownloadFileRequest(),
    progress: progress
)
```

---

## NetworkRequestConfig

A protocol that describes an HTTP request. All properties have sensible defaults:

```swift
public protocol NetworkRequestConfig: Sendable {
    var host: String { get }
    var path: String { get }
    var method: HTTPMethod { get }          // default: .get
    var headers: HTTPHeaders? { get }       // default: application/json
    var queryItems: [URLQueryItem]? { get } // default: nil
    var body: HTTPBody? { get }             // default: nil
    var xmlEnvelope: NetworkRequestXMLEnvelope? { get } // default: nil
}
```

---

## Dependency Injection

`NetworkFactory` accepts a `NetworkDependencies` struct, making every layer replaceable for testing or customization:

```swift
let dependencies = NetworkDependencies(
    sessionManager: CustomSessionManager(),
    requestBuilder: CustomRequestBuilder(),
    cacher: CustomCache(),
    logger: CustomLogger(),
    errorMapper: CustomErrorMapper(),
    validator: CustomValidator(),
    decoder: CustomDecoder()
)

let factory = NetworkFactory(dependencies: dependencies)
```

All dependencies have production-ready defaults and are defined as protocols:

| Protocol | Default implementation |
|---|---|
| `NetworkSessionManaging` | `DefaultSessionManager` |
| `NetworkRequestBuilding` | `DefaultRequestBuilder` |
| `NetworkResponseCaching` | `DefaultNetworkResponseCache` |
| `NetworkLogging` | `DefaultNetworkLogger` |
| `NetworkErrorMapping` | `DefaultErrorMapper` |
| `NetworkResponseValidating` | `StatusCodeValidator` |
| `NetworkResponseDecoding` | `JSONResponseDecoder` |

---

## Caching

`DefaultNetworkResponseCache` wraps `URLCache` and adds TTL support via `userInfo`:

- Cache is automatically checked before every request
- On a cache hit, the response is decoded and returned immediately
- On a decode failure, the cache entry is invalidated and the request is retried
- Pass `cacheTTL: .zero` to skip caching entirely

---

## Error Handling

All errors are mapped to `NetworkError`, a typed enum that covers the full request lifecycle:

```swift
do {
    let user: User = try await factory.fetch(requestConfig: GetUserRequest())
} catch let error as NetworkError {
    switch error {
    case .noInternetConnection:                     // handle offline
    case .timedOut:                                 // handle timeout
    case .networkClientFailure(let code, let url):  // 4xx
    case .networkServerFailure(let code, let url):  // 5xx
    case .decodingTypeMismatchFailure(let message): // decoding issue
    default: break
    }
}
```

Full list of cases:

| Category | Cases |
|---|---|
| Generic | `genericError`, `noInternetConnection`, `cancelled`, `timedOut` |
| Request | `networkBadRequest`, `networkRequestBuildFailure` |
| Client | `networkClientFailure(code:url:)` |
| Server | `networkServerFailure(code:url:)`, `networkServerStatusError(message:)`, `networkUnknownStatusCode(code:url:)` |
| Response | `networkInvalidResponse`, `networkInvalidStatusCode(code:url:)` |
| Decoding | `decodingGenericError`, `decodingKeyNotFoundFailure`, `decodingValueNotFoundFailure`, `decodingTypeMismatchFailure` |

---

## Architecture

```
NetworkFactoring (protocol)
└── NetworkFactory (concrete)
    └── NetworkDependencies
        ├── NetworkSessionManaging    → URLSession management
        ├── NetworkRequestBuilding    → URLRequest construction
        ├── NetworkResponseCaching    → TTL-based URLCache wrapper
        ├── NetworkLogging            → Request/response logging
        ├── NetworkErrorMapping       → Error normalization
        ├── NetworkResponseValidating → HTTP status code validation
        └── NetworkResponseDecoding   → JSON decoding
```

`NetworkExecuting` is an internal protocol responsible for the raw `URLSession.data(for:)` call, isolated from the factory logic and injected per request.

---

## License

MIT
