import CoreData
import Foundation

final class CoreDataStack {
    let container: NSPersistentContainer

    private var isLoaded = false
    private var loadError: Error?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SharePlateDataModel")

        guard let description = container.persistentStoreDescriptions.first else {
            loadError = CoreDataSharePlateRepositoryError.persistentStoreUnavailable
            return
        }

        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        if inMemory {
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func load() async throws {
        if isLoaded { return }
        if let loadError { throw loadError }

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { [weak self] _, error in
                guard let self else {
                    continuation.resume(
                        throwing: CoreDataSharePlateRepositoryError.persistentStoreUnavailable
                    )
                    return
                }

                if let error {
                    let repositoryError = CoreDataSharePlateRepositoryError
                        .persistentStoreLoadFailed(reason: error.localizedDescription)
                    self.loadError = repositoryError
                    continuation.resume(throwing: repositoryError)
                } else {
                    self.isLoaded = true
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
