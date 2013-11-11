//
//  MFlowEventOperation.h
//  USAToday1
//
//  Created by Stephen Tallent on 1/28/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Operation for automated event upload.
 Uploads any events found in the database that are older than 72 hours.
 */
@interface MFlowEventOperation : NSOperation {

}

@end
