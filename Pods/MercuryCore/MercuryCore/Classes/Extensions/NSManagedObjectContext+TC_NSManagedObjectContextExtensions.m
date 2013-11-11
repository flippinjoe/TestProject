//
//  NSManagedObjectContext+TC_NSManagedObjectContextExtensions.m
//  MercuryEvents
//
//  Created by Tyson Tune on 12/23/11.
//  Copyright (c) 2011 Mercury Intermedia. All rights reserved.
//

#import "NSManagedObjectContext+TC_NSManagedObjectContextExtensions.h"
#import <objc/runtime.h>

static void const * kCoreDataSaveBlockKey = @"kCoreDataSaveBlock";

@implementation NSManagedObjectContext (TC_NSManagedObjectContextExtensions)

- (void)setSaveBlock:(CoreDataSaveCompleteBlock)saveBlock {
    objc_setAssociatedObject(self,kCoreDataSaveBlockKey,saveBlock,OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CoreDataSaveCompleteBlock)saveBlock {
    return objc_getAssociatedObject(self, kCoreDataSaveBlockKey);
}

@end
