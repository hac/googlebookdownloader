#import "GoogleBook.h"

#import "GoogleBooksAPI.h"

#import <RegexKit/RegexKit.h>

#import "HacStringAdditions.h"

#import "AppController.h"

@implementation GoogleBook

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
#pragma mark JSON Parsing

- (void)addKeysToImageIndexFromString:(NSString *)indexString
{
	RKRegex *pageNumberPattern = [RKRegex regexWithRegexString:@"\"pid\":\"([^\"]*)\"" options:RKCompileCaseless];
	RKEnumerator *matches = [indexString matchEnumeratorWithRegex:pageNumberPattern];
	
	while (matches && [matches nextRanges])
	{
		NSString *pageNumberSubstring = [indexString substringWithRange:[matches currentRange]];
		NSString *pageNumber = [pageNumberSubstring stringByMatching:pageNumberPattern withReferenceString:@"${1}"];
		
		if (![pageOrder containsObject:pageNumber])
		{
			[pageOrder addObject:pageNumber];
			[imageIndex setObject:@"" forKey:pageNumber];
		}
	}
}

- (void)addValuesToImageIndexFromString:(NSString *)indexString
{
	RKRegex *pageNumberPattern = @"\"pid\":\"([^\"]*)\",\"src\":\"([^\"]*)\"";
	RKEnumerator *matches = [indexString matchEnumeratorWithRegex:pageNumberPattern];
	
	while (matches && [matches nextRanges])
	{
		NSString *pageNumberSubstring = [indexString substringWithRange:[matches currentRange]];
		NSString *pageNumber = [pageNumberSubstring stringByMatching:pageNumberPattern withReferenceString:@"${1}"];
		NSString *imagePath = [pageNumberSubstring stringByMatching:pageNumberPattern withReferenceString:@"${2}"];
		
		imagePath = [imagePath stringByReplacingOccurrencesOfString:@"\\u0026"
														 withString:@"&"];
		[imageIndex setObject:imagePath forKey:pageNumber];
	}
}

#pragma mark -
#pragma mark Indexing

- (void)getInitialIndex
{
	if (!initialIndexJSON)
	{
		// Get an initial index so we can get all the page numbers in the book
		initialIndexJSON = [[GoogleBooksAPI initialJsonIndexForBookWithId:bookId] retain];
	}
}

- (BOOL)bookIsValid
{
	[self getInitialIndex];
	return ([initialIndexJSON length] > 0);
}

- (BOOL)completeIndex
{	
	[self getInitialIndex];
	
	// This object stores the image url that goes with each page.
	imageIndex = [[NSMutableDictionary alloc] init];
	
	// This object stores the order of the pages (so we can put them back together later).
	pageOrder = [[NSMutableArray alloc] init];
	
	// Get all the page numbers from the initial index.
	[self addKeysToImageIndexFromString:initialIndexJSON];
	
	// It will probably also have the URLs for the first few pages. Take those so we don't have to look them up later.
	[self addValuesToImageIndexFromString:initialIndexJSON];
	
	NSProgressIndicator *progressIndicator = [delegate bookProcessingProgressIndicator];
	[progressIndicator setDoubleValue:0];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:[pageOrder count]];
	
	// The following loop should not make sense to you if you don't know how the Google Books server returns URLs:
	int i;
	for (i = 0; i < [pageOrder count]; i++)
	{
		// Update the progress window.
		[progressIndicator setDoubleValue:(double)i];
		[delegate bookProcessingStatusChanged:[NSString stringWithFormat:@"Finding image URLs: %d/%d pages complete", i, [pageOrder count]]];
		
		NSString *pageNumber = [pageOrder objectAtIndex:i];
		if ([[imageIndex valueForKey:pageNumber] isEqualToString:@""])
		{
			if ([pageOrder count] > i+1)
			{
				i++;
				NSString *nextPageNumber = [pageOrder objectAtIndex:i];
				[self addValuesToImageIndexFromString:[GoogleBooksAPI jsonIndexByAskingForPage:nextPageNumber
																				 ForBookWithId:bookId]];
			}
			
			if ([[imageIndex valueForKey:pageNumber] isEqualToString:@""])
			{
				[self addValuesToImageIndexFromString:[GoogleBooksAPI jsonIndexByAskingForPage:pageNumber
																				 ForBookWithId:bookId]];
			}
			
			// Stop if the user clicks cancel.
			if (shouldAbortAsSoonAsPossible)
			{
				NSString *logString = [NSString stringWithFormat:@"Index of %@ was CANCELLED with %d URLs.",
									   [self bookId],
									   [pageOrder count]];
				[[AppController sharedController] writeStringToLog:logString];
				return NO;
			}
		}
	}
	
	NSString *logString = [NSString stringWithFormat:@"Index of %@ was COMPLETED with %d URLs.",
						   [self bookId],
						   [pageOrder count]];
	[[AppController sharedController] writeStringToLog:logString];
	
	return YES;
}
					
