//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import <SignalUtilitiesKit/OWSRecipientIdentity.h>
#import <SessionProtocolKit/IdentityKeyStore.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const OWSPrimaryStorageIdentityKeyStoreIdentityKey;
extern NSString *const LKSeedKey;
extern NSString *const LKED25519SecretKey;
extern NSString *const LKED25519PublicKey;
extern NSString *const OWSPrimaryStorageIdentityKeyStoreCollection;

extern NSString *const OWSPrimaryStorageTrustedKeysCollection;

// This notification will be fired whenever identities are created
// or their verification state changes.
extern NSString *const kNSNotificationName_IdentityStateDidChange;

// number of bytes in a signal identity key, excluding the key-type byte.
extern const NSUInteger kIdentityKeyLength;

#ifdef DEBUG
extern const NSUInteger kStoredIdentityKeyLength;
#endif

@class OWSRecipientIdentity;
@class OWSStorage;
@class SNProtoVerified;
@class YapDatabaseReadWriteTransaction;

// This class can be safely accessed and used from any thread.
@interface OWSIdentityManager : NSObject <IdentityKeyStore>

@property (nonatomic, readonly) YapDatabaseConnection *dbConnection;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPrimaryStorage:(OWSPrimaryStorage *)primaryStorage NS_DESIGNATED_INITIALIZER;

+ (instancetype)sharedManager;

- (void)generateNewIdentityKeyPair;
- (void)clearIdentityKey;

- (nullable OWSRecipientIdentity *)recipientIdentityForRecipientId:(NSString *)recipientId;

/**
 * @param   recipientId unique stable identifier for the recipient, e.g. e164 phone number
 * @returns nil if the recipient does not exist, or is trusted for sending
 *          else returns the untrusted recipient.
 */
- (nullable OWSRecipientIdentity *)untrustedIdentityForSendingToRecipientId:(NSString *)recipientId;

// This method can be called from any thread.
- (void)throws_processIncomingSyncMessage:(SNProtoVerified *)verified
                              transaction:(YapDatabaseReadWriteTransaction *)transaction;

- (BOOL)saveRemoteIdentity:(NSData *)identityKey recipientId:(NSString *)recipientId;

- (nullable ECKeyPair *)identityKeyPair;

#pragma mark - Debug

#if DEBUG
// Clears everything except the local identity key.
- (void)clearIdentityState:(YapDatabaseReadWriteTransaction *)transaction;

- (void)snapshotIdentityState:(YapDatabaseReadWriteTransaction *)transaction;
- (void)restoreIdentityState:(YapDatabaseReadWriteTransaction *)transaction;
#endif

@end

NS_ASSUME_NONNULL_END
