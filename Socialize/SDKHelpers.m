//
//  SDKHelpers.m
//  SocializeSDK
//
//  Created by Nathaniel Griswold on 5/20/12.
//  Copyright (c) 2012 Socialize, Inc. All rights reserved.
//

#import "SDKHelpers.h"
#import "SocializeObjects.h"
#import "SZShareOptions.h"
#import "SZFacebookUtils.h"
#import "SZTwitterUtils.h"
#import "SZCommentOptions.h"
#import "SocializeThirdParty.h"
#import "Socialize.h"
#import <BlocksKit/BlocksKit.h>
#import "SZDisplay.h"
#import "SZUserUtils.h"
#import "_Socialize.h"
#import "SocializePrivateDefinitions.h"
#import "_SZSelectNetworkViewController.h"
#import "SZLinkDialogViewController.h"
#import "SZSelectNetworkViewController.h"
#import "SZLocationUtils.h"
#import "socialize_globals.h"

SZSocialNetwork SZLinkedSocialNetworks() {
    SZSocialNetwork networks = SZSocialNetworkNone;
    
    if ([SZTwitterUtils isLinked]) {
        networks |= SZSocialNetworkTwitter;
    }
    
    if ([SZFacebookUtils isLinked]) {
        networks |= SZSocialNetworkFacebook;
    }
    
    return networks;
}

SZSocialNetwork SZAvailableSocialNetworks() {
    SZSocialNetwork networks = SZSocialNetworkNone;
    
    if ([SZTwitterUtils isAvailable]) {
        networks |= SZSocialNetworkTwitter;
    }
    
    if ([SZFacebookUtils isAvailable]) {
        networks |= SZSocialNetworkFacebook;
    }
    
    return networks;
}

BOOL ShouldShowLinkDialog() {
    return ( SZLinkedSocialNetworks() == SZSocialNetworkNone && SZAvailableSocialNetworks() != SZSocialNetworkNone && ![Socialize authenticationNotRequired]);
}

void SZShowLinkToFacebookAlertView(void (^okBlock)(), void (^cancelBlock)()) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Authentication Required" message:@"Link to Facebook?"];
    [alertView addButtonWithTitle:@"Cancel" handler:cancelBlock];
    [alertView addButtonWithTitle:@"Ok" handler:okBlock];

    [alertView show];
}

void SZLinkAndGetPreferredNetworks(UIViewController *viewController, void (^completion)(SZSocialNetwork preferredNetworks), void (^cancellation)()) {
    
    // No Social Networks available
    if (SZAvailableSocialNetworks() == SZSocialNetworkNone) {
        BLOCK_CALL_1(completion, SZSocialNetworkNone);
    }
    
    if (ShouldShowLinkDialog()) {
        
        // Link and possibly show network selection
        SZLinkDialogViewController *link = [[SZLinkDialogViewController alloc] init];
        __block SZLinkDialogViewController *weakLink = link;
        link.completionBlock = ^(SZSocialNetwork selectedNetwork) {
            
            if (selectedNetwork != SZSocialNetworkNone) {
                
                // Linked to a network -- Show network selection
                _SZSelectNetworkViewController *selectNetwork = [[_SZSelectNetworkViewController alloc] init];
                selectNetwork.completionBlock = ^(SZSocialNetwork selectedNetworks) {
                    [viewController dismissViewControllerAnimated:YES completion:^{
                        BLOCK_CALL_1(completion, selectedNetworks);
                    }];
                };
                selectNetwork.cancellationBlock = ^{
                    [link.navigationController popToViewController:link animated:YES];
                };
                
                [weakLink pushViewController:selectNetwork animated:YES];
            } else {
                
                // Opted out of linking -- Don't show network selection
                [viewController dismissViewControllerAnimated:YES completion:^{
                    BLOCK_CALL_1(completion, SZSocialNetworkNone);
                }];
            }
        };
        
        link.cancellationBlock = ^{
            
            // Explicitly cancelled link -- Dismiss and call cancellation
            [viewController dismissViewControllerAnimated:YES completion:^{
                BLOCK_CALL(cancellation);                
            }];
        };
        
        [viewController presentModalViewController:link animated:YES];
    } else {
        
        // No link dialog required
        SZSelectNetworkViewController *selectNetwork = [[SZSelectNetworkViewController alloc] init];
        selectNetwork.completionBlock = ^(SZSocialNetwork selectedNetworks) {
            [viewController dismissViewControllerAnimated:YES completion:^{
                BLOCK_CALL_1(completion, selectedNetworks);
            }];
            
        };
        selectNetwork.cancellationBlock = ^{
            [viewController dismissViewControllerAnimated:YES completion:^{
                BLOCK_CALL(cancellation);
            }];
        };
        
        [viewController presentModalViewController:selectNetwork animated:YES];
    }
}

