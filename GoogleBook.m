#import "GoogleBook.h"

#import "GoogleBooksAPI.h"

#import <RegexKit/RegexKit.h>

#import "HacStringAdditions.h"

#import "HacHTMLDocument.h"

#import "AppController.h"

#import "DDURLParser.h"

@implementation GoogleBook

- (id)init
{
	if (self = [super init])
	{
		scrollComplete = NO;
		isPDF = NO;
		shouldAbortAsSoonAsPossible = NO;
	}
	return self;
}

- (void)dealloc
{
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

- (void)onload
{
	[self runScript:@"jquery-1.6.2.min"];
	[self runScript:@"HideToolbars"];
	[self runScript:@"ScrollThroughBook"];
}

- (void)checkScrollComplete
{
	NSString *stringScrollComplete = [webView stringByEvaluatingJavaScriptFromString:@"scrollComplete"];
	if ([stringScrollComplete isEqualToString:@"true"]) scrollComplete = YES;
}

- (void)downloadAllPages
{
	[self performSelectorOnMainThread:@selector(startFromURL:)
						   withObject:[NSString stringWithFormat:@"http://books.google.com/books?id=%@&printsec=frontcover", bookId]
						waitUntilDone:YES];
	
	// Wait until either...
	// 1) The web browser is completely scrolled down and there are no currently loading images
	// or 2) The user clicked cancel
	
	while ((scrollComplete == NO || [self currentDownloads] > 0) && shouldAbortAsSoonAsPossible == NO)
	{
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		[self performSelectorOnMainThread:@selector(checkScrollComplete) withObject:nil waitUntilDone:YES];
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
	
	if (pg == nil)
	{
		return;
	}
	
	if (isPDF)
	{
		// We will need to check the user's preferences on page size.
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		// Download the page image.
		NSImage *pageImage = [[NSImage alloc] initWithData:[resource data]];
		
		if ([defaults boolForKey:@"UseCustomPageWidth"])
			// If the user has a custom page width set...
		{
			// Sometimes the image ends up with the wrong dimensions, even though all the information is there.
			// Set the size to make sure it is right.
			int imageWidth = [defaults integerForKey:@"BookWidth"];
			[pageImage setSize:NSMakeSize(imageWidth, [pageImage size].height * (float)imageWidth / [pageImage size].width)];
		}
		
		NSString *logString = [NSString stringWithFormat:@"%@> Adding image: %@.%@\nWIDTH:%f HEIGHT:%f", [self bookId], pg, extension, [pageImage size].width, [pageImage size].height];
		[[AppController sharedController] writeStringToLog:logString];
		
		bool pageImageIsValid = (pageImage != nil) && ([pageImage size].width > 0) && ([pageImage size].height > 0);
		
		if (pageImageIsValid)
		{
			PDFPage *page = [[PDFPage alloc] initWithImage:(id)pageImage]; // If we don't cast pageImage to type id we get a warning. I don't know why.
			[pdfDocument insertPage:page atIndex:[pdfDocument pageCount]];
			[page release];
		}
		
		[pageImage release];
	}
	else
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:folderPath attributes:nil];
		[[resource data] writeToFile:[NSString stringWithFormat:@"%@/%@.%@", folderPath, pg, extension] atomically:YES];
		
		[htmlBody appendFormat:@"<img src=\"%@.%@\" /><br />\n", pg, extension];
	}

	pagesDownloaded++;
	
	[delegate bookProcessingStatusChanged:[NSString stringWithFormat:@"Downloading images: %d pages complete", pagesDownloaded]];
}

#pragma mark -
#pragma mark Cancelling active procedures

- (void)abortProcedures
{
	shouldAbortAsSoonAsPossible = YES;
}

@end
