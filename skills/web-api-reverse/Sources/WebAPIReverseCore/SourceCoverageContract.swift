import Foundation

enum SourceCoverageContract {
  static let sourceProductVerificationAreas: Set<String> = [
    "selected-platform-current-facts",
    "selected-platform-identity",
  ]

  struct Source: Sendable {
    let key: String
    let policy: SourceCoveragePolicy
    let areas: [String]?
  }

  static func validate(
    requiredAreas: [String]?,
    sources: [Source]
  ) throws -> [String] {
    guard let requiredAreas, !requiredAreas.isEmpty else {
      throw CapturePipelineError.missingRequiredCoverageAreas
    }
    let required = try validateAreas(
      requiredAreas,
      scope: "requiredCoverageAreas"
    )
    var assigned: Set<String> = []
    for source in sources {
      let areas = try validateAreas(
        source.areas ?? [],
        scope: "source \(source.key)"
      )
      if source.policy == .required {
        guard !areas.isEmpty else {
          throw CapturePipelineError.missingSourceCoverageAreas(source.key)
        }
        assigned.formUnion(areas)
      }
    }
    for area in required where !assigned.contains(area) {
      throw CapturePipelineError.unassignedRequiredCoverageArea(area)
    }
    return required
  }

  static func validateAreas(
    _ areas: [String],
    scope: String
  ) throws -> [String] {
    var seen: Set<String> = []
    for area in areas {
      guard
        area.range(
          of: #"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$"#,
          options: .regularExpression
        ) != nil
      else {
        throw CapturePipelineError.invalidCoverageArea(area)
      }
      guard seen.insert(area).inserted else {
        throw CapturePipelineError.duplicateCoverageArea(
          scope: scope,
          area: area
        )
      }
    }
    return seen.sorted()
  }
}