void SZFBAuthWrapper( void (^success)(), void (^failure)(NSError *error)) {
    if (![SZFacebookUtils isLinked]) {
        [SZFacebookUtils linkWithOptions:nil success:^(id _) {
            BLOCK_CALL(success);
        } foreground:nil failure:^(NSError *error) {
            BLOCK_CALL_1(failure, error);
        }];
    } else {
        success();
    }
}

void SZAuthWrapper(void (^success)(), void (^failure)(NSError *error)) {
    if (![[Socialize sharedSocialize] isAuthenticated]) {
        [[Socialize sharedSocialize] authenticateAnonymouslyWithSuccess:success failure:failure];
    } else {
        success();
    }
}

BOOL SZShouldShareLocation() {
    // FIXME -- Sense should be inverted for a simpler check
    NSNumber *shouldShareNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kSocializeShouldShareLocationKey];
    if (shouldShareNumber == nil) {
        return YES;
    }
    
    return [shouldShareNumber boolValue];
}

SZActivityOptions *SZActivityOptionsFromUserDefaults(Class optionsClass) {
    SZActivityOptions *options = [optionsClass defaultOptions];
    options.dontShareLocation = ![[[NSUserDefaults standardUserDefaults] objectForKey:kSocializeShouldShareLocationKey] boolValue];
    
    return options;
}
                                                   
SocializeShareMedium SocializeShareMediumForSZSocialNetworks(SZSocialNetwork networks) {
    // Currently Must exlusively share to a Social Network for this to be the medium.
    SocializeShareMedium medium;
    if (networks == SZSocialNetworkFacebook) {
        medium = SocializeShareMediumFacebook;
    } else if (networks == SZSocialNetworkTwitter) {
        medium = SocializeShareMediumTwitter;
    } else {
        medium = SocializeShareMediumOther;
    }
    return medium;
}

void CreateAndShareActivityPromptIfNeeded(id<SZActivity> activity, SZShareOptions *options, ActivityCreatorBlock creator, void (^success)(id<SZActivity> activity), void (^failure)(NSError *error)) {
    if (options == nil) {
        
    }
}

void SZAttemptAction(NSTimeInterval retryInterval, SZAttemptActionBlock attempt) {
    __block void (^attemptBlock)() = ^{
        attempt(^(NSError* error) {
            [NSTimer scheduledTimerWithTimeInterval:retryInterval block:^(NSTimeInterval interval) {
                attemptBlock();
            } repeats:NO];
        });
    };
    
    attemptBlock();
}

