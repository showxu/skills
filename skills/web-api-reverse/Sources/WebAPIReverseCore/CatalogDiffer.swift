import Foundation

public enum CatalogDiffer {
  public static func diff(
    from: ObservedCatalog,
    to: ObservedCatalog
  ) throws -> CatalogDiff {
    guard from.brand == to.brand, from.market == to.market else {
      throw EvidenceScopeError.mismatch(
        "\(from.brand)/\(from.market) vs \(to.brand)/\(to.market)"
      )
    }
    let fromById = Dictionary(
      uniqueKeysWithValues: from.operations.map { ($0.operationId, $0) }
    )
    let toById = Dictionary(
      uniqueKeysWithValues: to.operations.map { ($0.operationId, $0) }
    )
    let added = toById.keys.filter { fromById[$0] == nil }.sorted()
    let removed = fromById.keys.filter { toById[$0] == nil }.sorted()
    let shared = Set(fromById.keys).intersection(toById.keys)
    let changed = try shared.filter { operationId in
      guard let old = fromById[operationId], let new = toById[operationId] else {
        return true
      }
      return try DeterministicJSON.encode(old) != DeterministicJSON.encode(new)
    }.sorted()

    return CatalogDiff(
      schemaVersion: 1,
      kind: "web-api-reverse.catalog-diff",
      from: CatalogIdentity(
        brand: from.brand,
        market: from.market,
        updatedAt: from.updatedAt
      ),
      to: CatalogIdentity(
        brand: to.brand,
        market: to.market,
        updatedAt: to.updatedAt
      ),
      addedOperationIds: added,
      removedOperationIds: removed,
      changedOperationIds: changed,
      unchangedCount: shared.count - changed.count
    )
  }
}
