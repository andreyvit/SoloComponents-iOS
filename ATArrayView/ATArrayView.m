//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "ATArrayView.h"


@interface ATArrayView () <UIScrollViewDelegate>
- (void)setup;
- (void)configureItems:(BOOL)updateExisting;
- (void)configureItem:(UIView *)item forIndex:(NSInteger)index;
- (void)recycleItem:(UIView *)item;

@end



@implementation ATArrayView

@synthesize delegate=_delegate;
@synthesize itemSize=_itemSize;
@synthesize contentInsets=_contentInsets;
@synthesize minimumColumnGap=_minimumColumnGap;
@synthesize scrollView=_scrollView;
@synthesize itemCount=_itemCount;
@synthesize preloadBuffer=_preloadBuffer;

#pragma mark -
#pragma mark init/dealloc

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setup];
    }
    return self;
}

- (void) awakeFromNib {
    [self setup];
}

/* Moving setup here, allows for ATArrayView to work with InterfaceBuilder since
awakeFromNib is called instead of initWithFrame */
-(void) setup {
    _visibleItems = [[NSMutableSet alloc] init];
    _recycledItems = [[NSMutableSet alloc] init];

    _itemSize = CGSizeMake(70, 70);
    _minimumColumnGap = 5;
    _preloadBuffer = 0;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.bounces = YES;
    _scrollView.delegate = self;
    [self addSubview:_scrollView];
}

- (void)dealloc {
    [_scrollView release], _scrollView = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Data

- (void)reloadData {
    _itemCount = [_delegate numberOfItemsInArrayView:self];

    // recycle all items
    for (UIView *view in _visibleItems) {
        [self recycleItem:view];
    }
    [_visibleItems removeAllObjects];

    [self configureItems:NO];
}


#pragma mark -
#pragma mark Item Views

- (UIView *)viewForItemAtIndex:(NSUInteger)index {
    for (UIView *item in _visibleItems)
        if (item.tag == index)
            return item;
    return nil;
}

- (void)configureItems:(BOOL)reconfigure {
    // update content size if needed
    CGSize contentSize = CGSizeMake(self.bounds.size.width,
                                    _itemSize.height * _rowCount + _rowGap * (_rowCount - 1) + _effectiveInsets.top + _effectiveInsets.bottom);
    if (_scrollView.contentSize.width != contentSize.width || _scrollView.contentSize.height != contentSize.height) {
        _scrollView.contentSize = contentSize;
    }

    // calculate which items are visible
    int firstItem = self.firstVisibleItemIndex;
    int lastItem  = self.lastVisibleItemIndex;

    // recycle items that are no longer visible
    for (UIView *item in _visibleItems) {
        if (item.tag < firstItem || item.tag > lastItem) {
            [self recycleItem:item];
        }
    }
    [_visibleItems minusSet:_recycledItems];

    if (lastItem < 0)
        return;

    // add missing items
    for (int index = firstItem; index <= lastItem; index++) {
        UIView *item = [self viewForItemAtIndex:index];
        if (item == nil) {
            item = [_delegate viewForItemInArrayView:self atIndex:index];
            [_scrollView addSubview:item];
            [_visibleItems addObject:item];
        } else if (!reconfigure) {
            continue;
        }
        [self configureItem:item forIndex:index];
    }
}

- (void)configureItem:(UIView *)item forIndex:(NSInteger)index {
    item.tag = index;
    item.frame = [self rectForItemAtIndex:index];
    [item setNeedsDisplay]; // just in case
}


#pragma mark -
#pragma mark Layouting

- (void)layoutSubviews {
    BOOL boundsChanged = !CGRectEqualToRect(_scrollView.frame, self.bounds);
    if (boundsChanged) {
        // Strangely enough, if we do this assignment every time without the above
        // check, bouncing will behave incorrectly.
        _scrollView.frame = self.bounds;
    }

    _colCount = floorf((self.bounds.size.width - _contentInsets.left - _contentInsets.right) / _itemSize.width);

    while (1) {
        _colGap = (self.bounds.size.width - _contentInsets.left - _contentInsets.right - _itemSize.width * _colCount) / (_colCount + 1);
        if (_colGap >= _minimumColumnGap)
            break;
        --_colCount;
    };

    _rowCount = (_itemCount + _colCount - 1) / _colCount;
    _rowGap = _colGap;

    _effectiveInsets = UIEdgeInsetsMake(_contentInsets.top + _rowGap,
                                        _contentInsets.left + _colGap,
                                        _contentInsets.bottom + _rowGap,
                                        _contentInsets.right + _colGap);

    [self configureItems:boundsChanged];
}

- (NSInteger)firstVisibleItemIndex {
    int firstRow = MAX(floorf((CGRectGetMinY(_scrollView.bounds) - _effectiveInsets.top) / (_itemSize.height + _rowGap)), 0);
    //return MIN( firstRow * _colCount, _itemCount - 1);
    //Formula changed to incorporate the 'preload' buffer functionality
    return MIN( MAX(0,firstRow - (_preloadBuffer)) * _colCount, _itemCount - 1);
}

- (NSInteger)lastVisibleItemIndex {
    int lastRow = MIN( ceilf((CGRectGetMaxY(_scrollView.bounds) - _effectiveInsets.top) / (_itemSize.height + _rowGap)), _rowCount - 1);
    //return MIN((lastRow + 1) * _colCount - 1, _itemCount - 1);
    return MIN((lastRow + (_preloadBuffer + 1)) * _colCount - 1, _itemCount - 1);
}

- (CGRect)rectForItemAtIndex:(NSUInteger)index {
    NSInteger row = index / _colCount;
    NSInteger col = index % _colCount;

    return CGRectMake(_effectiveInsets.left + (_itemSize.width  + _colGap) * col,
                      _effectiveInsets.top  + (_itemSize.height + _rowGap) * row,
                      _itemSize.width, _itemSize.height);
}


#pragma mark -
#pragma mark Recycling

// It's the caller's responsibility to remove this item from _visibleItems,
// since this method is often called while traversing _visibleItems array.
- (void)recycleItem:(UIView *)item {
    [_recycledItems addObject:item];
    [item removeFromSuperview];
}

- (UIView *)dequeueReusableItem {
    UIView *result = [_recycledItems anyObject];
    if (result) {
        [_recycledItems removeObject:[[result retain] autorelease]];
    }
    return result;
}


#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self configureItems:NO];
}

@end



#pragma mark -

@implementation ATArrayViewController


#pragma mark -
#pragma mark init/dealloc

- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark View Loading

- (void)loadView {
    self.view = [[[ATArrayView alloc] init] autorelease];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.arrayView.delegate == nil)
        self.arrayView.delegate = self;
}


#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    if (self.arrayView.itemCount == 0)
        [self.arrayView reloadData];
}


#pragma mark -
#pragma mark View Access

- (ATArrayView *)arrayView {
    return (ATArrayView *)self.view;
}


#pragma mark -
#pragma mark ATArrayViewDelegate methods

- (NSInteger)numberOfItemsInArrayView:(ATArrayView *)arrayView {
    return 0;
}

- (UIView *)viewForItemInArrayView:(ATArrayView *)arrayView atIndex:(NSInteger)index {
    return nil;
}

@end
