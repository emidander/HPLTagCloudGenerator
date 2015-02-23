//
//  HPLTagCloudGenerator.h
//  Awkward
//
//  Created by Matthew Conlen on 5/8/13.
//  Copyright (c) 2013 Huffington Post Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HPLTagCloudTag : NSObject
+ (HPLTagCloudTag *)tagWithSize:(CGSize)size center:(CGPoint)center scale:(float)scale;
- (instancetype)initWithSize:(CGSize)size center:(CGPoint)center scale:(float)scale;

@property (nonatomic) CGSize size;
@property (nonatomic) CGPoint center;
@property (nonatomic) float scale;
@end

@interface HPLTagCloudGenerator : NSObject


// Dictionary of tags -> # of occurances
@property NSDictionary *tagDict;

// The size of the view that
// we are creating a tag cloud for
@property CGSize size;

// How far along the spiral do
// we increment each time.
// defaults to 0.35
@property float spiralStep;

// The spiral is defined
// by the equation
//
// r = a + b*Θ
//
// where Θ is the angle
//
@property float a;
@property float b;


// Returns a dictionary with tags. Safe to call from any thread.
- (NSDictionary *)generateTags;

// Create or update tag views.
- (NSDictionary *)updateViews:(NSDictionary *)oldViews inView:(UIView *)view withTags:(NSDictionary *)tags animate:(BOOL)animate;

@end
