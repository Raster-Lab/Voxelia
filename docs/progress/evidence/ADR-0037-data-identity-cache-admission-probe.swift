// SPDX-License-Identifier: MIT

// Isolated Swift 6 evidence for proposed ADR-0037. These Probe* declarations
// are deliberately not product API, a canonical encoder, a digest
// implementation, a trust store or an execution cache.

enum ProbeIdentityError: Error, Sendable, Equatable {
    case invalidText
    case textByteLimitExceeded
    case missingIdentityClaim
    case duplicateSourceLocator
    case conflictingContentClaim
    case unsupportedParameterProfile
    case undeclaredZeroInputGenerator
}

enum ProbePublicationError: Error, Sendable, Equatable {
    case cancelled
    case failed
    case mismatch
    case staleGeneration
    case snapshotChanged
    case alreadyPublished
}

protocol ProbeRedactedDiagnostic:
    CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable
{}

extension ProbeRedactedDiagnostic {
    var description: String { "<redacted-probe-identity>" }
    var debugDescription: String { "<redacted-probe-identity>" }

    var customMirror: Mirror {
        Mirror(
            self,
            children: EmptyCollection<(label: String?, value: Any)>()
        )
    }
}

struct ProbeExactText: Sendable, Hashable, ProbeRedactedDiagnostic {
    static let maximumUTF8ByteCount = 128

    let bytes: ContiguousArray<UInt8>

    init(_ value: String) throws {
        guard value.utf8.count <= Self.maximumUTF8ByteCount else {
            throw ProbeIdentityError.textByteLimitExceeded
        }
        guard !value.isEmpty, value.contains(where: { !$0.isWhitespace }) else {
            throw ProbeIdentityError.invalidText
        }
        bytes = ContiguousArray(value.utf8)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes.elementsEqual(rhs.bytes)
    }

    func hash(into hasher: inout Hasher) {
        for byte in bytes {
            hasher.combine(byte)
        }
    }
}

enum ProbeContentScope: Sendable, Hashable {
    case descriptorAndSamples
    case storageObject
    case serialisedObject
}

enum ProbeDigestAlgorithm: Sendable, Hashable {
    case sha256
    case sha512
}

enum ProbeProjection: Sendable, Hashable {
    case imageDescriptorAndSamplesV1
    case sourceStorageObjectV1
    case operationParametersV1
    case metadataCompleteRecordV1
}

/// `digestTag` is an opaque fixture discriminator, not a cryptographic digest.
struct ProbeContentClaim: Sendable, Hashable, ProbeRedactedDiagnostic {
    let algorithm: ProbeDigestAlgorithm
    let scope: ProbeContentScope
    let projection: ProbeProjection
    let digestTag: UInt64
}

struct ProbeSourceLocator: Sendable, Hashable, ProbeRedactedDiagnostic {
    let namespace: ProbeExactText
    let identifier: ProbeExactText
    let version: ProbeExactText?
}

struct ProbeSourceIdentity: Sendable, Hashable, ProbeRedactedDiagnostic {
    let locator: ProbeSourceLocator
    let contentClaim: ProbeContentClaim?
}

/// Mirrors the existing semantic/preference equality mismatch deliberately:
/// build metadata is preserved but ignored by ordinary semantic equality.
struct ProbeSemanticVersion: Sendable, Hashable, ProbeRedactedDiagnostic {
    let major: UInt32
    let minor: UInt32
    let patch: UInt32
    let prerelease: ProbeExactText?
    let buildMetadata: ProbeExactText?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.major == rhs.major
            && lhs.minor == rhs.minor
            && lhs.patch == rhs.patch
            && lhs.prerelease == rhs.prerelease
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
        hasher.combine(prerelease)
    }

    func isExactlyEqual(to other: Self) -> Bool {
        self == other && buildMetadata == other.buildMetadata
    }

    func hashExactFields(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
        hasher.combine(prerelease)
        hasher.combine(buildMetadata)
    }
}

struct ProbeObjectID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbeDerivationRecordID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

enum ProbeDataIdentityReference: Sendable, Hashable, ProbeRedactedDiagnostic {
    case object(ProbeObjectID)
    case content(ProbeContentClaim)
    case source(ProbeSourceIdentity)
    case derivation(ProbeDerivationRecordID)
}

enum ProbeOperationProfile: Sendable, Hashable {
    case transformationV1
    case zeroInputGeneratorV1

    var operationID: ProbeExactText {
        switch self {
        case .transformationV1:
            return makeText("org.voxelia.probe.operation")
        case .zeroInputGeneratorV1:
            return makeText("org.voxelia.probe.generator")
        }
    }

    var permitsZeroInputs: Bool {
        self == .zeroInputGeneratorV1
    }
}

struct ProbeDerivationIdentity: Sendable, Hashable, ProbeRedactedDiagnostic {
    let operationID: ProbeExactText
    let operationVersion: ProbeSemanticVersion
    let implementationID: ProbeExactText?
    let inputIdentities: ContiguousArray<ProbeDataIdentityReference>
    let parameterDigest: ProbeContentClaim

