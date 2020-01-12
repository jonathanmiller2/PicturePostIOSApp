//
//  UIColor+PPColors.m
//  Picture Post
//
//  Created by Ilya Atkin on 9/17/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "UIColor+PPColors.h"

@implementation UIColor (PPColors)

+ (UIColor*)ppDarkGreenColor {
    static UIColor* color;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithHue:(120.0/360) saturation:0.3 brightness:0.4 alpha:1];
    });
    
    return color;
}

+ (UIColor*)ppMediumGreenColor {
    static UIColor* color;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithHue:(120.0/360) saturation:0.125 brightness:1 alpha:1];
    });
    
    return color;
}

+ (UIColor*)ppLightGreenColor {
    static UIColor* color;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithHue:(120.0/360) saturation:0.0625 brightness:1 alpha:1];
    });
    
    return color;
}

+ (UIColor*)ppVeryLightGreenColor {
    static UIColor* color;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithHue:(120.0/360) saturation:0.03125 brightness:1 alpha:1];
    });
    
    return color;
}

+ (UIColor*)ppUnuploadedColor {
    return [self ppDarkGreenColor];
}

+ (UIColor*)ppUploadedColor {
    static UIColor* color;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithHue:(230.0/360) saturation:0.33 brightness:0.79 alpha:1];
    });
    
    return color;
}

+ (UIColor*)ppUploadingColor {
    static UIColor* color;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithHue:(176.0/360) saturation:.1 brightness:.9 alpha:1];
    });
    
    return color;
}

@end
