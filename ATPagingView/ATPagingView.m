//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "ATPagingView.h"


@interface ATPagingView () <UIScrollViewDelegate>

- (void)layoutPages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (void)recycleAllPages;
- (void)configureScrollView;
- (void)configurePage:(UIView *)page forIndex:(NSInteger)index;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;

@end



@implementation ATPagingView

@synthesize delegate=_delegate;
@synthesize gapBetweenPages=_gapBetweenPages;
@synthesize pagesToPreload=_pagesToPreload;
@synthesize pageCount=_pageCount;


#pragma mark -
#pragma mark init/dealloc

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_visiblePages = [[NSMutableSet alloc] init];
		_recycledPages = [[NSMutableSet alloc] init];

		self.clipsToBounds = YES;

		_scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
		_scrollView.pagingEnabled = YES;
		_scrollView.backgroundColor = [UIColor blackColor];
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.bounces = YES;
		_scrollView.delegate = self;
		[self addSubview:_scrollView];

		_gapBetweenPages = 20.0;
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
	[self layoutPages];
}


#pragma mark -
#pragma mark (Re)Loading

- (void)reloadRows {
	_pageCount = [_delegate numberOfPagesInPagingView:self];
//	[self configureScrollView];
	[self recycleAllPages];
	[self layoutPages];
}


#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
	CGSize size = self.bounds.size;
	CGRect scrollViewFrame = CGRectMake(-_gapBetweenPages/2, 0, size.width + _gapBetweenPages, size.height);
	if (_scrollView.frame.size.width != scrollViewFrame.size.width || _scrollView.frame.size.height != scrollViewFrame.size.height) {
		_scrollView.frame = scrollViewFrame;
		[self configureScrollView];
	}
	[self layoutPages];
}

- (void)layoutPages {
    // calculate which pages are visible
    CGRect visibleBounds = _scrollView.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, _pageCount - 1);

    // recycle no longer visible pages
    for (UIView *page in _visiblePages) {
        if (page.tag < firstNeededPageIndex || page.tag > lastNeededPageIndex) {
            [_recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [_visiblePages minusSet:_recycledPages];

    // add missing pages
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
			UIView *page = [_delegate viewForPageInPagingView:self atIndex:index];
            [self configurePage:page forIndex:index];
            [_scrollView addSubview:page];
            [_visiblePages addObject:page];
        }
    }
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    for (UIView *page in _visiblePages)
        if (page.tag == index)
            return YES;
    return NO;
}

// should be called when the number of rows or the scroll view frame changes
- (void)configureScrollView {
	if (_scrollView.frame.size.width == 0)
		return;  // not our time yet
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _pageCount, _scrollView.frame.size.height);
	_scrollView.contentOffset = CGPointZero;
}

- (void)configurePage:(UIView *)page forIndex:(NSInteger)index {
    page.tag = index;
    page.frame = [self frameForPageAtIndex:index];
	[page setNeedsDisplay]; // just in case
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidthWithGap = _scrollView.frame.size.width;
	CGSize pageSize = self.bounds.size;

    return CGRectMake(pageWidthWithGap * index + _gapBetweenPages/2,
					  0, pageSize.width, pageSize.height);
}


#pragma mark -
#pragma mark Recycling

- (void)recycleAllPages {
	for (UIView *view in _visiblePages) {
		[_recycledPages addObject:view];
		[view removeFromSuperview];
	}
	[_visiblePages removeAllObjects];
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
	[self layoutPages];
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
		[self.pagingView reloadRows];
}


#pragma mark -
#pragma mark View Access

- (ATPagingView *)pagingView {
	return (ATPagingView *)self.view;
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