    init(
        operationProfile: ProbeOperationProfile,
        operationVersion: ProbeSemanticVersion,
        implementationID: ProbeExactText?,
        inputIdentities: some Collection<ProbeDataIdentityReference>,
        parameterDigest: ProbeContentClaim,
    ) throws {
        guard parameterDigest.algorithm == .sha256,
            parameterDigest.scope == .serialisedObject,
            parameterDigest.projection == .operationParametersV1
        else {
            throw ProbeIdentityError.unsupportedParameterProfile
        }
        guard !inputIdentities.isEmpty || operationProfile.permitsZeroInputs else {
            throw ProbeIdentityError.undeclaredZeroInputGenerator
        }

        self.operationID = operationProfile.operationID
        self.operationVersion = operationVersion
        self.implementationID = implementationID
        self.inputIdentities = ContiguousArray(inputIdentities)
        self.parameterDigest = parameterDigest
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.operationID == rhs.operationID
            && lhs.operationVersion.isExactlyEqual(to: rhs.operationVersion)
            && lhs.implementationID == rhs.implementationID
            && lhs.inputIdentities == rhs.inputIdentities
            && lhs.parameterDigest == rhs.parameterDigest
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(operationID)
        operationVersion.hashExactFields(into: &hasher)
        hasher.combine(implementationID)
        hasher.combine(inputIdentities)
        hasher.combine(parameterDigest)
    }
}

enum ProbeIdentityState: Sendable, Equatable {
    case sourceOnly
    case derivationOnly
    case mixedLineage
    case contentOnly
    case contentAndSource
    case contentAndDerivation
    case contentAndMixedLineage
}

struct ProbeDataIdentity: Sendable, Hashable, ProbeRedactedDiagnostic {
    let objectID: ProbeObjectID
    let contentClaim: ProbeContentClaim?
    let sourceIdentities: ContiguousArray<ProbeSourceIdentity>
    let derivation: ProbeDerivationIdentity?
    let state: ProbeIdentityState

    init(
        objectID: ProbeObjectID,
        contentClaim: ProbeContentClaim?,
        sourceIdentities: some Collection<ProbeSourceIdentity>,
        derivation: ProbeDerivationIdentity?
    ) throws {
        let sources = ContiguousArray(sourceIdentities)
        var seenLocators: Set<ProbeSourceLocator> = []
        for source in sources {
            guard seenLocators.insert(source.locator).inserted else {
                throw ProbeIdentityError.duplicateSourceLocator
            }
        }

        let hasContent = contentClaim != nil
        let hasSources = !sources.isEmpty
        let hasDerivation = derivation != nil

        let resolvedState: ProbeIdentityState
        switch (hasContent, hasSources, hasDerivation) {
        case (false, false, false):
            throw ProbeIdentityError.missingIdentityClaim
        case (false, true, false):
            resolvedState = .sourceOnly
        case (false, false, true):
            resolvedState = .derivationOnly
        case (false, true, true):
            resolvedState = .mixedLineage
        case (true, false, false):
            resolvedState = .contentOnly
        case (true, true, false):
            resolvedState = .contentAndSource
        case (true, false, true):
            resolvedState = .contentAndDerivation
        case (true, true, true):
            resolvedState = .contentAndMixedLineage
        }

        self.objectID = objectID
        self.contentClaim = contentClaim
        self.sourceIdentities = sources
        self.derivation = derivation
        self.state = resolvedState
    }

    func addingContentClaim(
        _ claim: ProbeContentClaim,
        resultingObjectID: ProbeObjectID
    ) throws -> Self {
        if let contentClaim, contentClaim != claim {
            throw ProbeIdentityError.conflictingContentClaim
        }
        return try Self(
            objectID: resultingObjectID,
            contentClaim: claim,
            sourceIdentities: sourceIdentities,
            derivation: derivation
        )
    }
}

struct ProbeTrustContext: Sendable, Hashable, ProbeRedactedDiagnostic {
    let tenant: ProbeExactText
    let privacyDomain: ProbeExactText
    let securityDomain: ProbeExactText
    let purpose: ProbeExactText
    let policyVersion: ProbeExactText
}

struct ProbeSourceAttestation: Sendable, Hashable, ProbeRedactedDiagnostic {
    let locator: ProbeSourceLocator
    let context: ProbeTrustContext
}

struct ProbeExecutionCacheKey: Sendable, Hashable, ProbeRedactedDiagnostic {
    let operationID: ProbeExactText
    let operationVersion: ProbeExactText
    let implementationVersion: ProbeExactText
    let canonicalParameterClaim: ProbeContentClaim
    let inputContentIdentities: ContiguousArray<ProbeContentClaim>
    let executionProfile: ProbeExactText
    let backendAndCapability: ProbeExactText
    let precisionPolicy: ProbeExactText
    let shaderOrKernelVersion: ProbeExactText
    let environmentVersion: ProbeExactText
    let trustContext: ProbeTrustContext
}

struct ProbeVerifiedContentEvidence: Sendable, Hashable, ProbeRedactedDiagnostic {
    let objectID: ProbeObjectID
    let claim: ProbeContentClaim
    let context: ProbeTrustContext
    let verifiedSnapshot: UInt64
}

struct ProbeBoundDerivationEvidence: Sendable, Hashable, ProbeRedactedDiagnostic {
    let recordID: ProbeDerivationRecordID
    let executionKey: ProbeExecutionCacheKey
}

