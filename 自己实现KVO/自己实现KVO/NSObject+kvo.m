//
//  NSObject+kvo.m
//  自己实现KVO
//
//  Created by zhoushnegjian on 2017/8/23.
//  Copyright © 2017年 zhoushengjian. All rights reserved.
//

#import "NSObject+kvo.h"
#import <objc/message.h>


@interface SJKVOInfo : NSObject

@property (nonatomic, weak) id observer;

@property (nonatomic, copy) NSString *keyPath;

@property (nonatomic, copy) CallBack observerBlcok;

@end

@implementation SJKVOInfo

+ (instancetype)sjKVOInfoWithObserver:(id)observer keyPath:(NSString *)key callBack:(CallBack)callBack {
    SJKVOInfo *info = [[SJKVOInfo alloc] init];
    
    info->_observer = observer;
    info->_keyPath = key;
    info->_observerBlcok = callBack;
    
    return info;
}

@end

static NSString *const kSJKVOPrefix = @"SJKVO_";
static NSString *const kSJKVOAssociatedObservers = @"SJKVOAssociatedObservers";

@implementation NSObject (kvo)

- (void)sj_addObserver:(id)observer forKeyPath:(NSString *)keyPath callBack:(CallBack)callBack {
    
    //1、检查有没有相关set方法
    SEL setterSelector = NSSelectorFromString([self setterForGetter:keyPath]);
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    
    if (!setterMethod) {
        NSLog(@"监听失败，keyPath没有对应的set方法");
        return;
    }
    
    //2、检查有没有kvo的子类，没有则动态注册一个
    Class clazz = object_getClass(self);
    NSString *className = NSStringFromClass(clazz);
    
    Class kvoClass = clazz;
    if (![className hasPrefix:kSJKVOPrefix]) {
        
        NSString *kvoClassName = [kSJKVOPrefix stringByAppendingString:className];
        kvoClass = NSClassFromString(kvoClassName);
        
        if (!kvoClass) {//不存在这个类 动态创建
            
            kvoClass = objc_allocateClassPair(object_getClass(self), kvoClassName.UTF8String, 0);
            
            //偷偷替换class方法  告诉大家 这个kvo子类就是原本的类
            IMP kvo_class_imp = class_getMethodImplementation(object_getClass(self), @selector(sjkvo_class));
            const char *typeEncoding = method_getTypeEncoding(class_getInstanceMethod(object_getClass(self), @selector(class)));
//            class_addMethod(kvoClass, @selector(class), kvo_class_imp, typeEncoding);
            class_replaceMethod(kvoClass, @selector(class), kvo_class_imp, typeEncoding);
            
            objc_registerClassPair(kvoClass);
            
        }
        
        //让当前对象isa指向新的kvo子类
        object_setClass(self, kvoClass);
        NSLog(@"%@", [self class]);
        
    }

    //尝试：根据获取到的类型  来提供不同的set方法（也许还有其他更好的方案）
//    objc_property_t property = class_getProperty(object_getClass(self), (const char *)keyPath.UTF8String);
//    //判断数据类型
//    bool isObj = propertyIsObject(property);
    
    //3、给新的kvo子类重写setter方法
    IMP kvo_setter_imp = class_getMethodImplementation([self class], @selector(kvo_setter:));
    class_replaceMethod(kvoClass, setterSelector, kvo_setter_imp, method_getTypeEncoding(setterMethod));
    
    
    //4、将当前的调用保存到数组
    SJKVOInfo *info = [SJKVOInfo sjKVOInfoWithObserver:observer keyPath:keyPath callBack:callBack];
    
    NSMutableArray *observerArray = objc_getAssociatedObject(self, (__bridge const void *)(kSJKVOAssociatedObservers));
    if (!observerArray) {
        observerArray = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kSJKVOAssociatedObservers), observerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observerArray addObject:info];
    
}


static bool propertyIsObject(objc_property_t property) {
    
    const char *type = property_getAttributes(property);
    
    NSString * typeString = [NSString stringWithUTF8String:type];
    NSArray * attributes = [typeString componentsSeparatedByString:@","];
    NSString * typeAttribute = [attributes objectAtIndex:0];
    NSString * propertyType = [typeAttribute substringWithRange:NSMakeRange(1, 1)];
    const char * rawPropertyType = [propertyType UTF8String];
    
    /**
    if (strcmp(rawPropertyType, @encode(float)) == 0) {
        //it's a float
        NSLog(@"---it's a float");
    } else if (strcmp(rawPropertyType, @encode(int)) == 0) {
        //it's an int
        NSLog(@"---it's a int");
    }else if (strcmp(rawPropertyType, @encode(double)) == 0) {
        NSLog(@"----");
    }else if (strcmp(rawPropertyType, @encode(NSInteger)) == 0) {
        NSLog(@"----");
    }
    else if (strcmp(rawPropertyType, @encode(id)) == 0) {
        //it's some sort of object
        NSLog(@"---it's a object");
    } else {
        // According to Apples Documentation you can determine the corresponding encoding values
        NSLog(@"---");
    } */
    
    return strcmp(rawPropertyType, @encode(id)) == 0;
}

- (NSString *)setterForGetter:(NSString *)key {
    NSString *subStr = [key substringToIndex:1];
    key = [NSString stringWithFormat:@"set%@%@:", subStr.uppercaseString, [key substringFromIndex:1]];
    return key;
}

- (NSString *)getterForSetter:(NSString *)key {
    key = [key stringByReplacingOccurrencesOfString:@":" withString:@""];
    NSString *getterStr = [key substringFromIndex:3];
    NSString *subStr = [getterStr substringToIndex:1];
    return [subStr.lowercaseString stringByAppendingString:[getterStr substringFromIndex:1]];
}

- (Class)sjkvo_class {
    return class_getSuperclass(object_getClass(self));
}

//static void KVO_Setter(id self, SEL _cmd, id newValue) {
//    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kSJKVOAssociatedObservers));
//    NSArray *safeArray = [observers copy];
//    
//    
//}

- (void)kvo_setter:(id)newValue {
    
    NSString *setter = NSStringFromSelector(_cmd);
    NSString *getter = [self getterForSetter:setter];
    id oldValue = [self valueForKey:getter];
    
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void*)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);
    
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kSJKVOAssociatedObservers));
    NSArray *safeArray = [observers copy];
    
    for (SJKVOInfo *info in safeArray) {
        if ([info.keyPath isEqualToString:getter]) {
            info.observerBlcok(self, getter, oldValue, newValue);
        }
    }
    
}

- (void)kvo_doubleSetter:(double)newValue {
    NSString *setter = NSStringFromSelector(_cmd);
    NSString *getter = [self getterForSetter:setter];
    id oldValue = [self valueForKey:getter];
    
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    void (*objc_msgSendSuperCasted)(void *, SEL, double) = (void*)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);
    
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kSJKVOAssociatedObservers));
    NSArray *safeArray = [observers copy];
    
    for (SJKVOInfo *info in safeArray) {
        if ([info.keyPath isEqualToString:getter]) {
            info.observerBlcok(self, getter, oldValue, @(newValue));
        }
    }
}


@end

