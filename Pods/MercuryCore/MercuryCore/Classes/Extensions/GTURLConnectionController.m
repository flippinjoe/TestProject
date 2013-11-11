//
//  GTURLConnectionController.m
//
//  Created by Tyson Tune on 5/25/09.
//  Copyright 2009 Good Touch, LLC. All rights reserved.
//

#import "GTURLConnectionController.h"

@implementation GTURLConnectionController

@synthesize responseData;

- (id)initWithFeed:(NSString *)feed usernameOrNil:(NSString *)uname userpassOrNil:(NSString *)upass {
  if(self = [super init]) {
    if(uname != nil) username = uname;
    if(upass != nil) userpass = upass;
    self.responseData = [NSMutableData dataWithCapacity:1];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:feed]];
    [request setValue:@"GTURLConnector 1.0" forHTTPHeaderField:@"User-Agent"];
    urlconnect = [NSURLConnection connectionWithRequest:request delegate:self];
  }
  return self;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  NSLog(@"GTURLConnectionController didFailWithError: %@",error);
  if(delegate != nil && [delegate respondsToSelector:@selector(connection:failedWithMessage:)]) {
      [delegate connection:self failedWithMessage:[NSString stringWithFormat:@"Error: %@", error]];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  if([challenge previousFailureCount] > 0) { // auth failed
    // TODO: handle auth fail
    [connection cancel];
    ////NSLog(@"auth failed");
    return;
  }
  if(username != nil && userpass != nil) {
    NSURLCredential *credentials = [NSURLCredential credentialWithUser:username password:userpass persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];

  } else { // no user pass got to cancel and inform
    [connection cancel];
  }
} 

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  int statusCode = [(NSHTTPURLResponse *)response statusCode];
  if(statusCode == 503) {
    // ack throttled by forbidden, cancel it
    [connection cancel];
    if(delegate != nil && [delegate respondsToSelector:@selector(connection:failedWithMessage:)]) {
      [delegate connection:self failedWithMessage:@"Status 503"];
    }
  } else if(statusCode == 500) {
    [connection cancel];
  }
  if(delegate != nil && [delegate respondsToSelector:@selector(connection:receivedStatusCode:)]) {
    [delegate connection:self receivedStatusCode:statusCode];
  }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if(delegate != nil && [delegate respondsToSelector:@selector(connection:finishedWithData:)]) {
    [delegate connection:self finishedWithData:self.responseData];
  }
}

#pragma mark Upload Data progress

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  if(delegate != nil && [delegate respondsToSelector:@selector(connection:didUploadBytes:totalBytesWritten:totalBytesExpectedToWrite:)]) {
    [delegate connection:self didUploadBytes:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
  }
}

-(id)initWithDelegate:(id)aDelegate{
	if(self = [super init]) {
		delegate = aDelegate;
    }
	
	return self;

}
- (id)initWithRequest:(NSURLRequest *)req delegate:(id)aDelegate {
  if(self = [super init]) {
    delegate = aDelegate;
    [self makeRequest:req];
  }
  return self;
}

-(void)cancel{
	[urlconnect cancel]; 
}

-(void)killDelegate{
	
	[self cancel];
	
	if (delegate != nil) {
		delegate = nil;
	}
}

// to make integration from HTTPSocket easier
- (void)getUrl:(NSString *)url_string {
	[self cancel];
	NSURL *anURL = [NSURL URLWithString:url_string];
	NSURLRequest *request = [NSURLRequest requestWithURL:anURL];
	[self makeRequest:request];
}

- (void)makeRequest:(NSURLRequest *)aRequest {
  //urlconnect = nil;
  //self.responseData = nil;
//  NSURLConnection *anUrlconnect = [NSURLConnection connectionWithRequest:aRequest delegate:self];
  [NSURLConnection connectionWithRequest:aRequest delegate:self];
  self.responseData = [NSMutableData dataWithCapacity:1];
}


@end
