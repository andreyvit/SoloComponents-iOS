//
// SoloDownloader 0.1
// http://solo-components.com/
//
// Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//
#import "SoloDownloader.h"
#import <sys/stat.h>


static NSString *const JOB_STATE_NAMES[] = {@"NeverStarted", @"Paused", @"Running", @"Finished", @"Failed"};



@interface SoloDownloadJob (JobMethodsForQueue)

- (void)doStart;
- (void)doStop;

@end



#pragma mark SoloDownloadQueue

@interface SoloDownloadQueue ()

- (void)setRunningJob:(SoloDownloadJob *)job;
- (void)pickAnotherJobToRun;

@end

@implementation SoloDownloadQueue

@synthesize operationQueue=_operationQueue;
@synthesize runningJob=_runningJob;
@synthesize verbose=_verbose;


#pragma mark init/dealloc

- (id)init {
    self = [super init];
    if (self) {
        _waitingJobs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self setRunningJob:nil];
    [_waitingJobs release], _waitingJobs = nil;
    [super dealloc];
}


#pragma mark NSOperationQueue management

- (NSOperationQueue *)operationQueue {
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}


#pragma mark Scheduling

- (void)setRunningJob:(SoloDownloadJob *)job {
    if (_runningJob != job) {
        [_runningJob removeObserver:self forKeyPath:@"state"];
        [_runningJob release], _runningJob = nil;

        _runningJob = [job retain];
        [_runningJob addObserver:self forKeyPath:@"state" options:0 context:nil];
        if (_verbose && _runningJob) {
            NSLog(@"SoloDownloadQueue: starting job %@", [_runningJob description]);
        }
        [_runningJob doStart];
    }
}

- (void)scheduleJob:(SoloDownloadJob *)job {
    job.operationQueue = self.operationQueue;
    if (_runningJob == nil) {
        if (_verbose) {
            NSLog(@"SoloDownloadQueue: adding first job, will run immediately -- %@", [job description]);
        }
        [self setRunningJob:job];
    } else {
        if (_verbose) {
            NSLog(@"SoloDownloadQueue: adding job to waiting list -- %@", [job description]);
        }
        [_waitingJobs addObject:job];
    }
}

- (void)unscheduleJob:(SoloDownloadJob *)job {
    if (_runningJob == job) {
        if (_verbose) {
            NSLog(@"SoloDownloadQueue: unscheduling running job -- %@", [job description]);
        }
        [job doStop];
        [self pickAnotherJobToRun];
    } else {
        if (_verbose) {
            NSLog(@"SoloDownloadQueue: unscheduling waiting job -- %@", [job description]);
        }
        [_waitingJobs removeObject:job];
    }
}

- (void)pickAnotherJobToRun {
    if ([_waitingJobs count] > 0) {
        if (_verbose) {
            NSLog(@"SoloDownloadQueue: picking the first job (of %d) in the waiting list to run", [_waitingJobs count]);
        }
        SoloDownloadJob *job = [_waitingJobs objectAtIndex:0];
        [_waitingJobs removeObjectAtIndex:0];
        [self setRunningJob:job];
    } else {
        [self setRunningJob:nil];
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"state"]) {
        SoloDownloadJob *job = object;
        if (job == _runningJob && job.state != SoloDownloadJobStateRunning) {
            if (_verbose) {
                NSLog(@"SoloDownloadQueue: running job transitioned into state %@ -- %@", JOB_STATE_NAMES[job.state], [job description]);
            }
            [self pickAnotherJobToRun];
        }
    }
}

@end


#pragma mark - SoloDownloadJob


@interface SoloDownloadJob ()

- (void)computeInitialProgress;

- (void)startOperationForTask:(SoloDownloadTask *)task;

@end


@implementation SoloDownloadJob

@synthesize verbose=_verbose;
@synthesize operationQueue=_operationQueue;
@synthesize scheduler=_scheduler;
@synthesize tasks=_tasks;
@synthesize totalSize=_totalSize;
@synthesize lastError=_lastError;


