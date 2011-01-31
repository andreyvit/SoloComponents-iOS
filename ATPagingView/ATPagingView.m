//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "ATPagingView.h"


@interface ATPagingView () <UIScrollViewDelegate>

- (void)configurePages;
- (void)configurePage:(UIView *)page forIndex:(NSInteger)index;

- (CGRect)frameForScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;

- (void)recyclePage:(UIView *)page;

@end



@implementation ATPagingView

@synthesize delegate=_delegate;
@synthesize gapBetweenPages=_gapBetweenPages;
@synthesize pagesToPreload=_pagesToPreload;
@synthesize pageCount=_pageCount;
@synthesize currentPageIndex=_currentPageIndex;


#pragma mark -
#pragma mark init/dealloc

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_visiblePages = [[NSMutableSet alloc] init];
		_recycledPages = [[NSMutableSet alloc] init];
		_currentPageIndex = 0;
		_gapBetweenPages = 20.0;
		_pagesToPreload = 0;

		self.clipsToBounds = YES;

		_scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
		_scrollView.pagingEnabled = YES;
		_scrollView.backgroundColor = [UIColor blackColor];
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.bounces = YES;
		_scrollView.delegate = self;
		[self addSubview:_scrollView];
	}
	return self;
}

- (void)dealloc {
	[_scrollView release], _scrollView = nil;
	[super dealloc];
}


#pragma mark Properties

- (void)setGapBetweenPages:(CGFloat)value {
	_gapBetweenPages = value;
	[self setNeedsLayout];
}

- (void)setPagesToPreload:(NSInteger)value {
	_pagesToPreload = value;
	[self configurePages];
}


#pragma mark -
#pragma mark Data

- (void)reloadData {
	_pageCount = [_delegate numberOfPagesInPagingView:self];

	// recycle all pages
	for (UIView *view in _visiblePages) {
		[_recycledPages addObject:view];
		[view removeFromSuperview];
	}
	[_visiblePages removeAllObjects];

	[self configurePages];
}


#pragma mark -
#pragma mark Page Views

- (UIView *)viewForPageAtIndex:(NSUInteger)index {
    for (UIView *page in _visiblePages)
        if (page.tag == index)
            return page;
    return nil;
}

- (void)configurePages {
	if (_scrollView.frame.size.width == 0)
		return;  // not our time yet

	// normally layoutSubviews won't even call us, but protect against any other calls too (e.g. if someones does reloadPages)
	if (_rotationInProgress)
		return;

	CGSize contentSize = CGSizeMake(_scrollView.frame.size.width * _pageCount, _scrollView.frame.size.height);
	if (!CGSizeEqualToSize(_scrollView.contentSize, contentSize)) {
		_scrollView.contentSize = contentSize;
	}

    // calculate which pages are visible
    int firstPage = self.firstVisiblePageIndex;
    int lastPage  = self.lastVisiblePageIndex;

    // recycle no longer visible pages
    for (UIView *page in _visiblePages) {
        if (page.tag < firstPage || page.tag > lastPage) {
			[self recyclePage:page];
        }
    }
    [_visiblePages minusSet:_recycledPages];

    // add missing pages
    for (int index = firstPage; index <= lastPage; index++) {
        if ([self viewForPageAtIndex:index] == nil) {
			UIView *page = [_delegate viewForPageInPagingView:self atIndex:index];
            [self configurePage:page forIndex:index];
            [_scrollView addSubview:page];
            [_visiblePages addObject:page];
        }
    }

    CGRect visibleBounds = _scrollView.bounds;
	NSInteger newPageIndex = MIN(MAX(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)), 0), _pageCount - 1);
	if (newPageIndex != _currentPageIndex) {
		_currentPageIndex = newPageIndex;
		if ([_delegate respondsToSelector:@selector(currentPageDidChangeInPagingView:)])
			[_delegate currentPageDidChangeInPagingView:self];
		NSLog(@"_currentPageIndex == %d", _currentPageIndex);
	}
}

- (void)configurePage:(UIView *)page forIndex:(NSInteger)index {
    page.tag = index;
    page.frame = [self frameForPageAtIndex:index];
	[page setNeedsDisplay]; // just in case
}


#pragma mark -
#pragma mark Rotation