#pragma mark -
#pragma mark PDF Generation

- (PDFDocument *)pdfDocument
{
	PDFDocument *pdfDocument = [[[PDFDocument alloc] init] autorelease];
	
	NSProgressIndicator *progressIndicator = [delegate bookProcessingProgressIndicator];
	[progressIndicator setDoubleValue:0];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:[pageOrder count]];
	
	int i;
	for (i = 0; i < [pageOrder count]; i++)
	{
		[progressIndicator setDoubleValue:(double)i];
		[delegate bookProcessingStatusChanged:[NSString stringWithFormat:@"Building PDF: %d/%d pages complete", i, [pageOrder count]]];
		
		NSString *pageNumber = [pageOrder objectAtIndex:i];
		NSString *imagePath = [imageIndex valueForKey:pageNumber];
		
		// We will need to check the user's preferences on page size.
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		if ([defaults boolForKey:@"UseCustomPageWidth"])
			// If the user has a custom page width set...
		{
			// Ask Google for the page to have the specific width.
			int imageWidth = [defaults integerForKey:@"BookWidth"];
			imagePath = [NSString stringWithFormat:@"%@&w=%d", imagePath, imageWidth];
		}
		
		// Download the page image.
		NSImage *pageImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:imagePath]];
		
		if ([defaults boolForKey:@"UseCustomPageWidth"])
			// If the user has a custom page width set...
		{
			// Sometimes the image ends up with the wrong dimensions, even though all the information is there.
			// Set the size to make sure it is right.
			int imageWidth = [defaults integerForKey:@"BookWidth"];
			[pageImage setSize:NSMakeSize(imageWidth, [pageImage size].height * (float)imageWidth / [pageImage size].width)];
		}
		
		NSString *logString = [NSString stringWithFormat:@"%@> Adding image: %@\nWIDTH:%f HEIGHT:%f", [self bookId], imagePath, [pageImage size].width, [pageImage size].height];
		[[AppController sharedController] writeStringToLog:logString];
		
		PDFPage *page = [[PDFPage alloc] initWithImage:(id)pageImage]; // If we don't cast pageImage to type id we get a warning. I don't know why.
		
		[pdfDocument insertPage:page atIndex:[pdfDocument pageCount]];
		
		//[imageData release];
		[pageImage release];
		[page release];
		
		// Stop if the user clicks cancel.
		if (shouldAbortAsSoonAsPossible)
			return nil;
	}
	
	return pdfDocument;
}

#pragma mark -
#pragma mark Cancelling active procedures.

- (void)abortProcedures
{
	shouldAbortAsSoonAsPossible = YES;
}
					
#pragma mark -
#pragma mark Life Cycle

- (void)dealloc
{
	[initialIndexJSON release];
	[imageIndex release];
	[pageOrder release];
	
	[super dealloc];
}

@end
