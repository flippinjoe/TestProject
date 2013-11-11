//
//  GTURLConnectionController.h
//
//  Created by Tyson Tune on 5/25/09.
//  Copyright 2009 Good Touch, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTURLConnectionController : NSObject {
  NSURLConnection *urlconnect;
  NSString *username;
  NSString *userpass;
  NSMutableData *responseData;
  id delegate;
}

@property (nonatomic, strong) NSMutableData *responseData;

- (id)initWithFeed:(NSString *)feed usernameOrNil:(NSString *)uname userpassOrNil:(NSString *)upass;
- (id)initWithRequest:(NSURLRequest *)req delegate:(id)aDelegate;
- (id)initWithDelegate:(id)aDelegate;
- (void)makeRequest:(NSURLRequest *)aRequest;
- (void)getUrl:(NSString *)url_string;
-(void)cancel;
-(void)killDelegate;
@end

@protocol GTURLConnectionDelegate
- (void)connection:(GTURLConnectionController *)connection finishedWithData:(NSData *)data;
- (void)connection:(GTURLConnectionController *)connection receivedStatusCode:(int)code;
@optional
- (void)connection:(GTURLConnectionController *)connection failedWithMessage:(NSString *)message;
- (void)connection:(GTURLConnectionController *)connection didUploadBytes:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

@end

