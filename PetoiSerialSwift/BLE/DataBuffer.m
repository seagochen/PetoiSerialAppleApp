//
//  DataBuffer.m
//  ObjectiveApp
//
//  Created by Orlando Chen on 2021/3/25.
//

#import "DataBuffer.h"
#import "Converter.h"


@interface DataBuffer()
@property unsigned char* buffer;
@property NSMutableArray* tokens;
@property NSInteger header;
@property NSInteger capacity;
@property NSLock*   lock;
@end


@implementation DataBuffer

- (id)init
{
    if (self = [super init]) {
        [self realloc: 1024];
        
        // inititalize thread lock
        self.lock = [[NSLock alloc] init];
    }
    
    return self;
};


- (id)initWithCapacity: (NSInteger)capacity
{
    if (self = [super init]) {
        [self realloc: capacity];
        
        // inititalize thread lock
        self.lock = [[NSLock alloc] init];
    }
    
    return self;
};


- (void)dealloc
{
    if (self.buffer != nil) {
        free(self.buffer);
        
        // release objc objects
        self.buffer = nil;
        self.lock = nil;
        self.tokens = nil;
    }
};


- (void)realloc: (NSInteger) capacity
{
    if (self.buffer == nil) {
        self.buffer = malloc(capacity);
        self.header = 0; // 创建新的空间时，自动指向0
        
    } else {
        unsigned char* temp = calloc(capacity, sizeof(unsigned char));
        
        // copy buffer to temp
        memcpy(temp, self.buffer, self.header);
        
        // free buffer
        free(self.buffer);
        
        // point buffer ptr to temp
        self.buffer = temp;
    }
    
    if (self.tokens == nil) {
        self.tokens = [[NSMutableArray alloc] init];
    }
    
    self.capacity = capacity;
};


- (NSInteger)getOptimizedSize: (NSInteger)size
{
    float remainder = size;
    NSInteger exponential = 0;
    
    while(remainder > 1.f) {
        remainder = (float)remainder / 2.0f;
        exponential += 1;
    }
    
    double final = pow(2, exponential);
    return (NSInteger) final;
};


- (NSInteger)writeToBuffer: (NSData*)data
{
    NSInteger size = 0;
    NSInteger reset = self.capacity - self.header;
    
    // get bytes from nsdata
    unsigned char* bytes = [Converter cvtDataToCBytes:data length:&size];
    
    if (size >= 0 && reset > size) { // 正常情况
        
        // 写入数据
        memcpy(self.buffer + self.header, bytes, size);
        self.header += size;
        
    } else { // 需要写入的数据大于了可以存储的空间
        
        // 重新创建一个合适的数据空间
        NSInteger newCap = [self getOptimizedSize: self.header + size];
        [self realloc: newCap];
        
        // 写入数据
        memcpy(self.buffer + self.header, bytes, size);
        self.header += size;
    }
    
    // 返回成功写入的字节数
    return size;
}


- (NSInteger)getRestSize
{
    return self.capacity - self.header;
};


- (NSData*)getBuffer
{
    return [Converter cvtCBytesToData:self.buffer length:self.header];
};


- (NSInteger)getBufferSize
{
    return self.capacity;
};


- (NSInteger)nextTokenStartPos
{
    NSInteger backslash_r = 13; // \r
    NSInteger backslash_n = 10; // \n
    
    for (NSInteger i = 0; i < self.header - 1; i++) { // to avoid out of range
        if (self.buffer[i] == backslash_r &&
            self.buffer[i+1] == backslash_n) {
            return i + 2;
        }
    }
    
    return -1;
}

- (void)overallMove: (NSInteger)offset
{
    for (NSInteger i = 0; i < self.header - offset; i++) {
        self.buffer[i] = self.buffer[offset + i];
    }
    
    self.header -= offset;
};


- (BOOL)isString: (NSData*)data
{
    // nil ptr
    if (data == nil) return false;
    
    // empty bytes
    if ([data length] < 0) return false;
    
    NSInteger len = 0;
    unsigned char* bytes = [Converter cvtDataToCBytes:data length: &len];
    for (int i = 0; i < len; i++) {
        if (bytes[i] < 9 || bytes[i] >= 127) return false;
    }
    
    return true;
}


+ (void)print: (NSData*)data
{
    if ([data length] > 0) {
        NSInteger len = 0;
        unsigned char* buf = [Converter cvtDataToCBytes:data length:&len];
        
        for (int i = 0; i < len; i++) {
            //unsigned char debug = buf[i];
            
            if (buf[i] >= 32 && buf[i] < 127) {
                printf("%c ", buf[i]);
            } else {
                switch (buf[i]) {
                    case 0:
                        printf("\\0");
                        break;
                        
                    case 9: // blank
                        printf("\\t "); // horizontal tab
                        break;
                    
                    case 10:
                        printf("\\n "); // new line
                        break;
                    
                    case 11:
                        printf("\\v "); // vertical tab
                        break;
                        
                    case 12:
                        printf("\\f "); // new page
                        break;
                        
                    case 13:
                        printf("\\r "); // carriage return
                        break;
                        
                    default:
                        printf("%d ", buf[i]);
                        break;
                }
            }
        }
        printf("\n");
    }
};


- (NSInteger)getTokenSize {
    return [self.tokens count];
}


// MARK: 清空操作s
- (void)empty {
    [self.tokens removeAllObjects];
    [self realloc:self.capacity];
};

- (void)appendData: (NSData*)data
{
    if (! [self isString:data]) return;

    printf("----------------data------------------\n");
    [DataBuffer print: data];
    printf("--------------------------------------\n");
    
    if ([self.lock tryLock])
    {
        // 将数据写入缓冲
        [self writeToBuffer:data];

        // 持续扫描，直到返回的数值为 -1
        while (true) {
            // 从数据中抓取token结尾，这里的结尾定义默认为\r\n
            NSInteger tailer = [self nextTokenStartPos];

            if (tailer == -1) break;

            // 找到了完整的数据位，将数据从buffer中拷贝出来
            NSData* token = [Converter cvtCBytesToData:self.buffer length:tailer];

            printf("---------------token------------------\n");
            [DataBuffer print: token];
            printf("--------------------------------------\n");

            // 把数据写入MutableArray
            [self.tokens insertObject:token atIndex:0];
//            [self.tokens addObject:token];

            // 然后将buffer中的剩余数据拷贝到0号位
            [self overallMove:tailer];
        }
    }
    
    [self.lock unlock];
}


- (NSData*)tryGetToken
{
    if ([self.lock tryLock]) {
        
        if ([self.tokens count] > 0) {
            NSData* data = [self.tokens lastObject];
            [self.tokens removeLastObject];
            
            [self.lock unlock];
            return data;
        }
    }
    
    [self.lock unlock];

    return nil;
};

@end
