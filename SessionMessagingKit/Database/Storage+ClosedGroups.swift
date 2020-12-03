import SessionProtocolKit

extension Storage {
    
    // MARK: - Ratchets
    
    private static func getClosedGroupRatchetCollection(_ collection: ClosedGroupRatchetCollectionType, for groupPublicKey: String) -> String {
        switch collection {
        case .old: return "LokiOldClosedGroupRatchetCollection.\(groupPublicKey)"
        case .current: return "LokiClosedGroupRatchetCollection.\(groupPublicKey)"
        }
    }
    
    public func getClosedGroupRatchet(for groupPublicKey: String, senderPublicKey: String, from collection: ClosedGroupRatchetCollectionType = .current) -> ClosedGroupRatchet? {
        let collection = Storage.getClosedGroupRatchetCollection(collection, for: groupPublicKey)
        var result: ClosedGroupRatchet?
        Storage.read { transaction in
            result = transaction.object(forKey: senderPublicKey, inCollection: collection) as? ClosedGroupRatchet
        }
        return result
    }

    public func setClosedGroupRatchet(for groupPublicKey: String, senderPublicKey: String, ratchet: ClosedGroupRatchet, in collection: ClosedGroupRatchetCollectionType = .current, using transaction: Any) {
        let collection = Storage.getClosedGroupRatchetCollection(collection, for: groupPublicKey)
        (transaction as! YapDatabaseReadWriteTransaction).setObject(ratchet, forKey: senderPublicKey, inCollection: collection)
    }
    
    public func getAllClosedGroupRatchets(for groupPublicKey: String, from collection: ClosedGroupRatchetCollectionType = .current) -> [(senderPublicKey: String, ratchet: ClosedGroupRatchet)] {
        let collection = Storage.getClosedGroupRatchetCollection(collection, for: groupPublicKey)
        var result: [(senderPublicKey: String, ratchet: ClosedGroupRatchet)] = []
        Storage.read { transaction in
            transaction.enumerateRows(inCollection: collection) { key, object, _, _ in
                guard let ratchet = object as? ClosedGroupRatchet else { return }
                let senderPublicKey = key
                result.append((senderPublicKey: senderPublicKey, ratchet: ratchet))
            }
        }
        return result
    }

    public func removeAllClosedGroupRatchets(for groupPublicKey: String, from collection: ClosedGroupRatchetCollectionType = .current, using transaction: Any) {
        let collection = Storage.getClosedGroupRatchetCollection(collection, for: groupPublicKey)
        (transaction as! YapDatabaseReadWriteTransaction).removeAllObjects(inCollection: collection)
    }
    
    // MARK: - Private Keys
    
    private static let closedGroupPrivateKeyCollection = "LokiClosedGroupPrivateKeyCollection"

    public func getClosedGroupPrivateKey(for publicKey: String) -> String? {
        var result: String?
        Storage.read { transaction in
            result = transaction.object(forKey: publicKey, inCollection: Storage.closedGroupPrivateKeyCollection) as? String
        }
        return result
    }

    public func setClosedGroupPrivateKey(_ privateKey: String, for publicKey: String, using transaction: Any) {
        (transaction as! YapDatabaseReadWriteTransaction).setObject(privateKey, forKey: publicKey, inCollection: Storage.closedGroupPrivateKeyCollection)
    }

    public func removeClosedGroupPrivateKey(for publicKey: String, using transaction: Any) {
        (transaction as! YapDatabaseReadWriteTransaction).removeObject(forKey: publicKey, inCollection: Storage.closedGroupPrivateKeyCollection)
    }

    
    
    // MARK: - Convenience
    
    public func getAllClosedGroupSenderKeys(for groupPublicKey: String, from collection: ClosedGroupRatchetCollectionType = .current) -> Set<ClosedGroupSenderKey> {
        return Set(getAllClosedGroupRatchets(for: groupPublicKey, from: collection).map { senderPublicKey, ratchet in
            ClosedGroupSenderKey(chainKey: Data(hex: ratchet.chainKey), keyIndex: ratchet.keyIndex, publicKey: Data(hex: senderPublicKey))
        })
    }
    
    public func getUserClosedGroupPublicKeys() -> Set<String> {
        var result: Set<String> = []
        Storage.read { transaction in
            result = Set(transaction.allKeys(inCollection: Storage.closedGroupPrivateKeyCollection))
        }
        return result
    }

    public func isClosedGroup(_ publicKey: String) -> Bool {
        getUserClosedGroupPublicKeys().contains(publicKey)
    }
}