//
//  TestShareServices.m
//  SocializeSDK
//
//  Created by Nathaniel Griswold on 11/7/11.
//  Copyright (c) 2011 Socialize, Inc. All rights reserved.
//

#import "TestShareServices.h"

@implementation TestShareServices

- (void)testCreateShare {
    NSString *shareURL = [self testURL:[NSString stringWithFormat:@"%s/share", _cmd]];
    [self createShareWithURL:shareURL medium:SocializeShareMediumFacebook text:@"a share"];
}

- (void)testCreateShareWithPropagationInfo {
    NSString *shareURL = [self testURL:[NSString stringWithFormat:@"%s/share", _cmd]];
    SocializeEntity *entity = [SocializeEntity entityWithKey:shareURL name:@"Test"];
    SocializeShare *share = [SocializeShare shareWithEntity:entity text:@"a share" medium:SocializeShareMediumFacebook];
    [share setPropagationInfoRequest:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"facebook"] forKey:@"third_parties"]];
    [self createShare:share];
    
    // verify share
    id<SocializeShare> createdShare = self.createdObject;
    NSDictionary *facebookResponse = [[createdShare propagationInfoResponse] objectForKey:@"facebook"];
    GHAssertNotNil([facebookResponse objectForKey:@"application_url"], nil);
    GHAssertNotNil([facebookResponse objectForKey:@"entity_url"], nil);
}

@end
