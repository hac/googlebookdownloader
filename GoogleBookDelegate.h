@protocol GoogleBookDelegate

- (void)bookProcessingDidFailWithMessageText:(NSString *)messageText
						  andInformativeText:(NSString *)informativeText;

- (void)bookProcessingStatusChanged:(NSString *)statusText;

- (NSProgressIndicator *)bookProcessingProgressIndicator;

@end
