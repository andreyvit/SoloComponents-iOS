//
// SoloDownloader 0.1
// http://solo-components.com/
//
// Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//
#import "SoloDownloader.h"
#import <sys/stat.h>


#pragma mark - SoloDownloadTask


@interface SoloDownloadTask ()

- (void)updateProgress;

@property(nonatomic, retain) NSOperation *operation;

@end


@implementation SoloDownloadTask

@synthesize verbose=_verbose;
@synthesize finished=_finished;
@synthesize progress=_progress;

- (id)initWithURL:(NSURL *)url destinationPath:(NSString *)destinationPath interimPath:(NSString *)interimPath {
    self = [super init];
    if (self) {
        _url = [url retain];
        _destinationPath = [destinationPath copy];
        if ([interimPath length]) {
            _interimPath = [interimPath copy];
        } else {
            _interimPath = [[destinationPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"#%@#.%@", [[destinationPath lastPathComponent] stringByDeletingPathExtension], [destinationPath pathExtension]]];
        }
        [self updateProgress];
    }
    return self;
}

- (void)dealloc {
    [_url release], _url = nil;
    [_destinationPath release], _destinationPath = nil;
    [_interimPath release], _interimPath = nil;
    [super dealloc];
}


#pragma mark Progress

- (void)updateProgress {
    [self willChangeValueForKey:@"finished"];
    [self willChangeValueForKey:@"progress"];
    
    struct stat st;
    if (0 == lstat([_destinationPath UTF8String], &st)) {
        _finished = YES;
        _progress = st.st_size;
    } else if (0 == lstat([_interimPath UTF8String], &st)) {
        _finished = NO;
        _progress = st.st_size;
    } else {
        _finished = NO;
        _progress = 0;
    }
    
    [self didChangeValueForKey:@"progress"];
    [self didChangeValueForKey:@"finished"];
}

- (void)setOperation:(NSOperation *)operation {
    if (_operation != operation) {
        [_operation removeObserver:self forKeyPath:@"isFinished"];
        [_operation removeObserver:self forKeyPath:@"progress"];
        [_operation release];
        _operation = [operation retain];
        [_operation addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
        [_operation addObserver:self forKeyPath:@"progress" options:0 context:nil];
        _operation.verbose = _verbose;
    }
}

- (NSOperation *)operation {
    if (_operation == nil) {
         self.operation = [[[SoloDownloadOperation alloc] initWithURL:_url path:_interimPath] autorelease];
    }
    return _operation;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isFinished"]) {
        if ([_operation isFinished] && !_finished) {
            if (_operation.error) {
                _lastError = [_operation.error retain];
            } else {
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtPath:_interimPath toPath:_destinationPath error:&error];
                _lastError = [error retain];
            }
            [self updateProgress];
        }
    } else if ([keyPath isEqualToString:@"progress"]) {
        [self updateProgress];
    }
}

@end


#pragma mark - SoloDownloadOperation


@interface SoloDownloadOperation ()

- (void)finish;

@end


@implementation SoloDownloadOperation

@synthesize verbose=_verbose;
@synthesize error=_error;

- (id)initWithURL:(NSURL *)url path:(NSString *)path {
    self = [super init];
    if (self) {
        _url = [url retain];
        _path = [path copy];
    }
    return self;
}

- (void)dealloc {
    [_url release], _url = nil;
    [_path release], _path = nil;
    [super dealloc];
}


#pragma mark Downloading

- (void)start {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        [self finish];
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:_url];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (_connection) {
        _receivedData = [[NSMutableData data] retain];
        NSLog(@"Connecting URL: %@", _url);
    } else {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Unable to establish connections" forKey:NSLocalizedDescriptionKey];
        _error = [NSError errorWithDomain:@"HTTP" code:100 userInfo:details];
        
        [self finish];
    }
}

- (void) finish {
    NSLog(@"operation for <%@> finished. "
          @"status code: error: %@, data size: %u",
          _url, _error, [_receivedData length]);
    
    [_receivedData release], _receivedData = nil;
    [_connection release], _connection = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isFinished = YES;
    _isExecuting = NO;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return _isExecuting;
}

- (BOOL)isFinished {
    return _isFinished;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (_verbose) {
        NSLog(@"- [SoloDownloadOperation didReceiveResponse] (%@)", _url);
    }
//    _filename = [[response suggestedFilename] retain];
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (_verbose) {
        NSLog(@"- [SoloDownloadOperation didReceiveData] - %u bytes (%@)", [data length], _url);
    }
    [_receivedData appendData:data];
    
    [self willChangeValueForKey:@"progress"];
    _progress += [data length];
    [self didChangeValueForKey:@"progress"];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (_verbose) {
        NSLog(@"- [SoloDownloadOperation didFailWithError] - %@ (%@)", [error description], _url);
    }
    [self willChangeValueForKey:@"isErrored"];
    _error = [error copy];
    [self didChangeValueForKey:@"isErrored"];
    [self finish];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (_verbose) {
        NSLog(@"SoloDownloadOperation finished: %llu bytes total (%@)", _progress, _url);
    }
    NSLog(@"Loading finished succesfully");
    NSLog(@"Saving file as: %@", _path);
    [_receivedData writeToFile:_path atomically:YES];
    [self finish];
}



@end