#pragma mark init/dealloc

- (id)init {
    self = [super init];
    if (self) {
        _tasks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_operationQueue cancelAllOperations];
    [_operationQueue waitUntilAllOperationsAreFinished];
    [_operationQueue release], _operationQueue = nil;
    [_tasks release], _tasks = nil;
    [_lastError release], _lastError = nil;
    [super dealloc];
}


#pragma mark Progress

- (unsigned long long)currentSize {
    if (!_initialProgressComputed) {
        [self computeInitialProgress];
    }
    return _currentSize;
}

- (void)countInitialProgressForTask:(SoloDownloadTask *)task {
    _currentSize += task.progress;
    if (task.finished) {
        _tasksFinished++;
    }
}

- (void)computeInitialProgress {
    _currentSize = 0;

    for (SoloDownloadTask *task in _tasks) {
        [self countInitialProgressForTask:task];
    }

    _initialProgressComputed = YES;
}


#pragma mark State

- (BOOL)isRunning {
    return _tasksEnqueued > 0;
}

- (SoloDownloadJobState)state {
    if (!_initialProgressComputed) {
        [self computeInitialProgress];
    }
    if ([self isRunning]) {
        return SoloDownloadJobStateRunning;
    } else if (_lastError) {
        return SoloDownloadJobStateFailed;
    } else if (_tasksFinished >= [_tasks count]) {
        return SoloDownloadJobStateFinished;
    } else if (_currentSize > 0) {
        return SoloDownloadJobStatePaused;
    } else {
        return SoloDownloadJobStateNeverStarted;
    }
}


#pragma mark NSOperationQueue management

- (NSOperationQueue *)operationQueue {
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}


#pragma mark Task management

- (void)addTask:(SoloDownloadTask *)task {
    [_tasks addObject:task];
    if (_initialProgressComputed) {
        [self countInitialProgressForTask:task];
    }
    if ([self isRunning]) {
        [self startOperationForTask:task];
    }
}


#pragma mark Start/stop

- (void)start {
    if (_scheduler) {
        [_scheduler scheduleJob:self];
    } else {
        [self doStart];
    }
}

- (void)stop {
    if (_scheduler) {
        [_scheduler unscheduleJob:self];
    } else {
        [self doStop];
    }
}

- (void)doStart {
    if (_verbose) {
        NSLog(@"SoloDownloadJob(%p): starting", self);
    }
    if (!_initialProgressComputed) {
        [self computeInitialProgress];
    }
    if ([self isRunning]) {
        return;
    }
    [_lastError release], _lastError = nil;
    for (SoloDownloadTask *task in _tasks) {
        if (!task.finished) {
            [self startOperationForTask:task];
        }
    }
}

- (void)doStop {
    if (![self isRunning]) {
        return;
    }
    for (SoloDownloadTask *task in _tasks) {
        [task cancel];
    }
}


#pragma mark Task operations

- (void)startOperationForTask:(SoloDownloadTask *)task {
    [task addObserver:self forKeyPath:@"queued" options:NSKeyValueObservingOptionOld context:nil];
    [task addObserver:self forKeyPath:@"finished" options:NSKeyValueObservingOptionOld context:nil];
    [task addToQueue:self.operationQueue];
}

- (void)taskEnqueued:(SoloDownloadTask *)task {
    [self willChangeValueForKey:@"state"];
    _tasksEnqueued++;
    if (_verbose) {
        NSLog(@"SoloDownloadJob(%p): enqueued task %@", self, [task description]);
    }
    [self didChangeValueForKey:@"state"];
}