struct ProbeAdmissionEvidence: Sendable, ProbeRedactedDiagnostic {
    let verifiedContent: Set<ProbeVerifiedContentEvidence>
    let sourceAttestations: Set<ProbeSourceAttestation>
    let deterministicDerivations: Set<ProbeBoundDerivationEvidence>
    let derivationsWithAdmissibleInputs: Set<ProbeBoundDerivationEvidence>
}

enum ProbeCacheAdmission: Sendable, Equatable, ProbeRedactedDiagnostic {
    case denied
    case verifiedContent(ProbeContentClaim, ProbeTrustContext)
    case trustedVersionedSource(ProbeSourceLocator, ProbeTrustContext)
    case deterministicDerivation(ProbeDerivationRecordID, ProbeExecutionCacheKey)
}

func admitPersistentCacheReference(
    _ reference: ProbeDataIdentityReference,
    evidence: ProbeAdmissionEvidence,
    context: ProbeTrustContext,
    verifiedContentObjectID: ProbeObjectID? = nil,
    verifiedContentSnapshot: UInt64? = nil,
    executionKey: ProbeExecutionCacheKey? = nil
) -> ProbeCacheAdmission {
    switch reference {
    case .object:
        return .denied
    case .content(let claim):
        guard let verifiedContentObjectID, let verifiedContentSnapshot else {
            return .denied
        }
        let hasBoundEvidence = evidence.verifiedContent.contains {
            $0.objectID == verifiedContentObjectID && $0.claim == claim
                && $0.context == context
                && $0.verifiedSnapshot == verifiedContentSnapshot
        }
        return hasBoundEvidence ? .verifiedContent(claim, context) : .denied
    case .source(let source):
        guard source.locator.version != nil else { return .denied }
        let attestation = ProbeSourceAttestation(locator: source.locator, context: context)
        return evidence.sourceAttestations.contains(attestation)
            ? .trustedVersionedSource(source.locator, context) : .denied
    case .derivation(let recordID):
        guard let executionKey,
            executionKey.trustContext == context
        else {
            return .denied
        }
        let boundEvidence = ProbeBoundDerivationEvidence(
            recordID: recordID,
            executionKey: executionKey
        )
        guard evidence.deterministicDerivations.contains(boundEvidence),
            evidence.derivationsWithAdmissibleInputs.contains(boundEvidence)
        else {
            return .denied
        }
        return .deterministicDerivation(recordID, executionKey)
    }
}

struct ProbePublishedContentEvidence:
    Sendable, Equatable, ProbeRedactedDiagnostic
{
    let objectID: ProbeObjectID
    let claim: ProbeContentClaim
    let generation: UInt64
    let snapshot: UInt64
    let context: ProbeTrustContext
}

struct ProbePublicationAuthorization: Sendable {
    let cacheAlias: Bool
    let provenanceSuccess: Bool

    static let identityOnly = Self(cacheAlias: false, provenanceSuccess: false)
    static let cacheAndProvenance = Self(cacheAlias: true, provenanceSuccess: true)
}

struct ProbePublishedState: Sendable, Equatable, ProbeRedactedDiagnostic {
    let identity: ProbeDataIdentity
    let assurance: ProbePublishedContentEvidence?
    let cacheAliasCount: UInt64
    let provenanceSuccessCount: UInt64
}

actor ProbeIdentityPublisher {
    private var published: ProbePublishedState
    private let currentGeneration: UInt64
    private let currentSnapshot: UInt64
    private let completionObjectID: ProbeObjectID
    private let trustContext: ProbeTrustContext
    private let publicationAuthorization: ProbePublicationAuthorization
    private var didPublishCompletion = false

    init(
        identity: ProbeDataIdentity,
        generation: UInt64,
        snapshot: UInt64,
        completionObjectID: ProbeObjectID,
        trustContext: ProbeTrustContext,
        publicationAuthorization: ProbePublicationAuthorization
    ) {
        published = ProbePublishedState(
            identity: identity,
            assurance: nil,
            cacheAliasCount: 0,
            provenanceSuccessCount: 0
        )
        currentGeneration = generation
        currentSnapshot = snapshot
        self.completionObjectID = completionObjectID
        self.trustContext = trustContext
        self.publicationAuthorization = publicationAuthorization
    }

    func finish(
        computed: ProbeContentClaim,
        expected: ProbeContentClaim?,
        generation: UInt64,
        pinnedSnapshot: UInt64,
        cancelled: Bool = false,
        failed: Bool = false
    ) throws {
        guard !didPublishCompletion else {
            throw ProbePublicationError.alreadyPublished
        }
        guard !cancelled else {
            throw ProbePublicationError.cancelled
        }
        guard !failed else {
            throw ProbePublicationError.failed
        }
        guard generation == currentGeneration else {
            throw ProbePublicationError.staleGeneration
        }
        guard pinnedSnapshot == currentSnapshot else {
            throw ProbePublicationError.snapshotChanged
        }
        if let existingClaim = published.identity.contentClaim,
            existingClaim != computed
        {
            throw ProbePublicationError.mismatch
        }
        if let expected,
            expected != computed
                || published.identity.contentClaim.map({ $0 != expected }) == true
        {
            throw ProbePublicationError.mismatch
        }

        let enrichedIdentity = try published.identity.addingContentClaim(
            computed,
            resultingObjectID: completionObjectID
        )
        published = ProbePublishedState(
            identity: enrichedIdentity,
            assurance: ProbePublishedContentEvidence(
                objectID: completionObjectID,
                claim: computed,
                generation: currentGeneration,
                snapshot: currentSnapshot,
                context: trustContext
            ),
            cacheAliasCount: published.cacheAliasCount
                + (publicationAuthorization.cacheAlias ? 1 : 0),
            provenanceSuccessCount: published.provenanceSuccessCount
                + (publicationAuthorization.provenanceSuccess ? 1 : 0)
        )
        didPublishCompletion = true
    }

    func snapshot() -> ProbePublishedState {
        published
    }
}