void CreateAndShareActivity(id<SZActivity> activity, SZActivityOptions *options, SZSocialNetwork networks, ActivityCreatorBlock creator, void (^success)(id<SZActivity> activity), void (^failure)(NSError *error)) {
    if (networks & SZSocialNetworkFacebook && (![SZFacebookUtils isAvailable] || ![SZFacebookUtils isLinked])) {
        BLOCK_CALL_1(failure, [NSError defaultSocializeErrorForCode:SocializeErrorFacebookUnavailable]);
        return;
    }
    
    if (networks & SZSocialNetworkTwitter && (![SZTwitterUtils isAvailable] || ![SZTwitterUtils isLinked])) {
        BLOCK_CALL_1(failure, [NSError defaultSocializeErrorForCode:SocializeErrorTwitterUnavailable]);
        return;
    }
    
    if (networks & SZSocialNetworkFacebook) {
        activity.propagationInfoRequest = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"facebook"] forKey:@"third_parties"];
    }
    
    if (networks & SZSocialNetworkTwitter) {
        activity.propagation = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"twitter"] forKey:@"third_parties"];
    }
    
    void (^creationBlock)() = ^{
        
        creator(activity, ^(id<SZActivity> activity) {
            if (networks & SZSocialNetworkFacebook) {
                
                // This shortened link returned from the server encapsulates all the Socialize magic
                NSString *shareURL = [[[activity propagationInfoResponse] objectForKey:@"facebook"] objectForKey:@"application_url"];
                
                NSString *name = activity.application.name;
                NSString *link = shareURL;
                NSString *caption = [NSString stringWithSocializeAppDownloadPlug];
                
                // Build the message string
                NSMutableString *message = [NSMutableString string];
                if ([activity.entity.name length] > 0) {
                    [message appendFormat:@"%@: ", activity.entity.name];
                }
                
                [message appendFormat:@"%@\n\n", shareURL];
                
                NSString *text = nil;
                if ([activity respondsToSelector:@selector(text)]) {
                    text = [(id)activity text];
                }
                if ([text length] > 0) {
                    [message appendFormat:@"%@\n\n", text];
                }
                
                [message appendFormat:@"Shared from %@.", activity.application.name];
                
                NSMutableDictionary *postData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 message, @"message",
                                                 caption, @"caption",
                                                 link, @"link",
                                                 name, @"name",
                                                 @"This is the description", @"description",
                                                 nil];
                
                BLOCK_CALL_2(options.willPostToSocialNetworkBlock, SZSocialNetworkFacebook, postData);
                
                [SZFacebookUtils postWithGraphPath:@"me/links" params:postData success:^(id result) {
                    BLOCK_CALL_1(options.didPostToSocialNetworkBlock, SZSocialNetworkFacebook);
                    BLOCK_CALL_1(success, activity);
                } failure:^(NSError *error) {
                    
                    // Failed Wall post is still a success. Handle separately in options.
                    BLOCK_CALL_1(options.didFailToPostToSocialNetworkBlock, SZSocialNetworkFacebook);

                    BLOCK_CALL_1(success, activity);
                }];
            } else {
                BLOCK_CALL_1(success, activity);
            }
        }, failure);
        
    };

    if (SZShouldShareLocation() && !options.dontShareLocation) {
        [SZLocationUtils getCurrentLocationWithSuccess:^(CLLocation *location) {
            activity.lat = [NSNumber numberWithDouble:location.coordinate.latitude];
            activity.lng = [NSNumber numberWithDouble:location.coordinate.longitude];
            creationBlock();
        } failure:^(NSError *error) {
            NSLog(@"Socialize Warning: Location sharing requested, but could not get location. %@", [error localizedDescription]);
            creationBlock();
        }];
    } else {
        creationBlock();
    }    
}

BOOL SZErrorsAreDisabled() {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kSocializeUIErrorAlertsDisabled] boolValue];
}

void UIControllerDidFailWithErrorNotification(id object, NSError *error) {
    NSDictionary *userInfo = nil;
    if (error != nil) {
        userInfo = [NSDictionary dictionaryWithObject:error forKey:SocializeUIControllerErrorUserInfoKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SocializeUIControllerDidFailWithErrorNotification
                                                        object:object
                                                      userInfo:userInfo];
}

void SZPostSocializeUIControllerDidFailWithErrorNotification(id object, NSError *error) {
    NSDictionary *userInfo = nil;
    if (error != nil) {
        userInfo = [NSDictionary dictionaryWithObject:error forKey:SocializeUIControllerErrorUserInfoKey];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SocializeUIControllerDidFailWithErrorNotification
                                                        object:object
                                                      userInfo:userInfo];
}

void SZEmitUIError(id object, NSError *error) {
    SZPostSocializeUIControllerDidFailWithErrorNotification(object, error);
    
    if (!SZErrorsAreDisabled()) {
        UIAlertView *alertView = [UIAlertView alertWithTitle:@"Error" message:[error localizedDescription]];
        [alertView addButtonWithTitle:@"Ok"];
        [alertView show];
    }
}

void SZEmitUnconfiguredFacebookMessage() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(SOCIALIZE_FACEBOOK_NOT_CONFIGURED_MESSAGE);
    });

}

void SZEmitUnconfiguredTwitterMessage() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(SOCIALIZE_TWITTER_NOT_CONFIGURED_MESSAGE);        
    });
    
}

void SZEmitUnconfiguredSmartAlertsMessage() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(SOCIALIZE_NOTIFICATIONS_NOT_CONFIGURED_MESSAGE);
    });
}

BOOL SZOSGTE(NSString *minVersion) {
    NSString *currOsVersion = [[UIDevice currentDevice] systemVersion];
    NSComparisonResult result = [currOsVersion compare:minVersion options:NSNumericSearch];
    return result == NSOrderedSame || result == NSOrderedDescending;
}
