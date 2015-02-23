//
//  HPLTagCloudGenerator.m
//  Awkward
//
//  Created by Matthew Conlen on 5/8/13.
//  Copyright (c) 2013 Huffington Post Labs. All rights reserved.
//

#import "HPLTagCloudGenerator.h"
#import <math.h>

#define kFontSize 60.0

@implementation HPLTagCloudTag

+ (HPLTagCloudTag *)tagWithSize:(CGSize)size center:(CGPoint)center scale:(float)scale {
  return [[HPLTagCloudTag alloc] initWithSize:size center:(CGPoint)center scale:scale];
}

- (instancetype)initWithSize:(CGSize)size center:(CGPoint)center scale:(float)scale {
  if (self = [super init]) {
    _size = size;
    _center = center;
    _scale = scale;
  }
  return self;
}

@end

@interface HPLTagCloudGenerator () {
    int spiralCount;
}

@end

@implementation HPLTagCloudGenerator

- (id) init {
    self = [super init];
    spiralCount = 0;
    self.spiralStep = 0.35;
    self.a = 5;
    self.b = 6;
    return self;
}

- (CGPoint) getNextPosition {

    float angle = self.spiralStep * spiralCount++;

    float offsetX = self.size.width/2;
    float offsetY = self.size.height/2;
    int x = (self.a + self.b*angle)*cos(angle);
    int y = (self.a + self.b*angle)*sin(angle);

    return CGPointMake(x+offsetX,y+offsetY);
}

- (BOOL) checkIntersectionWithFrame:(CGRect)checkFrame tagArray:(NSArray*)tagArray {
    for (HPLTagCloudTag *value in tagArray) {
        CGRect frame = CGRectMake(value.center.x - value.size.width / 2, value.center.y - value.size.height / 2, value.size.width, value.size.height);
        if (CGRectIntersectsRect(checkFrame, frame)) {
            return YES;
        }
    }
    return NO;
}

- (NSDictionary *)updateViews:(NSDictionary *)oldViews inView:(UIView *)view withTags:(NSDictionary *)tags animate:(BOOL)animate {
  NSMutableDictionary *newViews = [NSMutableDictionary dictionary];
  for (NSString *tagKey in tags) {
    HPLTagCloudTag *tag = [tags objectForKey:tagKey];
    
    UILabel *label = [oldViews objectForKey:tagKey];
    
    if (!label) {
      label = [[UILabel alloc] initWithFrame:CGRectZero];
      label.text = tagKey;
      label.font = [UIFont systemFontOfSize:kFontSize];
      label.transform = CGAffineTransformMakeScale(0.0, 0.0);
      label.center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
      [view addSubview:label];
    }

    if (animate) {
      [UIView animateWithDuration:0.5 animations:^{
        [self setLabelPosition:label tag:tag];
      }];
    } else {
        [self setLabelPosition:label tag:tag];
    }
    
    [newViews setObject:label forKey:tagKey];
  }
  
  for (NSString *tagKey in oldViews) {
    if (!newViews[tagKey]) {
      UILabel *oldView = oldViews[tagKey];
      if (animate) {
        [UIView animateWithDuration:0.5 animations:^{
          oldView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        } completion:^(BOOL finished) {
          [oldView removeFromSuperview];
        }];
      } else {
        [oldView removeFromSuperview];
      }
    }
  }
  
  return newViews;
}

- (void)setLabelPosition:(UILabel *)label tag:(HPLTagCloudTag *)tag {
  label.center = tag.center;
  label.bounds = CGRectMake(0, 0, tag.size.width, tag.size.height);
  label.transform = CGAffineTransformMakeScale(tag.scale, tag.scale);
}

- (NSDictionary *)generateTags {
    NSMutableDictionary *smoothedTagDict = [NSMutableDictionary dictionaryWithDictionary:self.tagDict];

    NSMutableDictionary *tags = [NSMutableDictionary dictionary];

    NSArray *sortedTags = [self.tagDict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int v1 = [obj1 intValue];
        int v2 = [obj2 intValue];
        if (v1 > v2)
            return NSOrderedAscending;
        else if (v1 < v2)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];

    // Smooth the Values
    // Artifically ensure that the count of any tags is always distinct...
    //
    //
    // e.g.
    //      tag1 ~> 1
    //      tag2 ~> 1
    //      tag3 ~> 1
    //      tag4 ~> 1
    //
    // becomes
    //      tag1 ~> 1
    //      tag2 ~> 2
    //      tag3 ~> 3
    //      tag4 ~> 4
    //
    // so that things look nicer

    for(long i=[sortedTags count]-1; i>0; i--) {
        int curVal = [(NSNumber *) [smoothedTagDict objectForKey:[sortedTags objectAtIndex:i]] intValue];
        int nextVal = [(NSNumber *) [smoothedTagDict objectForKey:[sortedTags objectAtIndex:i-1]] intValue];

        if(nextVal <= curVal) {
            nextVal = curVal+1;
            [smoothedTagDict setValue:[NSNumber numberWithInt:nextVal] forKey:[sortedTags objectAtIndex:i-1]];
        }
    }

    int max = [(NSNumber *) [smoothedTagDict objectForKey:[sortedTags objectAtIndex:0]] intValue];
    int min = [(NSNumber *) [smoothedTagDict objectForKey:[sortedTags objectAtIndex:[sortedTags count]-1]] intValue];
    min--;

    CGFloat maxWidth = [[UIScreen mainScreen] bounds].size.width / 3.0;
    UIFont *baseFont = [UIFont systemFontOfSize:kFontSize];

    for (NSString *tag in sortedTags) {
        int count = [(NSNumber *) [smoothedTagDict objectForKey:tag] intValue];

        float displayWidth = maxWidth * 0.1 + (maxWidth * 0.9) * (count - min) / (max - min);
        CGSize unscaledSize = [tag sizeWithAttributes:@{NSFontAttributeName: baseFont}];
        float scale = displayWidth / unscaledSize.width;
        float height = displayWidth * (unscaledSize.height / unscaledSize.width);
      
        // check intersections
        CGPoint center = [self getNextPosition];
        CGRect frame = CGRectMake(center.x - displayWidth / 2, center.y - height / 2, displayWidth, height);

        while ([self checkIntersectionWithFrame:frame tagArray:[tags allValues]]) {
            center = [self getNextPosition];
            frame = CGRectMake(center.x - displayWidth / 2, center.y - height / 2, displayWidth, height);
        }

        [tags setObject:[HPLTagCloudTag tagWithSize:CGSizeMake(unscaledSize.width, unscaledSize.height) center:center scale:scale] forKey:tag];
    }

    return tags;
}

- (NSArray *)generateTagViews {
  NSDictionary *tags = [self generateTags];
  NSMutableArray *views = [NSMutableArray arrayWithCapacity:tags.count];
  for (NSString *tagKey in tags) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    HPLTagCloudTag *tag = tags[tagKey];
    label.text = tagKey;
    label.font = [UIFont systemFontOfSize:kFontSize];
    label.transform = CGAffineTransformMakeScale(tag.scale, tag.scale);
    label.bounds = CGRectMake(0, 0, tag.size.width, tag.size.height);
    label.center = tag.center;
    [views addObject:label];
  }
  return [views copy];
}

@end
