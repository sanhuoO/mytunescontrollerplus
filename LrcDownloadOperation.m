//
//  LrcDownloadOperation.m
//  lrcDownloader
//
//  Created by zhili hu on 2/4/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcDownloadOperation.h"

#include <fcntl.h>
#include <unistd.h>

@interface LrcDownloadOperation ()

@property (copy, readwrite) NSString *lrcFilePath;

@end

@implementation LrcDownloadOperation

- (id)initWithURL:(NSURL *)url lrcDirPath:(NSString *)lrcDirPath lrcFileName:(NSString*)name
{
    assert(lrcDirPath != nil);
    self = [super initWithURL:url];
    if (self != nil) {
        self->_lrcDirPath = [lrcDirPath copy];
		self->_lrcName = [name copy];
    }
    return self;
}

- (void)dealloc
{
	[self->_lrcName release];
    [self->_lrcFilePath release];
    [self->_lrcDirPath release];
    [super dealloc];
}

@synthesize lrcDirPath = _lrcDirPath;
@synthesize lrcFilePath = _lrcFilePath;


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
// An NSURLConnect delegate method.  We override this to set up a 
// destination output stream for the incoming image data.
{
    [super connection:connection didReceiveResponse:response];
    
    if (self.isStatusCodeAcceptable) {
        NSString *  extension;
        assert(self.responseOutputStream == nil);

		NSString *  filePath;
		int         counter;
		int         fd;
		
		extension = @"lrc";
		
		// Repeatedly try to create a new file with that info, adding a 
		// unique number if we get a conflict.
		counter = 0;
		filePath = [self.lrcDirPath stringByAppendingPathComponent:[_lrcName stringByAppendingPathExtension:extension]];
		do {
			int     err;
			int     junk;
			
			err = 0;
			fd = open([filePath UTF8String], O_CREAT | O_EXCL | O_RDWR, 0666);
			if (fd < 0) {
				err = errno;
			} else {
				junk = close(fd);
				assert(junk == 0);
			}
			
			if (err == 0) {
				self.lrcFilePath = filePath;
				self.responseOutputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
				break;
			} else if (err == EEXIST) {
				counter += 1;
				if (counter > 500) {
					break;
				}
				filePath = [self.lrcDirPath stringByAppendingPathComponent:[[NSString stringWithFormat:@"%@-%d", _lrcName, counter] stringByAppendingPathExtension:extension]];
			} else if (err == EINTR) {
				// do nothing
			} else {
				break;
			}
		} while (YES);
        // If we've failed to create a valid file, redirect the output to the bit bucket.
        
        if (self.responseOutputStream == nil) {
            self.responseOutputStream = [NSOutputStream outputStreamToFileAtPath:@"/dev/null" append:NO];
        }
    }
}

@end