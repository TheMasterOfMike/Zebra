//
//  ZBPackageActions.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 13/5/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBPackage;
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Queue/ZBQueueType.h>
#import <Extensions/UIBarButtonItem+blocks.h>

#import "ZBPackageActionType.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageActions : NSObject
+ (void)buttonTitleForPackage:(ZBPackage *)package completion:(void (^)(NSString * _Nullable title))completion;
+ (void (^)(void))buttonActionForPackage:(ZBPackage *)package;
+ (NSArray <UITableViewRowAction *> *)rowActionsForPackage:(ZBPackage *)package inTableView:(UITableView *)tableView;
+ (NSArray <UIAlertAction *> *)alertActionsForPackage:(ZBPackage *)package;
+ (NSArray <UIPreviewAction *> *)previewActionsForPackage:(ZBPackage *)package inTableView:(UITableView *_Nullable)tableView;
+ (NSArray <UIAction *> *)menuElementsForPackage:(ZBPackage *)package inTableView:(UITableView *_Nullable)tableView API_AVAILABLE(ios(13.0));
@end

NS_ASSUME_NONNULL_END
