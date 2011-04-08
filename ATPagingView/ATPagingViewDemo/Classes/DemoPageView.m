//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "DemoPageView.h"


@implementation DemoPageView


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGSize size = self.bounds.size;

    [[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] set];
    UIRectFill(rect);

    CGContextRef context = UIGraphicsGetCurrentContext();

    // "\"
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, size.width, size.height);

    // "/"
    CGContextMoveToPoint(context, 0, size.height);
    CGContextAddLineToPoint(context, size.width, 0);

    CGContextAddRect(context, rect);

    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextStrokePath(context);

    [[UIColor redColor] set];
    CGRect textRect = self.bounds;
    textRect.origin.y += textRect.size.height / 3;
    [[NSString stringWithFormat:@"Page %d", self.tag] drawInRect:textRect withFont:[UIFont boldSystemFontOfSize:17] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
}

- (void)dealloc {
    [super dealloc];
}


@end
