//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import <QuartzCore/QuartzCore.h>  // for self.layer.smt

#import "DemoItemView.h"


@implementation DemoItemView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.layer.cornerRadius = 8;
        self.layer.borderColor = [[UIColor redColor] CGColor];
        self.layer.borderWidth = 1;
        self.layer.backgroundColor = [[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] CGColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGSize size = self.bounds.size;

    NSString *label = [NSString stringWithFormat:@"%02d", self.tag];
    UIFont *font = [UIFont boldSystemFontOfSize:17];

    CGSize textSize = [label sizeWithFont:font];

    [[UIColor redColor] set];
    [label drawAtPoint:CGPointMake((size.width - textSize.width) / 2,
                                   (size.height - textSize.height) / 2) withFont:font];
}


@end
