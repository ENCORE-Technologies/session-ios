//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "TSInfoMessage.h"
#import "SSKEnvironment.h"
#import <SessionProtocolKit/SessionProtocolKit.h>
#import <YapDatabase/YapDatabaseConnection.h>
#import <SessionUtilitiesKit/SessionUtilitiesKit.h>

NS_ASSUME_NONNULL_BEGIN

NSUInteger TSInfoMessageSchemaVersion = 1;

@interface TSInfoMessage ()

@property (nonatomic, getter=wasRead) BOOL read;

@property (nonatomic, readonly) NSUInteger infoMessageSchemaVersion;

@end

#pragma mark -

@implementation TSInfoMessage

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    if (self.infoMessageSchemaVersion < 1) {
        _read = YES;
    }

    _infoMessageSchemaVersion = TSInfoMessageSchemaVersion;

    if (self.isDynamicInteraction) {
        self.read = YES;
    }

    return self;
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)thread
                      messageType:(TSInfoMessageType)infoMessage
{
    // MJK TODO - remove senderTimestamp
    self = [super initMessageWithTimestamp:timestamp
                                  inThread:thread
                               messageBody:nil
                             attachmentIds:@[]
                          expiresInSeconds:0
                           expireStartedAt:0
                             quotedMessage:nil
                               linkPreview:nil];

    if (!self) {
        return self;
    }

    _messageType = infoMessage;
    _infoMessageSchemaVersion = TSInfoMessageSchemaVersion;

    if (self.isDynamicInteraction) {
        self.read = YES;
    }

    return self;
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)thread
                      messageType:(TSInfoMessageType)infoMessage
                    customMessage:(NSString *)customMessage
{
    self = [self initWithTimestamp:timestamp inThread:thread messageType:infoMessage];
    if (self) {
        _customMessage = customMessage;
    }
    return self;
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)thread
                      messageType:(TSInfoMessageType)infoMessage
          unregisteredRecipientId:(NSString *)unregisteredRecipientId
{
    self = [self initWithTimestamp:timestamp inThread:thread messageType:infoMessage];
    if (self) {
        _unregisteredRecipientId = unregisteredRecipientId;
    }
    return self;
}

+ (instancetype)userNotRegisteredMessageInThread:(TSThread *)thread recipientId:(NSString *)recipientId
{
    // MJK TODO - remove senderTimestamp
    return [[self alloc] initWithTimestamp:[NSDate millisecondTimestamp]
                                  inThread:thread
                               messageType:TSInfoMessageUserNotRegistered
                   unregisteredRecipientId:recipientId];
}

- (OWSInteractionType)interactionType
{
    return OWSInteractionType_Info;
}

- (NSString *)previewTextWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    switch (_messageType) {
        case TSInfoMessageTypeLokiSessionResetInProgress:
            return NSLocalizedString(@"Secure session reset in progress", nil);
        case TSInfoMessageTypeLokiSessionResetDone:
            return NSLocalizedString(@"Secure session reset done", nil);
        case TSInfoMessageTypeSessionDidEnd:
            return NSLocalizedString(@"SECURE_SESSION_RESET", nil);
        case TSInfoMessageTypeUnsupportedMessage:
            return NSLocalizedString(@"UNSUPPORTED_ATTACHMENT", nil);
        case TSInfoMessageUserNotRegistered:
            if (self.unregisteredRecipientId.length > 0) {
                NSString *recipientName = @"";
                return [NSString stringWithFormat:NSLocalizedString(@"ERROR_UNREGISTERED_USER_FORMAT",
                                                      @"Format string for 'unregistered user' error. Embeds {{the "
                                                      @"unregistered user's name or signal id}}."),
                                 recipientName];
            } else {
                return NSLocalizedString(@"CONTACT_DETAIL_COMM_TYPE_INSECURE", nil);
            }
        case TSInfoMessageTypeGroupQuit:
            return NSLocalizedString(@"GROUP_YOU_LEFT", nil);
        case TSInfoMessageTypeGroupUpdate:
            return _customMessage != nil ? _customMessage : NSLocalizedString(@"GROUP_UPDATED", nil);
        case TSInfoMessageAddToContactsOffer:
            return NSLocalizedString(@"ADD_TO_CONTACTS_OFFER",
                @"Message shown in conversation view that offers to add an unknown user to your phone's contacts.");
        case TSInfoMessageAddUserToProfileWhitelistOffer:
            return NSLocalizedString(@"ADD_USER_TO_PROFILE_WHITELIST_OFFER",
                @"Message shown in conversation view that offers to share your profile with a user.");
        case TSInfoMessageAddGroupToProfileWhitelistOffer:
            return NSLocalizedString(@"ADD_GROUP_TO_PROFILE_WHITELIST_OFFER",
                @"Message shown in conversation view that offers to share your profile with a group.");
        default:
            break;
    }

    return @"Unknown Info Message Type";
}

#pragma mark - OWSReadTracking

- (BOOL)shouldAffectUnreadCounts
{
    return NO;
}

- (uint64_t)expireStartedAt
{
    return 0;
}

- (void)markAsReadAtTimestamp:(uint64_t)readTimestamp
              sendReadReceipt:(BOOL)sendReadReceipt
                  transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    if (_read) {
        return;
    }

    _read = YES;
    [self saveWithTransaction:transaction];

    // Ignore sendReadReceipt, it doesn't apply to info messages.
}

@end

NS_ASSUME_NONNULL_END
