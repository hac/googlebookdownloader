/*
 This class gets information from Google Books by a combination of these two methods:
 - HTML
 - JSON from the private AJAX API
 */

#import <Foundation/Foundation.h>

@interface GoogleBooksAPI : NSObject
{
}

+ (BOOL)overviewPageExistsForBookWithId:(NSString *)bookId;
+ (NSString *)titleForBookWithId:(NSString *)bookId;

+ (NSString *)initialJsonIndexForBookWithId:(NSString *)bookId;
+ (NSString *)jsonIndexByAskingForPage:(NSString *)pageNumber
						 ForBookWithId:(NSString *)bookId;

@end
