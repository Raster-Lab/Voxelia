// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaStorage

@Suite("StorageTaxonomy")
struct StorageTaxonomyTests {
    @Test("[Unit][VOX-STO-002][VOX-API-003] exposes exact storage kinds")
    func exposesExactStorageKinds() {
        let expected: [(kind: StorageKind, rawValue: String)] = [
            (.contiguous, "contiguous"),
            (.memoryMapped, "memoryMapped"),
            (.tiled, "tiled"),
            (.bricked, "bricked"),
            (.compressed, "compressed"),
            (.remote, "remote"),
            (.callback, "callback"),
            (.view, "view"),
        ]

        for value in expected {
            #expect(value.kind.rawValue == value.rawValue)
            #expect(StorageKind(rawValue: value.rawValue) == value.kind)
        }
        #expect(StorageKind(rawValue: "memorymapped") == nil)
        #expect(StorageKind(rawValue: "unknown") == nil)
    }

    @Test("[Unit][VOX-STO-002][VOX-API-003] exposes exact persistence kinds")
    func exposesExactPersistenceKinds() {
        let expected: [(persistence: StoragePersistence, rawValue: String)] = [
            (.transient, "transient"),
            (.processLifetime, "processLifetime"),
            (.mappedFile, "mappedFile"),
            (.persistentCache, "persistentCache"),
            (.external, "external"),
        ]

        for value in expected {
            #expect(value.persistence.rawValue == value.rawValue)
            #expect(StoragePersistence(rawValue: value.rawValue) == value.persistence)
        }
        #expect(StoragePersistence(rawValue: "processlifetime") == nil)
        #expect(StoragePersistence(rawValue: "unknown") == nil)
    }

    @Test("[Unit][VOX-API-004] Codable uses exact raw strings")
    func codableUsesExactRawStrings() throws {
        let kinds: [StorageKind] = [
            .contiguous,
            .memoryMapped,
            .tiled,
            .bricked,
            .compressed,
            .remote,
            .callback,
            .view,
        ]
        let persistenceValues: [StoragePersistence] = [
            .transient,
            .processLifetime,
            .mappedFile,
            .persistentCache,
            .external,
        ]

        for kind in kinds {
            let data = try JSONEncoder().encode(kind)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(kind.rawValue)""#)
            #expect(try JSONDecoder().decode(StorageKind.self, from: data) == kind)
        }
        for persistence in persistenceValues {
            let data = try JSONEncoder().encode(persistence)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(persistence.rawValue)""#)
            #expect(
                try JSONDecoder().decode(StoragePersistence.self, from: data)
                    == persistence
            )
        }
    }

    @Test("[Unit][VOX-API-004] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        for json in [#""unknown""#, "1", "true", "null", "{}", "[]"] {
            let data = Data(json.utf8)
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(StorageKind.self, from: data)
            }
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(StoragePersistence.self, from: data)
            }
        }
    }

    @Test("[Unit][VOX-API-003] taxonomies remain Sendable and distinct")
    func remainsSendableAndDistinct() {
        requireSendable(StorageKind.self)
        requireSendable(StoragePersistence.self)
        #expect(
            Set([
                StorageKind.contiguous,
                .memoryMapped,
                .tiled,
                .bricked,
                .compressed,
                .remote,
                .callback,
                .view,
            ]).count == 8
        )
        #expect(
            Set([
                StoragePersistence.transient,
                .processLifetime,
                .mappedFile,
                .persistentCache,
                .external,
            ]).count == 5
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
