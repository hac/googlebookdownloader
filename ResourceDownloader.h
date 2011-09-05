//
//  ResourceDownloader.h
//  Google Book Downloader
//
//  Created by Ω on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WebKit/WebKit.h>

@interface ResourceDownloader : NSObject
{
	WebView *webView;
	NSMutableArray *requestIndex;
	int r;
}

- (void)startFromURL:(NSString *)url;
- (void)stop;
- (NSString *)runScript:(NSString *)scriptName;

- (void)onload;
- (void)resourceLoaded:(WebResource *)resource;

- (int)currentDownloads;

@end
