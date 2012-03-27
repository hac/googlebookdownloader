#import "GoogleBook.h"
#import "GoogleBooksAPI.h"
#import <RegexKit/RegexKit.h>
#import "HacStringAdditions.h"
#import "HacHTMLDocument.h"
#import "AppController.h"
#import "DDURLParser.h"
#import "WebView+FakeClicking.h"

@implementation GoogleBook

- (id)init
{
	if (self = [super init])
	{
		bookId = nil;
		startPage = nil;
		
		scrollComplete = NO;
		isPDF = NO;
		shouldAbortAsSoonAsPossible = NO;
		
		pdfIndex = [[NSMutableArray alloc] init];
		pageNumberMap = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[startPage release];
	[bookId release];

	[pdfIndex release];
	[pageNumberMap release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessor Methods

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

- (id)delegate
{
	return delegate;
}

- (void)setBookId:(NSString *)newBookId
{
	[bookId release];
	bookId = [newBookId copy];
}

- (NSString *)bookId
{
	return bookId;
}

- (void)setStartPage:(NSString *)newStartPage
{
	[startPage release];
	startPage = [newStartPage copy];
}

- (NSString *)startPage
{
	return startPage;
}

- (void)setPageLimit:(int)newPageLimit
{
	pageLimit = newPageLimit;
}

- (int)pageLimit
{
	return pageLimit;
}

#pragma mark -
#pragma mark Book Metadata

- (NSString *)bookTitle
{
	NSString *title = [GoogleBooksAPI titleForBookWithId:bookId];
	if (title)
		return title;

	// If we fail to get a title from the API, just use the book identifier.
	return [NSString stringWithFormat:@"Google Book %@", bookId];
}

#pragma mark -
#pragma mark Downloading

- (BOOL)bookExists
{
	return [GoogleBooksAPI overviewPageExistsForBookWithId:bookId];
}

- (void)beginScroll
{
	[webView runScript:@"ScrollThroughBook"];
}

- (void)onload
{
	[webView runScript:@"jquery-1.6.2.min"];
	
	//[webView runScript:@"HideToolbars"];
	
	// This intentional pause helps to let the fake clicker click the zoom in button.
	[NSTimer scheduledTimerWithTimeInterval:3
									 target:self
								   selector:@selector(beginScroll)
								   userInfo:nil
									repeats:NO];
}

- (void)checkScrollComplete
{
	// Look for the zoom in button.
	// Buttons: ":0" = Zoom out, ":1" = Zoom in, ":2" = One page, ":3" = Two pages
	if (!zoomedIn)
	{
		int zoomLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"ZoomLevel"];
		if (zoomLevel)
		{
			zoomedIn = [webView clickElementWithId:@":0" repeat:zoomLevel];
		}
		else
		{
			zoomedIn = YES;
		}

	}
	
	// Check if the scroller has reached the bottom.
	NSString *stringScrollComplete = [webView stringByEvaluatingJavaScriptFromString:@"scrollComplete"];
	if ([stringScrollComplete isEqualToString:@"true"]) scrollComplete = YES;
}

- (void)downloadAllPages
{
	NSString *url = [NSString stringWithFormat:@"http://books.google.com/books?id=%@&printsec=frontcover", bookId];
	if (startPage)
	{
		url = [url stringByAppendingFormat:@"&pg=PA%@", startPage];
	}	
	NSLog(@"Downloading: %@", url);
	[self performSelectorOnMainThread:@selector(startFromURL:)
						   withObject:url
						waitUntilDone:YES];
	
	// Wait until either...
	// 1) The web browser is completely scrolled down and there are no currently loading images
	// or 2) The user clicked cancel
	
	while ((scrollComplete == NO || [self currentDownloads] > 0) && shouldAbortAsSoonAsPossible == NO)
	{
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		[self performSelectorOnMainThread:@selector(checkScrollComplete) withObject:nil waitUntilDone:YES];
	}
	
	if (!zoomedIn)
	{
		NSLog(@"FAILED to zoom in");
	}
	
	[self stop];
}

#pragma mark -
#pragma mark PDF Generation

- (PDFDocument *)pdfDocument
{
	pdfDocument = [[PDFDocument alloc] init];
	
	isPDF = YES;
	
	[self downloadAllPages];
		
	return [pdfDocument autorelease];
}

#pragma mark -
#pragma mark Saving as a folder
- (BOOL)saveImagesToFolder:(NSString *)aFolderPath
{
	folderPath = [aFolderPath retain];
	
	NSProgressIndicator *progressIndicator = [delegate bookProcessingProgressIndicator];
	[progressIndicator setDoubleValue:0];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:nil];
	
	BOOL isDirectory;
	if ([[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory] && isDirectory)
	{
		[[NSFileManager defaultManager] removeFileAtPath:folderPath handler:nil];
	}
	
	if (![[NSFileManager defaultManager] createDirectoryAtPath:folderPath
													attributes:nil])
	{
		return NO;
	}
	
	htmlBody = [[NSMutableString alloc] init];
	
	pagesDownloaded = 0;
	
	[self downloadAllPages];
		
	NSString *html = [HacHTMLDocument htmlWithTitle:[self bookTitle]
											   body:htmlBody];
	[html writeToFile:[folderPath stringByAppendingPathComponent:@"index.html"]
		   atomically:YES];
	
	[folderPath release];
	folderPath = nil;
	
	[htmlBody release];
	htmlBody = nil;
		
	return YES;
}

- (void)resourceLoaded:(WebResource *)resource
{
	NSArray *mimeParts = [[resource MIMEType] componentsSeparatedByString:@"/"];
	NSString *extension = nil;
	if ([[mimeParts objectAtIndex:0] isEqualToString:@"image"])
	{
		extension = [mimeParts objectAtIndex:1];
	}
/*	else if ([[mimeParts objectAtIndex:0] isEqualToString:@"text"]) {
		extension = @"txt";
	}*/
	else
	{
		return;
	}

	DDURLParser *parser = [[[DDURLParser alloc] initWithURLString:[[resource URL] absoluteString]] autorelease];
	NSString *pg = [parser valueForVariable:@"pg"];
	int width = [[parser valueForVariable:@"w"] intValue];
	
	if (pg == nil)
	{
		return;
	}
	
	if (isPDF)
	{
		// We will need to check the user's preferences on page size.
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		// Download the page image.
		NSImage *pageImage = [[[NSImage alloc] initWithData:[resource data]] autorelease];
			
		// Sometimes the image ends up with the wrong dimensions, even though all the information is there.
		// Set the size to make sure it is right.
		// If the user has a custom page width set use that.
		int imageWidth = ([defaults boolForKey:@"UseCustomPageWidth"])?[defaults integerForKey:@"BookWidth"]:width;
		[pageImage setSize:NSMakeSize(imageWidth, [pageImage size].height * (float)imageWidth / [pageImage size].width)];
		
		NSString *logString = [NSString stringWithFormat:@"%@> Adding image: %@.%@\nWIDTH:%f HEIGHT:%f", [self bookId], pg, extension, [pageImage size].width, [pageImage size].height];
		[[AppController sharedController] writeStringToLog:logString];
		
		bool pageImageIsValid = (pageImage != nil) && ([pageImage size].width > 0) && ([pageImage size].height > 0);
		
		if (pageImageIsValid)
		{
			// This number refers to the order at which each image on the page begins to load.
			// Since many pages can be loading simultaneously, the order at which the finish loading might be wrong.
			int imageNumber = [requestIndex indexOfObject:[resource URL]];
			
			// If there is already an image of this page, delete it.
			// It's probably a lower quality image from before we zoomed in.
			NSNumber *existingPage = [pageNumberMap objectForKey:pg];
			if (existingPage)
			{
				// Get information about the existing image.
				NSURL *existingURL = [requestIndex objectAtIndex:[existingPage intValue]];
				int existingImageNumber = [requestIndex indexOfObject:existingURL];
				DDURLParser *existingPageParser = [[[DDURLParser alloc] initWithURLString:[existingURL absoluteString]] autorelease];
				int existingWidth = [[existingPageParser valueForVariable:@"w"] intValue];
				
				// If it's larger, then don't add the new one.
				if (existingWidth > width)
				{
					return;
				}
				
				// Otherwise delete the old one.
				int indexToDelete = [pdfIndex indexOfObject:[NSNumber numberWithInt:existingImageNumber]];
				[pdfIndex removeObjectAtIndex:indexToDelete];
				[pdfDocument removePageAtIndex:indexToDelete];
			}
			else
			{
				pagesDownloaded++;
			}

			
			[pageNumberMap setObject:[NSNumber numberWithInt:imageNumber] forKey:pg];
			
			// If we get pages loaded so late that after them are already in the PDF, backtrack to the right spot.
			// This bug fixed was introduced in 2.0.1
			int insertIndex = [pdfDocument pageCount];
			while (insertIndex > 0
				   && imageNumber < [[pdfIndex objectAtIndex:insertIndex-1] intValue])
			{
				insertIndex--;
			}
			
			// Use PDFKit to add turn the image into a PDF page and add it to the file in memory.
			PDFPage *page = [[PDFPage alloc] initWithImage:(id)pageImage]; // If we don't cast pageImage to type id we get a warning. I don't know why.
			[pdfDocument insertPage:page atIndex:insertIndex];
			[pdfIndex insertObject:[NSNumber numberWithInt:imageNumber] atIndex:insertIndex];
			[page release];
		}
	}
	else
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:folderPath attributes:nil];
		
		NSString *filePath = [NSString stringWithFormat:@"%@/%@.%@", folderPath, pg, extension];
		
		BOOL overwriting = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
		
		[[resource data] writeToFile:filePath atomically:YES];
		
		if (!overwriting)
		{
			[htmlBody appendFormat:@"<img src=\"%@.%@\" /><br />\n", pg, extension];
			pagesDownloaded++;
		}
	}
	
	if (pageLimit && pagesDownloaded >= pageLimit + 1)
	{
		[pdfDocument removePageAtIndex:1]; // Delete the second page because it's really the -1st page.
		 
		shouldAbortAsSoonAsPossible = YES;
	}
	
	[delegate bookProcessingStatusChanged:[NSString stringWithFormat:@"Downloading images: %d pages complete", pagesDownloaded]];
}

#pragma mark -
#pragma mark Cancelling active procedures

- (void)abortProcedures
{
	shouldAbortAsSoonAsPossible = YES;
}

@end
