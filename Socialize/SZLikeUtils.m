//
//  SZLikeUtils.m
//  SocializeSDK
//
//  Created by Nathaniel Griswold on 6/3/12.
//  Copyright (c) 2012 Socialize, Inc. All rights reserved.
//

#import "SZLikeUtils.h"
#import "SZUserUtils.h"
#import "SZEntityUtils.h"
#import "SDKHelpers.h"
#import "SocializeObjects.h"
#import "SZShareUtils.h"
#import "socialize_globals.h"

@implementation SZLikeUtils

+ (SZLikeOptions*)userLikeOptions {
    SZLikeOptions *options = (SZLikeOptions*)SZActivityOptionsFromUserDefaults([SZLikeOptions class]);
    return options;
}

+ (void)likeWithViewController:(UIViewController*)viewController options:(SZLikeOptions*)options entity:(id<SZEntity>)entity success:(void(^)(id<SZLike> like))success failure:(void(^)(NSError *error))failure {
    if (options == nil) {
        options = [self userLikeOptions];
    }
    
    SZLinkAndGetPreferredNetworks(viewController, ^(SZSocialNetwork preferredNetworks) {
        
        [self likeWithEntity:entity options:[self userLikeOptions] networks:preferredNetworks success:success failure:failure];
        
    }, ^{
        
        BLOCK_CALL_1(failure, [NSError defaultSocializeErrorForCode:SocializeErrorLikeCancelledByUser]);
    });
}

+ (void)likeWithEntity:(id<SZEntity>)entity options:(SZLikeOptions*)options networks:(SZSocialNetwork)networks success:(void(^)(id<SZLike> like))success failure:(void(^)(NSError *error))failure {
    SZLike *like = [SZLike likeWithEntity:entity];
    ActivityCreatorBlock likeCreator = ^(id<SZLike> like, void(^createSuccess)(id), void(^createFailure)(NSError*)) {
        
        SZAuthWrapper(^{
            [[Socialize sharedSocialize] createLike:like success:createSuccess failure:createFailure];
        }, failure);

    };

    CreateAndShareActivity(like, options, networks, likeCreator, success, failure);
}

+ (void)unlike:(id<SZEntity>)entity success:(void(^)(id<SZLike> like))success failure:(void(^)(NSError *error))failure {
    id<SZFullUser> user = [SZUserUtils currentUser];
    
    SZAuthWrapper(^{
        [[Socialize sharedSocialize] deleteLikeForUser:user entity:entity success:success failure:failure];
    }, failure);
}

+ (void)isLiked:(id<SZEntity>)entity success:(void(^)(BOOL isLiked))success failure:(void(^)(NSError *error))failure {
    [SZEntityUtils getEntityWithKey:[entity key] success:^(id<SocializeEntity> entity) {
        BOOL isLiked = [[[entity userActionSummary] objectForKey:@"likes"] integerValue] > 0;
        BLOCK_CALL_1(success, isLiked);
    } failure:failure];
}

+ (void)getLike:(id<SZEntity>)entity success:(void(^)(id<SZLike> like))success failure:(void(^)(NSError *error))failure {
    id<SZFullUser> user = [SZUserUtils currentUser];
    
    SZAuthWrapper(^{
        [[Socialize sharedSocialize] getLikesForUser:(id<SZUser>)user entity:entity first:nil last:nil success:^(NSArray *likes) {
            BLOCK_CALL_1(success, [likes lastObject]);
        } failure:failure];
    }, failure);
}

+ (void)getLikesForUser:(id<SZUser>)user start:(NSNumber*)start end:(NSNumber*)end success:(void(^)(NSArray *likes))success failure:(void(^)(NSError *error))failure {
    SZAuthWrapper(^{
        [[Socialize sharedSocialize] getLikesForUser:user entity:nil first:start last:end success:success failure:failure];
    }, failure);
}

+ (void)getLikesForEntity:(id<SZEntity>)entity start:(NSNumber*)start end:(NSNumber*)end success:(void(^)(NSArray *likes))success failure:(void(^)(NSError *error))failure {
    SZAuthWrapper(^{
        [[Socialize sharedSocialize] getLikesForEntity:entity first:start last:end success:success failure:failure];
    }, failure);
}

+ (void)getLikeForUser:(id<SZUser>)user entity:(id<SZEntity>)entity success:(void(^)(id<SZLike> like))success failure:(void(^)(NSError *error))failure {
    SZAuthWrapper(^{
        [[Socialize sharedSocialize] getLikesForUser:user entity:entity first:nil last:nil success:^(NSArray *likes) {
            BLOCK_CALL_1(success, [likes lastObject]);
        } failure:failure];
    }, failure);
}

@end
