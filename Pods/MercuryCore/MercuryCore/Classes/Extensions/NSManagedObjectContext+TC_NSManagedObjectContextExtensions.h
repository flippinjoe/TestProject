//
//  NSManagedObjectContext+TC_NSManagedObjectContextExtensions.h
//  MercuryEvents
//
//  Created by Tyson Tune on 12/23/11.
//  Copyright (c) 2011 Mercury Intermedia. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef void(^CoreDataSaveCompleteBlock)(BOOL success, NSNotification *didSaveNotification, NSError *error);

@interface NSManagedObjectContext (TC_NSManagedObjectContextExtensions)

- (void)setSaveBlock:(CoreDataSaveCompleteBlock)saveBlock;
- (CoreDataSaveCompleteBlock)saveBlock;


@end
