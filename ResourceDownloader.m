//
//  ResourceDownloader.m
//  Google Book Downloader
//
//  Created by Ω on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ResourceDownloader.h"

@implementation ResourceDownloader

- (void)startFromURL:(NSString *)url
{
	requestIndex = [[NSMutableArray alloc] init];
	
	webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 800)];
	
	[webView setResourceLoadDelegate:self];
	[webView setFrameLoadDelegate:self];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void)stop
{
	[webView setResourceLoadDelegate:nil];
	[webView setFrameLoadDelegate:nil];
	[webView release];
	webView = nil;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	if (frame == [sender mainFrame])
	{
		[self onload];
	}
}

- (void)onload
{
}

// http://google.com/codesearch#6R_f0l7yfPc/Eclipse%20SWT%20WebKit/carbon/org/eclipse/swt/browser/WebKit.java&q=didFinishLoadingFromDataSource&ct=rc&cd=20&sq=&l=1307

- (void)resourceLoaded:(WebResource *)resource
{
}

- (void)webView:(WebView *)sender
	   resource:(id)identifier
didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	if (webView != nil)
	{
		[self resourceLoaded:[dataSource subresourceForURL:[(NSURLRequest *)identifier URL]]];
	}
	r--;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource;
{
	r--;
}

- (id) webView : (WebView *) sender identifierForInitialRequest : (NSURLRequest  *) request fromDataSource : (id) dataSource
{
	[requestIndex addObject:[request URL]];
	
	r++;
	return request;
}

- (int)currentDownloads
{
	return r;
}

- (void)dealloc
{
	[webView release];
	webView = nil;
	
	[requestIndex release];
	requestIndex = nil;
	
	[super dealloc];
}

@end