func require(_ condition: @autoclosure () -> Bool) {
    precondition(condition())
}

func requireThrows<T: Error & Equatable>(
    _ expected: T,
    _ body: () throws -> Void
) {
    do {
        try body()
        preconditionFailure("Expected a payload-free probe error.")
    } catch let error as T {
        precondition(error == expected)
    } catch {
        preconditionFailure("Unexpected probe error type.")
    }
}

func makeText(_ value: String) -> ProbeExactText {
    do {
        return try ProbeExactText(value)
    } catch {
        preconditionFailure("Invalid fixed probe fixture.")
    }
}

func makeDerivation(
    version: ProbeSemanticVersion,
    inputs: [ProbeDataIdentityReference],
    parameterDigest: ProbeContentClaim,
    operationProfile: ProbeOperationProfile = .transformationV1
) -> ProbeDerivationIdentity {
    do {
        return try ProbeDerivationIdentity(
            operationProfile: operationProfile,
            operationVersion: version,
            implementationID: makeText("reference"),
            inputIdentities: inputs,
            parameterDigest: parameterDigest
        )
    } catch {
        preconditionFailure("Invalid fixed derivation fixture.")
    }
}

func makeIdentity(
    objectID: ProbeObjectID,
    content: ProbeContentClaim?,
    sources: [ProbeSourceIdentity],
    derivation: ProbeDerivationIdentity?
) -> ProbeDataIdentity {
    do {
        return try ProbeDataIdentity(
            objectID: objectID,
            contentClaim: content,
            sourceIdentities: sources,
            derivation: derivation
        )
    } catch {
        preconditionFailure("Invalid fixed identity fixture.")
    }
}

