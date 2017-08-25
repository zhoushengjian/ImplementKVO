//
//  NSObject+kvo.h
//  自己实现KVO
//
//  Created by zhoushnegjian on 2017/8/23.
//  Copyright © 2017年 zhoushengjian. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CallBack)(id observedObj, NSString *keyPath, id oldValue, id newValue);

@interface NSObject (kvo)

- (void)sj_addObserver:(id)observer forKeyPath:(NSString *)keyPath callBack:(CallBack)callBack;

@end
