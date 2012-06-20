//
//  SZShareDialogViewController.m
//  Socialize
//
//  Created by Nathaniel Griswold on 6/19/12.
//  Copyright (c) 2012 Socialize. All rights reserved.
//

#import "SZShareDialogViewController.h"
#import "_SZShareDialogViewController.h"

@interface SZShareDialogViewController ()
@property (nonatomic, strong) _SZShareDialogViewController *shareDialog;

@end

@implementation SZShareDialogViewController
@synthesize completionBlock = _completionBlock;
@synthesize cancellationBlock = _cancellationBlock;
@synthesize shareDialog = _shareDialog;
@synthesize shares = _shares;
@synthesize entity = entity_;

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithEntity:(id<SZEntity>)entity {
    if (self = [super init]) {
        self.entity = entity;
        [self pushShareDialog];
    }
    
    return self;
}

- (void)pushShareDialog {
    _SZShareDialogViewController *shareDialog = [[_SZShareDialogViewController alloc] initWithEntity:self.entity];
    [self pushViewController:shareDialog animated:NO];
}

- (_SZShareDialogViewController*)shareDialog {
    if (_shareDialog == nil) {
        _shareDialog = [[_SZShareDialogViewController alloc] init];
    }
    return _shareDialog;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setCompletionBlock:(void (^)(NSArray *shares))completionBlock {
    _completionBlock = completionBlock;
    self.shareDialog.completionBlock = completionBlock;
}

@end