@main
struct ADR0037Probe {
    static func main() async {
        let objectA = ProbeObjectID(value: makeText("object-a"))
        let objectB = ProbeObjectID(value: makeText("object-b"))
        let sourceContent = ProbeContentClaim(
            algorithm: .sha256,
            scope: .storageObject,
            projection: .sourceStorageObjectV1,
            digestTag: 10
        )
        let imageContent = ProbeContentClaim(
            algorithm: .sha256,
            scope: .descriptorAndSamples,
            projection: .imageDescriptorAndSamplesV1,
            digestTag: 20
        )
        let otherImageContent = ProbeContentClaim(
            algorithm: .sha256,
            scope: .descriptorAndSamples,
            projection: .imageDescriptorAndSamplesV1,
            digestTag: 21
        )
        let parameterDigest = ProbeContentClaim(
            algorithm: .sha256,
            scope: .serialisedObject,
            projection: .operationParametersV1,
            digestTag: 30
        )
        let metadataDigest = ProbeContentClaim(
            algorithm: .sha256,
            scope: .serialisedObject,
            projection: .metadataCompleteRecordV1,
            digestTag: 31
        )

        let locatorA = ProbeSourceLocator(
            namespace: makeText("org.voxelia.source"),
            identifier: makeText("source-a"),
            version: makeText("v1")
        )
        let locatorB = ProbeSourceLocator(
            namespace: makeText("org.voxelia.source"),
            identifier: makeText("source-b"),
            version: makeText("v2")
        )
        let sourceA = ProbeSourceIdentity(locator: locatorA, contentClaim: sourceContent)
        let sourceB = ProbeSourceIdentity(locator: locatorB, contentClaim: nil)

        let versionA = ProbeSemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            prerelease: nil,
            buildMetadata: makeText("build-a")
        )
        let versionB = ProbeSemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            prerelease: nil,
            buildMetadata: makeText("build-b")
        )
        require(versionA == versionB)
        require(!versionA.isExactlyEqual(to: versionB))

        let objectReference = ProbeDataIdentityReference.object(objectA)
        let contentReference = ProbeDataIdentityReference.content(imageContent)
        let derivationA = makeDerivation(
            version: versionA,
            inputs: [objectReference, contentReference],
            parameterDigest: parameterDigest
        )
        let derivationB = makeDerivation(
            version: versionB,
            inputs: [objectReference, contentReference],
            parameterDigest: parameterDigest
        )
        require(derivationA != derivationB)

        requireThrows(ProbeIdentityError.missingIdentityClaim) {
            _ = try ProbeDataIdentity(
                objectID: objectA,
                contentClaim: nil,
                sourceIdentities: [],
                derivation: nil
            )
        }

        let states:
            [(
                ProbeContentClaim?, [ProbeSourceIdentity], ProbeDerivationIdentity?,
                ProbeIdentityState
            )] = [
                (nil, [sourceA], nil, .sourceOnly),
                (nil, [], derivationA, .derivationOnly),
                (nil, [sourceA], derivationA, .mixedLineage),
                (imageContent, [], nil, .contentOnly),
                (imageContent, [sourceA], nil, .contentAndSource),
                (imageContent, [], derivationA, .contentAndDerivation),
                (imageContent, [sourceA], derivationA, .contentAndMixedLineage),
            ]
        for fixture in states {
            let identity = makeIdentity(
                objectID: objectA,
                content: fixture.0,
                sources: fixture.1,
                derivation: fixture.2
            )
            require(identity.state == fixture.3)
        }

        requireThrows(ProbeIdentityError.duplicateSourceLocator) {
            _ = try ProbeDataIdentity(
                objectID: objectA,
                contentClaim: nil,
                sourceIdentities: [sourceA, sourceA],
                derivation: nil
            )
        }
        let conflictingSource = ProbeSourceIdentity(
            locator: locatorA,
            contentClaim: ProbeContentClaim(
                algorithm: .sha256,
                scope: .storageObject,
                projection: .sourceStorageObjectV1,
                digestTag: 11
            )
        )
        requireThrows(ProbeIdentityError.duplicateSourceLocator) {
            _ = try ProbeDataIdentity(
                objectID: objectA,
                contentClaim: nil,
                sourceIdentities: [sourceA, conflictingSource],
                derivation: nil
            )
        }

        let orderedSources = makeIdentity(
            objectID: objectA,
            content: nil,
            sources: [sourceA, sourceB],
            derivation: nil
        )
        let reorderedSources = makeIdentity(
            objectID: objectA,
            content: nil,
            sources: [sourceB, sourceA],
            derivation: nil
        )
        require(orderedSources != reorderedSources)

        let composed = makeText("\u{00E9}")
        let decomposed = makeText("e\u{0301}")
        require(composed != decomposed)
        requireThrows(ProbeIdentityError.invalidText) {
            _ = try ProbeExactText(" \t")
        }

        let contentWithSource = makeIdentity(
            objectID: objectA,
            content: imageContent,
            sources: [sourceA],
            derivation: nil
        )
        require(contentWithSource.contentClaim?.scope == .descriptorAndSamples)
        require(contentWithSource.sourceIdentities[0].contentClaim?.scope == .storageObject)
        let sameContentOtherObject = makeIdentity(
            objectID: objectB,
            content: imageContent,
            sources: [],
            derivation: nil
        )
        let sameContentFirstObject = makeIdentity(
            objectID: objectA,
            content: imageContent,
            sources: [],
            derivation: nil
        )
        require(sameContentOtherObject != sameContentFirstObject)
        require(sameContentOtherObject.contentClaim == sameContentFirstObject.contentClaim)

        let repeatedInputDerivation = makeDerivation(
            version: versionA,
            inputs: [contentReference, contentReference],
            parameterDigest: parameterDigest
        )
        require(repeatedInputDerivation.inputIdentities.count == 2)
        let reorderedInputs = makeDerivation(
            version: versionA,
            inputs: [contentReference, objectReference],
            parameterDigest: parameterDigest
        )
        require(derivationA != reorderedInputs)

        let generator = makeDerivation(
            version: versionA,
            inputs: [],
            parameterDigest: parameterDigest,
            operationProfile: .zeroInputGeneratorV1
        )
        require(generator.inputIdentities.isEmpty)
        requireThrows(ProbeIdentityError.undeclaredZeroInputGenerator) {
            _ = try ProbeDerivationIdentity(
                operationProfile: .transformationV1,
                operationVersion: versionA,
                implementationID: nil,
                inputIdentities: [],
                parameterDigest: parameterDigest
            )
        }
        requireThrows(ProbeIdentityError.unsupportedParameterProfile) {
            _ = try ProbeDerivationIdentity(
                operationProfile: .transformationV1,
                operationVersion: versionA,
                implementationID: nil,
                inputIdentities: [objectReference],
                parameterDigest: metadataDigest
            )
        }
        requireThrows(ProbeIdentityError.unsupportedParameterProfile) {
            _ = try ProbeDerivationIdentity(
                operationProfile: .transformationV1,
                operationVersion: versionA,
                implementationID: nil,
                inputIdentities: [objectReference],
                parameterDigest: ProbeContentClaim(
                    algorithm: .sha256,
                    scope: .storageObject,
                    projection: .operationParametersV1,
                    digestTag: 30
                )
            )
        }
        requireThrows(ProbeIdentityError.unsupportedParameterProfile) {
            _ = try ProbeDerivationIdentity(
                operationProfile: .transformationV1,
                operationVersion: versionA,
                implementationID: nil,
                inputIdentities: [objectReference],
                parameterDigest: ProbeContentClaim(
                    algorithm: .sha512,
                    scope: .serialisedObject,
                    projection: .operationParametersV1,
                    digestTag: 30
                )
            )
        }

        let trustContext = ProbeTrustContext(
            tenant: makeText("tenant-a"),
            privacyDomain: makeText("clinical-a"),
            securityDomain: makeText("local-trusted"),
            purpose: makeText("processing"),
            policyVersion: makeText("policy-v1")
        )
        let otherPolicy = ProbeTrustContext(
            tenant: makeText("tenant-a"),
            privacyDomain: makeText("clinical-a"),
            securityDomain: makeText("local-trusted"),
            purpose: makeText("processing"),
            policyVersion: makeText("policy-v2")
        )
        let otherTenant = ProbeTrustContext(
            tenant: makeText("tenant-b"),
            privacyDomain: makeText("clinical-a"),
            securityDomain: makeText("local-trusted"),
            purpose: makeText("processing"),
            policyVersion: makeText("policy-v1")
        )
        let otherPrivacyDomain = ProbeTrustContext(
            tenant: makeText("tenant-a"),
            privacyDomain: makeText("research-a"),
            securityDomain: makeText("local-trusted"),
            purpose: makeText("processing"),
            policyVersion: makeText("policy-v1")
        )
        let otherSecurityDomain = ProbeTrustContext(
            tenant: makeText("tenant-a"),
            privacyDomain: makeText("clinical-a"),
            securityDomain: makeText("remote-attested"),
            purpose: makeText("processing"),
            policyVersion: makeText("policy-v1")
        )
        let otherPurpose = ProbeTrustContext(
            tenant: makeText("tenant-a"),
            privacyDomain: makeText("clinical-a"),
            securityDomain: makeText("local-trusted"),
            purpose: makeText("export"),
            policyVersion: makeText("policy-v1")
        )
        let baseExecutionKey = ProbeExecutionCacheKey(
            operationID: makeText("org.voxelia.probe.operation"),
            operationVersion: makeText("1.0.0"),
            implementationVersion: makeText("impl-v1"),
            canonicalParameterClaim: parameterDigest,
            inputContentIdentities: [imageContent],
            executionProfile: makeText("reference"),
            backendAndCapability: makeText("cpu-portable"),
            precisionPolicy: makeText("binary64"),
            shaderOrKernelVersion: makeText("kernel-v1"),
            environmentVersion: makeText("environment-v1"),
            trustContext: trustContext
        )
        let derivationRecordID = ProbeDerivationRecordID(value: makeText("derivation-a"))
        let sourceAttestation = ProbeSourceAttestation(
            locator: locatorA,
            context: trustContext
        )
        let evidence = ProbeAdmissionEvidence(
            verifiedContent: [
                ProbeVerifiedContentEvidence(
                    objectID: objectA,
                    claim: imageContent,
                    context: trustContext,
                    verifiedSnapshot: 90
                )
            ],
            sourceAttestations: [sourceAttestation],
            deterministicDerivations: [
                ProbeBoundDerivationEvidence(
                    recordID: derivationRecordID,
                    executionKey: baseExecutionKey
                )
            ],
            derivationsWithAdmissibleInputs: [
                ProbeBoundDerivationEvidence(
                    recordID: derivationRecordID,
                    executionKey: baseExecutionKey
                )
            ]
        )
        let noEvidence = ProbeAdmissionEvidence(
            verifiedContent: [],
            sourceAttestations: [],
            deterministicDerivations: [],
            derivationsWithAdmissibleInputs: []
        )

        require(
            admitPersistentCacheReference(
                contentReference,
                evidence: noEvidence,
                context: trustContext,
                verifiedContentObjectID: objectA,
                verifiedContentSnapshot: 90
            ) == .denied
        )
        require(
            admitPersistentCacheReference(
                contentReference,
                evidence: evidence,
                context: trustContext,
                verifiedContentObjectID: objectA,
                verifiedContentSnapshot: 90
            ) == .verifiedContent(imageContent, trustContext)
        )
        require(
            admitPersistentCacheReference(
                contentReference,
                evidence: evidence,
                context: otherPolicy,
                verifiedContentObjectID: objectA,
                verifiedContentSnapshot: 90
            ) == .denied
        )
        for otherContext in [
            otherTenant,
            otherPrivacyDomain,
            otherSecurityDomain,
            otherPurpose,
        ] {
            require(
                admitPersistentCacheReference(
                    contentReference,
                    evidence: evidence,
                    context: otherContext,
                    verifiedContentObjectID: objectA,
                    verifiedContentSnapshot: 90
                ) == .denied
            )
        }
        require(
            admitPersistentCacheReference(
                contentReference,
                evidence: evidence,
                context: trustContext
            ) == .denied
        )
        require(
            admitPersistentCacheReference(
                contentReference,
                evidence: evidence,
                context: trustContext,
                verifiedContentObjectID: objectA,
                verifiedContentSnapshot: 91
            ) == .denied
        )
        require(
            admitPersistentCacheReference(
                contentReference,
                evidence: evidence,
                context: trustContext,
                verifiedContentObjectID: objectB,
                verifiedContentSnapshot: 90
            ) == .denied
        )
        require(
            admitPersistentCacheReference(
                .source(sourceA),
                evidence: evidence,
                context: trustContext
            ) == .trustedVersionedSource(locatorA, trustContext)
        )
        require(
            admitPersistentCacheReference(
                .source(sourceA),
                evidence: evidence,
                context: otherPolicy
            ) == .denied
        )
        let unversionedSource = ProbeSourceIdentity(
            locator: ProbeSourceLocator(
                namespace: makeText("org.voxelia.source"),
                identifier: makeText("unversioned"),
                version: nil
            ),
            contentClaim: nil
        )
        require(
            admitPersistentCacheReference(
                .source(unversionedSource),
                evidence: evidence,
                context: trustContext
            ) == .denied
        )
        require(
            admitPersistentCacheReference(
                objectReference,
                evidence: evidence,
                context: trustContext
            ) == .denied
        )

        let derivationReference = ProbeDataIdentityReference.derivation(derivationRecordID)
        require(
            admitPersistentCacheReference(
                derivationReference,
                evidence: evidence,
                context: trustContext,
                executionKey: baseExecutionKey
            ) == .deterministicDerivation(derivationRecordID, baseExecutionKey)
        )
        require(
            admitPersistentCacheReference(
                derivationReference,
                evidence: noEvidence,
                context: trustContext,
                executionKey: baseExecutionKey
            ) == .denied
        )
        require(
            admitPersistentCacheReference(
                derivationReference,
                evidence: evidence,
                context: trustContext
            ) == .denied
        )

        func executionKeyVariant(
            operationID: ProbeExactText? = nil,
            operationVersion: ProbeExactText? = nil,
            implementationVersion: ProbeExactText? = nil,
            canonicalParameterClaim: ProbeContentClaim? = nil,
            inputContentIdentities: ContiguousArray<ProbeContentClaim>? = nil,
            executionProfile: ProbeExactText? = nil,
            backendAndCapability: ProbeExactText? = nil,
            precisionPolicy: ProbeExactText? = nil,
            shaderOrKernelVersion: ProbeExactText? = nil,
            environmentVersion: ProbeExactText? = nil,
            trustContext: ProbeTrustContext? = nil
        ) -> ProbeExecutionCacheKey {
            ProbeExecutionCacheKey(
                operationID: operationID ?? baseExecutionKey.operationID,
                operationVersion: operationVersion ?? baseExecutionKey.operationVersion,
                implementationVersion: implementationVersion
                    ?? baseExecutionKey.implementationVersion,
                canonicalParameterClaim: canonicalParameterClaim
                    ?? baseExecutionKey.canonicalParameterClaim,
                inputContentIdentities: inputContentIdentities
                    ?? baseExecutionKey.inputContentIdentities,
                executionProfile: executionProfile ?? baseExecutionKey.executionProfile,
                backendAndCapability: backendAndCapability
                    ?? baseExecutionKey.backendAndCapability,
                precisionPolicy: precisionPolicy ?? baseExecutionKey.precisionPolicy,
                shaderOrKernelVersion: shaderOrKernelVersion
                    ?? baseExecutionKey.shaderOrKernelVersion,
                environmentVersion: environmentVersion
                    ?? baseExecutionKey.environmentVersion,
                trustContext: trustContext ?? baseExecutionKey.trustContext
            )
        }
        let executionKeyVariants = [
            executionKeyVariant(operationID: makeText("org.voxelia.probe.other-operation")),
            executionKeyVariant(operationVersion: makeText("1.0.1")),
            executionKeyVariant(implementationVersion: makeText("impl-v2")),
            executionKeyVariant(
                canonicalParameterClaim: ProbeContentClaim(
                    algorithm: .sha256,
                    scope: .serialisedObject,
                    projection: .operationParametersV1,
                    digestTag: 32
                )
            ),
            executionKeyVariant(inputContentIdentities: [otherImageContent]),
            executionKeyVariant(executionProfile: makeText("diagnostic")),
            executionKeyVariant(backendAndCapability: makeText("gpu-family-a")),
            executionKeyVariant(precisionPolicy: makeText("binary32")),
            executionKeyVariant(shaderOrKernelVersion: makeText("kernel-v2")),
            executionKeyVariant(environmentVersion: makeText("environment-v2")),
            executionKeyVariant(trustContext: otherPolicy),
            executionKeyVariant(trustContext: otherTenant),
            executionKeyVariant(trustContext: otherPrivacyDomain),
            executionKeyVariant(trustContext: otherSecurityDomain),
            executionKeyVariant(trustContext: otherPurpose),
        ]
        for variant in executionKeyVariants {
            require(baseExecutionKey != variant)
            require(
                admitPersistentCacheReference(
                    derivationReference,
                    evidence: evidence,
                    context: variant.trustContext,
                    executionKey: variant
                ) == .denied
            )
        }
        require(Set(executionKeyVariants).count == executionKeyVariants.count)

        requireThrows(ProbeIdentityError.conflictingContentClaim) {
            _ = try contentWithSource.addingContentClaim(
                otherImageContent,
                resultingObjectID: objectA
            )
        }

        let initialIdentity = makeIdentity(
            objectID: objectB,
            content: nil,
            sources: [sourceA],
            derivation: nil
        )
        let successfulPublisher = ProbeIdentityPublisher(
            identity: initialIdentity,
            generation: 7,
            snapshot: 90,
            completionObjectID: objectB,
            trustContext: trustContext,
            publicationAuthorization: .cacheAndProvenance
        )
        do {
            try await successfulPublisher.finish(
                computed: imageContent,
                expected: imageContent,
                generation: 7,
                pinnedSnapshot: 90
            )
        } catch {
            preconditionFailure("Valid publication unexpectedly failed.")
        }
        let completed = await successfulPublisher.snapshot()
        require(completed.identity.contentClaim == imageContent)
        require(completed.assurance?.objectID == objectB)
        require(completed.assurance?.claim == imageContent)
        require(completed.assurance?.generation == 7)
        require(completed.assurance?.snapshot == 90)
        require(completed.assurance?.context == trustContext)
        require(completed.cacheAliasCount == 1)
        require(completed.provenanceSuccessCount == 1)
        do {
            try await successfulPublisher.finish(
                computed: imageContent,
                expected: imageContent,
                generation: 7,
                pinnedSnapshot: 90
            )
            preconditionFailure("A completion was published twice.")
        } catch let error as ProbePublicationError {
            require(error == .alreadyPublished)
        } catch {
            preconditionFailure("Unexpected publication error type.")
        }

        let replacementObjectPublisher = ProbeIdentityPublisher(
            identity: initialIdentity,
            generation: 7,
            snapshot: 90,
            completionObjectID: objectA,
            trustContext: trustContext,
            publicationAuthorization: .identityOnly
        )
        do {
            try await replacementObjectPublisher.finish(
                computed: imageContent,
                expected: imageContent,
                generation: 7,
                pinnedSnapshot: 90
            )
        } catch {
            preconditionFailure("Externally selected replacement ID failed.")
        }
        let replacementCompleted = await replacementObjectPublisher.snapshot()
        require(replacementCompleted.identity.objectID == objectA)
        require(replacementCompleted.identity.contentClaim == imageContent)
        require(replacementCompleted.assurance?.objectID == objectA)
        require(replacementCompleted.cacheAliasCount == 0)
        require(replacementCompleted.provenanceSuccessCount == 0)

        let faultCases: [(ProbeContentClaim?, UInt64, UInt64, Bool, Bool, ProbePublicationError)] =
            [
                (imageContent, 7, 90, true, false, .cancelled),
                (imageContent, 7, 90, false, true, .failed),
                (imageContent, 8, 90, false, false, .staleGeneration),
                (imageContent, 7, 91, false, false, .snapshotChanged),
                (otherImageContent, 7, 90, false, false, .mismatch),
            ]
        for fault in faultCases {
            let publisher = ProbeIdentityPublisher(
                identity: initialIdentity,
                generation: 7,
                snapshot: 90,
                completionObjectID: objectB,
                trustContext: trustContext,
                publicationAuthorization: .cacheAndProvenance
            )
            do {
                try await publisher.finish(
                    computed: imageContent,
                    expected: fault.0,
                    generation: fault.1,
                    pinnedSnapshot: fault.2,
                    cancelled: fault.3,
                    failed: fault.4
                )
                preconditionFailure("Fault path unexpectedly published.")
            } catch let error as ProbePublicationError {
                require(error == fault.5)
            } catch {
                preconditionFailure("Unexpected publication error type.")
            }
            let unchanged = await publisher.snapshot()
            require(unchanged.identity == initialIdentity)
            require(unchanged.assurance == nil)
            require(unchanged.cacheAliasCount == 0)
            require(unchanged.provenanceSuccessCount == 0)
        }

        let preexistingClaimPublisher = ProbeIdentityPublisher(
            identity: contentWithSource,
            generation: 7,
            snapshot: 90,
            completionObjectID: objectA,
            trustContext: trustContext,
            publicationAuthorization: .cacheAndProvenance
        )
        do {
            try await preexistingClaimPublisher.finish(
                computed: imageContent,
                expected: nil,
                generation: 7,
                pinnedSnapshot: 90
            )
        } catch {
            preconditionFailure("Matching pre-existing claim was not admitted.")
        }
        let preexistingCompleted = await preexistingClaimPublisher.snapshot()
        require(preexistingCompleted.identity == contentWithSource)
        require(preexistingCompleted.assurance?.claim == imageContent)
        require(preexistingCompleted.cacheAliasCount == 1)
        require(preexistingCompleted.provenanceSuccessCount == 1)

        let existingClaimFaults: [(ProbeContentClaim, ProbeContentClaim?)] = [
            (otherImageContent, nil),
            (imageContent, otherImageContent),
        ]
        for fault in existingClaimFaults {
            let publisher = ProbeIdentityPublisher(
                identity: contentWithSource,
                generation: 7,
                snapshot: 90,
                completionObjectID: objectA,
                trustContext: trustContext,
                publicationAuthorization: .cacheAndProvenance
            )
            do {
                try await publisher.finish(
                    computed: fault.0,
                    expected: fault.1,
                    generation: 7,
                    pinnedSnapshot: 90
                )
                preconditionFailure("Conflicting existing claim was overwritten.")
            } catch let error as ProbePublicationError {
                require(error == .mismatch)
            } catch {
                preconditionFailure("Unexpected publication error type.")
            }
            let unchanged = await publisher.snapshot()
            require(unchanged.identity == contentWithSource)
            require(unchanged.assurance == nil)
            require(unchanged.cacheAliasCount == 0)
            require(unchanged.provenanceSuccessCount == 0)
        }

        let sentinel = "PATIENT-SOURCE-SENTINEL"
        let safeErrors: [any Error] = [
            ProbeIdentityError.missingIdentityClaim,
            ProbeIdentityError.duplicateSourceLocator,
            ProbePublicationError.cancelled,
            ProbePublicationError.mismatch,
            ProbePublicationError.staleGeneration,
        ]
        for error in safeErrors {
            require(!String(describing: error).contains(sentinel))
            require(!String(reflecting: error).contains(sentinel))
        }

        let sensitiveIdentity = makeIdentity(
            objectID: ProbeObjectID(value: makeText(sentinel)),
            content: imageContent,
            sources: [],
            derivation: nil
        )
        require(!String(describing: sensitiveIdentity).contains(sentinel))
        require(!String(reflecting: sensitiveIdentity).contains(sentinel))
        require(Mirror(reflecting: sensitiveIdentity).children.isEmpty)
    }
}