- (void)willAnimateRotation {
	_rotationInProgress = YES;

	// recycle non-current pages, otherwise they might show up during the rotation
	for (UIView *view in _visiblePages)
		if (view.tag != _currentPageIndex) {
			[self recyclePage:view];
		}
	[_visiblePages minusSet:_recycledPages];

	// we're inside an animation block, this has two consequences:
	//
	// 1) we need to resize the page view now (so that the size change is animated)
	//
	// 2) we cannot update the scroll view's contentOffset to align it with the new
	// page boundaries (since any such change will be animated in very funny ways)
	//
	// (note that the scroll view has already been resized by now)
	//
	// so we set the new size, but keep the old position here
	CGSize pageSize = _scrollView.frame.size;
	[self viewForPageAtIndex:_currentPageIndex].frame = CGRectMake(_scrollView.contentOffset.x, 0, pageSize.width - _gapBetweenPages, pageSize.height);
}

- (void)didRotate {
	// adjust frames according to the new page size - this does not cause any visible changes,
	// because we move the pages and adjust contentOffset simultaneously
	for (UIView *view in _visiblePages)
		[self configurePage:view forIndex:view.tag];
	_scrollView.contentOffset = CGPointMake(_currentPageIndex * _scrollView.frame.size.width, 0);

	_rotationInProgress = NO;

	[self configurePages];
}


#pragma mark -
#pragma mark Layouting

- (void)layoutSubviews {
	if (_rotationInProgress)
		return;

	CGRect oldFrame = _scrollView.frame;
	CGRect newFrame = [self frameForScrollView];
	if (!CGRectEqualToRect(oldFrame, newFrame)) {
		// Strangely enough, if we do this assignment every time without the above
		// check, bouncing will behave incorrectly.
		_scrollView.frame = newFrame;
	}

	if (oldFrame.size.width != 0 && _scrollView.frame.size.width != oldFrame.size.width) {
		// rotation is in progress, don't do any adjustments just yet
	} else if (oldFrame.size.height != _scrollView.frame.size.height) {
		// some other height change (the initial change from 0 to some specific size,
		// or maybe an in-call status bar has appeared or disappeared)
		[self configurePages];
	}
}

- (NSInteger)firstVisiblePageIndex {
    CGRect visibleBounds = _scrollView.bounds;
	return MAX(floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds)), 0);
}

- (NSInteger)lastVisiblePageIndex {
    CGRect visibleBounds = _scrollView.bounds;
	return MIN(floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds)), _pageCount - 1);
}

- (CGRect)frameForScrollView {
	CGSize size = self.bounds.size;
	return CGRectMake(-_gapBetweenPages/2, 0, size.width + _gapBetweenPages, size.height);
}

// not public because this is in scroll view coordinates
- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidthWithGap = _scrollView.frame.size.width;
	CGSize pageSize = self.bounds.size;

    return CGRectMake(pageWidthWithGap * index + _gapBetweenPages/2,
					  0, pageSize.width, pageSize.height);
}


#pragma mark -
#pragma mark Recycling

// It's the caller's responsibility to remove this page from _visiblePages,
// since this method is often called while traversing _visiblePages array.
- (void)recyclePage:(UIView *)page {
	[_recycledPages addObject:page];
	[page removeFromSuperview];
}

- (UIView *)dequeueReusablePage {
	UIView *result = [_recycledPages anyObject];
	if (result) {
		[_recycledPages removeObject:[[result retain] autorelease]];
	}
	return result;
}


#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (_rotationInProgress)
		return;
	[self configurePages];
}

@end



#pragma mark -

@implementation ATPagingViewController


#pragma mark -
#pragma mark init/dealloc

- (void)dealloc {
	[super dealloc];
}


#pragma mark -
#pragma mark View Loading

- (void)loadView {
	self.view = [[[ATPagingView alloc] init] autorelease];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (self.pagingView.delegate == nil)
		self.pagingView.delegate = self;
}


#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
	if (self.pagingView.pageCount == 0)
		[self.pagingView reloadData];
}


#pragma mark -
#pragma mark View Access

- (ATPagingView *)pagingView {
	return (ATPagingView *)self.view;
}


#pragma mark -
#pragma mark Rotation


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self.pagingView willAnimateRotation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.pagingView didRotate];
}


#pragma mark -
#pragma mark ATPagingViewDelegate methods

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView {
	return 0;
}

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index {
	return nil;
}

@end
