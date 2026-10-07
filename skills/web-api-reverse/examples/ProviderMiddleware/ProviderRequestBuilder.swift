import Foundation

public enum ExampleRoutePolicy: Equatable, Sendable {
  case fixed(baseURL: String)
  case sessionEnvironment(path: String)
  case unknown
}

public enum ExampleAuthPolicy: Equatable, Sendable {
  case none
  case bearerAccessToken
  case accessAndRefreshToken
  case sessionHeadersAndCookies
  case refreshTokenOnly
  case unknown
}

public struct ExampleProviderSession: Sendable {
  public let environment: String
  public let accessToken: String
  public let cookies: [String: String]

  public init(
    environment: String,
    accessToken: String,
    cookies: [String: String]
  ) {
    self.environment = environment
    self.accessToken = accessToken
    self.cookies = cookies
  }
}

public struct ExampleOperationPolicy: Equatable, Sendable {
  public let clientPath: String
  public let wirePath: String
  public let encodedQueryBodyNames: [String]
  public let responseContentTypeAliases: [String: String]

  public init(
    clientPath: String,
    wirePath: String,
    encodedQueryBodyNames: [String] = [],
    responseContentTypeAliases: [String: String] = [:]
  ) {
    self.clientPath = clientPath
    self.wirePath = wirePath
    self.encodedQueryBodyNames = encodedQueryBodyNames
    self.responseContentTypeAliases = responseContentTypeAliases
  }
}

public enum ExampleProviderError: Error, Equatable {
  case missingSession
  case unsupportedEnvironment(String)
  case invalidURL
  case generatedPathMismatch
  case invalidWireTransform
}

public struct ExampleProviderRequestBuilder: Sendable {
  public typealias EnvironmentResolver = @Sendable (String) -> URL?

  private let resolveEnvironment: EnvironmentResolver

  public init(resolveEnvironment: @escaping EnvironmentResolver) {
    self.resolveEnvironment = resolveEnvironment
  }

  public func request(
    method: String,
    routePolicy: ExampleRoutePolicy,
    authPolicy: ExampleAuthPolicy,
    session: ExampleProviderSession?
  ) throws -> URLRequest {
    let url: URL
    switch routePolicy {
    case .fixed(let baseURL):
      guard let resolved = URL(string: baseURL) else {
        throw ExampleProviderError.invalidURL
      }
      url = resolved
    case .sessionEnvironment(let path):
      guard let session else {
        throw ExampleProviderError.missingSession
      }
      guard let baseURL = resolveEnvironment(session.environment),
        let resolved = URL(string: path, relativeTo: baseURL)?.absoluteURL
      else {
        throw ExampleProviderError.unsupportedEnvironment(session.environment)
      }
      url = resolved
    case .unknown:
      throw ExampleProviderError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    switch authPolicy {
    case .none:
      break
    case .bearerAccessToken, .sessionHeadersAndCookies:
      guard let session else {
        throw ExampleProviderError.missingSession
      }
      request.setValue(
        "Bearer \(session.accessToken)",
        forHTTPHeaderField: "Authorization"
      )
      if authPolicy == .sessionHeadersAndCookies {
        request.setValue(
          session.cookies
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "; "),
          forHTTPHeaderField: "Cookie"
        )
      }
    case .accessAndRefreshToken, .refreshTokenOnly, .unknown:
      throw ExampleProviderError.invalidURL
    }
    return request
  }

  public func applyingWirePolicy(
    to generatedRequest: URLRequest,
    policy: ExampleOperationPolicy
  ) throws -> URLRequest {
    guard
      let generatedURL = generatedRequest.url,
      generatedURL.path == policy.clientPath,
      var components = URLComponents(
        url: generatedURL,
        resolvingAgainstBaseURL: false
      )
    else {
      throw ExampleProviderError.generatedPathMismatch
    }
    components.path = policy.wirePath
    var request = generatedRequest
    if !policy.encodedQueryBodyNames.isEmpty {
      guard
        policy.encodedQueryBodyNames.count == 1,
        let body = generatedRequest.httpBody,
        (try? JSONSerialization.jsonObject(with: body)) != nil,
        let value = String(data: body, encoding: .utf8)
      else {
        throw ExampleProviderError.invalidWireTransform
      }
      var query = components.queryItems ?? []
      query.append(
        URLQueryItem(
          name: policy.encodedQueryBodyNames[0],
          value: value
        )
      )
      components.queryItems = query
      request.httpBody = nil
      request.setValue(nil, forHTTPHeaderField: "Content-Length")
      request.setValue(nil, forHTTPHeaderField: "Content-Type")
    }
    guard let wireURL = components.url else {
      throw ExampleProviderError.invalidURL
    }
    request.url = wireURL
    return request
  }

  public func canonicalResponseContentType(
    _ wireContentType: String,
    policy: ExampleOperationPolicy
  ) -> String {
    let mediaType =
      wireContentType
      .split(separator: ";", maxSplits: 1)
      .first?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased() ?? wireContentType.lowercased()
    return policy.responseContentTypeAliases[mediaType] ?? mediaType
  }
}