- (void)taskDequeued:(SoloDownloadTask *)task {
    [task removeObserver:self forKeyPath:@"queued"];
    [task removeObserver:self forKeyPath:@"finished"];

    [self willChangeValueForKey:@"state"];
    _tasksEnqueued--;

    if (_verbose) {
        NSLog(@"SoloDownloadJob(%p): dequeued task %@", self, [task description]);
    }

    if (task.lastError && _lastError == nil) {
        _lastError = [task.lastError retain];

        // cancel all tasks on failure
        for (SoloDownloadTask *task in _tasks) {
            [task cancel];
        }
    }
    [self didChangeValueForKey:@"state"];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"queued"]) {
        SoloDownloadTask *task = object;
        BOOL oldValue = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
        if (oldValue != task.queued)
            if (task.queued) {
                [self taskEnqueued:task];
            } else {
                [self taskDequeued:task];
            }

    } else if ([keyPath isEqualToString:@"finished"]) {
        SoloDownloadTask *task = object;
        [self willChangeValueForKey:@"state"];
        BOOL oldValue = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
        if (oldValue != task.finished)
            if (task.finished) {
                _tasksFinished++;
                if (_verbose) {
                    NSLog(@"SoloDownloadJob(%p): task finished %@", self, [task description]);
                }
            } else {
                _tasksFinished--;
                if (_verbose) {
                    NSLog(@"SoloDownloadJob(%p): task no longer finished %@", self, [task description]);
                }
            }
        [self didChangeValueForKey:@"state"];
    }
}

@end


#pragma mark - SoloDownloadTask


@interface SoloDownloadTask ()

- (void)updateProgress;

@property(nonatomic, retain) NSOperation *operation;

@end


@implementation SoloDownloadTask

@synthesize verbose=_verbose;

@synthesize url=_url;
@synthesize destinationPath=_destinationPath;
@synthesize interimPath=_interimPath;

@synthesize finished=_finished;
@synthesize queued=_queued;
@synthesize lastError=_lastError;
@synthesize progress=_progress;

- (id)initWithURL:(NSURL *)url destinationPath:(NSString *)destinationPath {
    return [self initWithURL:url destinationPath:destinationPath interimPath:nil];
}

- (id)initWithURL:(NSURL *)url destinationPath:(NSString *)destinationPath interimPath:(NSString *)interimPath {
    self = [super init];
    if (self) {
        _url = [url retain];
        _destinationPath = [destinationPath copy];
        if ([interimPath length]) {
            _interimPath = [interimPath copy];
        } else {
            _interimPath = [[[destinationPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"#%@#.%@", [[destinationPath lastPathComponent] stringByDeletingPathExtension], [destinationPath pathExtension]]] copy];
        }
        [self updateProgress];
    }
    return self;
}

- (void)dealloc {
    self.operation = nil;  // this class is not intended to be KVO-compliant for operation key, so this is safe
    [_url release], _url = nil;
    [_destinationPath release], _destinationPath = nil;
    [_interimPath release], _interimPath = nil;
    [super dealloc];
}


#pragma mark Debugging

- (NSString *)description {
    return [NSString stringWithFormat:@"SoloDownloadTask(%p%@, progress=%llu, %@)", self, (_finished ? @", FINISHED" : @""), _progress, [_destinationPath lastPathComponent]];
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


#pragma mark Operation management

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

- (void)addToQueue:(NSOperationQueue *)queue {
    if (_queued) {
        return;
    }
    [self willChangeValueForKey:@"queued"];
    [queue addOperation:self.operation];
    _queued = YES;
    [self didChangeValueForKey:@"queued"];
}

- (void)cancel {
    if (!_queued) {
        return;
    }
    [self willChangeValueForKey:@"queued"];
    [self.operation cancel];
    self.operation = nil;
    _queued = NO;
    [self didChangeValueForKey:@"queued"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isFinished"]) {
        if ([_operation isFinished] && !_finished) {
            if (_operation.error) {
                [_lastError release];
                _lastError = [_operation.error retain];
            } else {
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtPath:_interimPath toPath:_destinationPath error:&error];
                [_lastError release];
                _lastError = [error retain];
            }
            [self updateProgress];
            [self willChangeValueForKey:@"queued"];
            _queued = NO;
            self.operation = nil;
            [self didChangeValueForKey:@"queued"];
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
