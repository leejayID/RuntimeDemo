//
//  Archive.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/17.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#ifndef Archive_h
#define Archive_h

// 在需要归档的类的实现文件添加ArchiveImplementation，就可以实现一键归档
#define ArchiveImplementation \
- (id)initWithCoder:(NSCoder *)decoder \
{ \
if (self = [super init]) { \
[self decode:decoder]; \
} \
return self; \
} \
\
- (void)encodeWithCoder:(NSCoder *)encoder \
{ \
[self encode:encoder]; \
}

#endif /* Archive_h */
