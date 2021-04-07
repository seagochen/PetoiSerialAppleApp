//
//  StringBuffer.m
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/4/1.
//

#import "StringBuffer.h"

@interface StringBuffer ()
@property NSMutableArray* buffer;
@property NSLock* lock;
@end


@implementation StringBuffer

// MARK: 构造函数
- (id)init {
    if (self = [super init]) {
        // initialize mutable string array
        self.buffer = [[NSMutableArray alloc] init];
        
        // inititalize thread lock
        self.lock = [[NSLock alloc] init];
    }
    
    return self;
};


// MARK: 解构函数
- (void)dealloc {
    
    if (self.buffer != nil) {
        // release objc objects
        self.buffer = nil;
        self.lock = nil;
    }
};


- (void)push: (NSString*) str {
    if ([self.lock tryLock]) {
        if (str != nil) {
            [self.buffer addObject:str];
        }
    }
    
    [self.lock unlock];
};


- (NSString*) pop {
    if ([self.lock tryLock]) {
        
        if ([self size] > 0) {
            NSString* data = [self.buffer objectAtIndex: 0];
            [self.buffer removeObjectAtIndex: 0];
            
            [self.lock unlock];
            return data;
        }
    }
    
    [self.lock unlock];
    return nil;
};


- (NSString*) batchStr: (BOOL)clean {
    
    if ([self.lock tryLock]) {
        
        if (![self isEmpty]) {
            NSString* output = [[NSString alloc] init];
            
            for (NSString* str in self.buffer) {
                output = [output stringByAppendingString:str];
            }
            
            if (clean) {
                [self clear];
            }
            
            [self.lock unlock];
            return output;
        }
    }
    
    [self.lock unlock];
    return nil;
};


- (BOOL) isEmpty {
    return [self size] <= 0;
};


- (NSInteger) size {
    return [self.buffer count];
};


- (void)clear {
    if ([self.lock tryLock]) {
        [self.buffer removeAllObjects];
    }
    [self.lock unlock];
};

@end
