//
//  ViewController.m
//  自己实现KVO
//
//  Created by zhoushnegjian on 2017/8/23.
//  Copyright © 2017年 zhoushengjian. All rights reserved.
//

#import "ViewController.h"
#import "Car.h"
#import "Truck.h"
#import "NSObject+kvo.h"
#import <objc/message.h>

@interface ViewController ()

@end

@implementation ViewController {
    Car *_car;
    Truck *_truck;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _car = [Car new];
    _truck = [Truck new];
    
    //同一属性添加两次 kvo 会收到两次监听回调
//    [_car addObserver:self forKeyPath:@"speed" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
//    [_car addObserver:self forKeyPath:@"speed" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];


    
//    [_car sj_addObserver:self forKeyPath:@"speed" callBack:^(id observedObj, NSString *keyPath, id oldValue, id newValue) {
//        NSLog(@"old:%@---new:%@", oldValue, newValue);
//    }];
    
    [_truck sj_addObserver:self forKeyPath:@"number" callBack:^(id observedObj, NSString *keyPath, id oldValue, id newValue) {
        NSLog(@"old:%@---new:%@", oldValue, newValue);
    }];
    
    
}

- (void)dealloc {
    
    //注：添加一次，移除两次会报错（移除一个未被监听的keyPath的观察）
//    [_car removeObserver:self forKeyPath:@"speed"];
//    [_car removeObserver:self forKeyPath:@"speed"];
    
    NSLog(@"♻️ Dealloc %@", NSStringFromClass([self class]));
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    _car.speed += 23;
    
    [_truck sumNumber];
    
//    _truck.speed += 23;
    
//    _car.number = @([_car.number intValue]+123);
//    [_car sumNumber];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"speed"]) {
        NSLog(@"====%@", object);
        NSLog(@"****%@", change);
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
