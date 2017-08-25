//
//  Car.m
//  自己实现KVO
//
//  Created by zhoushnegjian on 2017/8/23.
//  Copyright © 2017年 zhoushengjian. All rights reserved.
//

#import "Car.h"

@interface Car ()

@property (nonatomic, strong) NSNumber *number;


@end

@implementation Car

- (void)dealloc {
    NSLog(@"♻️ Dealloc %@", NSStringFromClass([self class]));
}

- (void)sumNumber {
    self.number = @([self.number intValue]+123);
}

@end
