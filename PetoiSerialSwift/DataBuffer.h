//
//  DataBuffer.h
//  ObjectiveApp
//
//  Created by Orlando Chen on 2021/3/25.
//

#ifndef DataBuffer_h
#define DataBuffer_h

#import <Foundation/Foundation.h>

@interface DataBuffer : NSObject

// MARK: 构造函数
- (id)init;

// MARK: 构造函数
- (id)initWithCapacity: (NSInteger)capacity;

// MARK: 解构函数
- (void)dealloc;

// MARK: 给buffer增加数据
- (void)appendData: (NSData*)data;

// MARK: 获取存储数据缓存的指针
- (NSData*)getBuffer;

// MARK: 获取存储数据缓存的大小
- (NSInteger)getBufferSize;

// MARK: 存储数据缓存还可以使用的有效空间
- (NSInteger)getRestSize;

// MARK: 尝试从缓存中读取可用的数据
- (NSData*)tryGetToken;

// MARK: 测试使用，把bytes打印成数值的方法
+ (void)print: (NSData*)data;

@end


#endif /* DataBuffer_h */
