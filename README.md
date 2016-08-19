# Objective-C中的Runtime

## 前言
Runtime是一套比较底层的纯C语言API，包含了很多底层的C语言API。在我们平时编写的OC代码中，程序运行时，其实最终都是转成了Runtime的C语言代码。Runtime是开源的，你可以去[这里](http://opensource.apple.com/tarballs/objc4/)下载Runtime的源码。
本文主要分为两个章节，第一部分主要是理论和原理，第二部分主要是使用实例。简书文章[地址](http://www.jianshu.com/p/3e050ec3b759)，CSDN文章[地址](http://blog.csdn.net/leejay_carson/article/details/52239246)。文章的最后会附上本文的demo下载链接。
## 理论知识
### 一、Objective-C中的数据结构
描述Objective-C对象所有的数据结构定义都在Runtime的头文件里，下面我们逐一分析。
#### 1.id
运行期系统如何知道某个对象的类型呢？对象类型并不是在编译期就知道了，而是要在运行期查找。Objective-C有个特殊的类型id，它可以表示Objective-C的任意对象类型，id类型定义在Runtime的头文件中：
```objc
struct objc_object {
    Class isa;
} *id;
```
> 由此可见，每个对象结构体的首个成员是Class类的变量。该变量定义了对象所属的类，通常称为isa指针。

#### 2.Class
Class对象也定义在Runtime的头文件中：
```objc
typedef struct objc_class *Class;
struct objc_class { 
    Class isa                                 OBJC_ISA_AVAILABILITY; 
#if !__OBJC2__
    Class super_class                         OBJC2_UNAVAILABLE; 
    const char *name                          OBJC2_UNAVAILABLE;
    long version                              OBJC2_UNAVAILABLE; 
    long info                                 OBJC2_UNAVAILABLE; 
    long instance_size                        OBJC2_UNAVAILABLE; 
    struct objc_ivar_list *ivars              OBJC2_UNAVAILABLE; 
    struct objc_method_list **methodLists     OBJC2_UNAVAILABLE;
    struct objc_cache *cache                  OBJC2_UNAVAILABLE; 
    struct objc_protocol_list *protocols      OBJC2_UNAVAILABLE; 
#endif
}
```
下面说下Class的结构体中的几个主要变量：
* 1.isa：
结构体的首个变量也是isa指针，这说明Class本身也是Objective-C中的对象。
* 2.super_class：
结构体里还有个变量是super_class，它定义了本类的超类。类对象所属类型（isa指针所指向的类型）是另外一个类，叫做“元类”。
* 3.ivars：
成员变量列表，类的成员变量都在ivars里面。
* 4.methodLists：
方法列表，类的实例方法都在methodLists里，类方法在元类的methodLists里面。methodLists是一个指针的指针，通过修改该指针指向指针的值，就可以动态的为某一个类添加成员方法。这也就是Category实现的原理，同时也说明了Category只可以为对象添加成员方法，不能添加成员变量。
* 5.cache：
方法缓存列表，objc_msgSend（下文详解）每调用一次方法后，就会把该方法缓存到cache列表中，下次调用的时候，会优先从cache列表中寻找，如果cache没有，才从methodLists中查找方法。提高效率。

![](http://upload-images.jianshu.io/upload_images/1321491-dda0360cd4769dbd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**看图说话：**

上图中：superclass指针代表继承关系，isa指针代表实例所属的类。
类也是一个对象，它是另外一个类的实例，这个就是“元类”，元类里面保存了类方法的列表，类里面保存了实例方法的列表。实例对象的isa指向类，类对象的isa指向元类，元类对象的isa指针指向一个“根元类”（root metaclass）。所有子类的元类都继承父类的元类，换而言之，类对象和元类对象有着同样的继承关系。
>  PS: 
1.Class是一个指向objc_class结构体的指针，而id是一个指向objc_object结构体的指针，其中的isa是一个指向objc_class结构体的指针。其中的id就是我们所说的对象，Class就是我们所说的类。
2.isa指针不总是指向实例对象所属的类，不能依靠它来确定类型，而是应该用```isKindOfClass:```方法来确定实例对象的类。因为KVO的实现机制就是将被观察对象的isa指针指向一个中间类而不是真实的类。

#### 3.SEL
SEL是选择子的类型，选择子指的就是方法的名字。在Runtime的头文件中的定义如下：
```objc
typedef struct objc_selector *SEL;
```
它就是个映射到方法的C字符串，SEL类型代表着方法的签名，在类对象的方法列表中存储着该签名与方法代码的对应关系，每个方法都有一个与之对应的SEL类型的对象，根据一个SEL对象就可以找到方法的地址，进而调用方法。

#### 4.Method
Method代表类中的某个方法的类型，在Runtime的头文件中的定义如下：
```objc
typedef struct objc_method *Method;
```
objc_method的结构体定义如下：
```objc
struct objc_method {
    SEL method_name                    OBJC2_UNAVAILABLE;
    char *method_types                 OBJC2_UNAVAILABLE;
    IMP method_imp                     OBJC2_UNAVAILABLE;
}
```
* 1.method_name：方法名。
* 2.method_types：方法类型，主要存储着方法的参数类型和返回值类型。
* 3.IMP：方法的实现，函数指针。（下文详解）

``` class_copyMethodList(Class cls, unsigned int *outCount) ```可以使用这个方法获取某个类的成员方法列表。

#### 5.Ivar
Ivar代表类中实例变量的类型，在Runtime的头文件中的定义如下：
```objc
typedef struct objc_ivar *Ivar;
```
objc_ivar的定义如下：
```objc
struct objc_ivar {
    char *ivar_name                   OBJC2_UNAVAILABLE; 
    char *ivar_type                   OBJC2_UNAVAILABLE; 
    int ivar_offset                   OBJC2_UNAVAILABLE; 
#ifdef __LP64__
    int space                         OBJC2_UNAVAILABLE;
#endif
}
```
``` class_copyIvarList(Class cls, unsigned int *outCount) ``` 可以使用这个方法获取某个类的成员变量列表。
#### 6.objc_property_t
objc_property_t是属性，在Runtime的头文件中的的定义如下：
```objc
typedef struct objc_property *objc_property_t;
```
``` class_copyPropertyList(Class cls, unsigned int *outCount) ``` 可以使用这个方法获取某个类的属性列表。
#### 7.IMP
IMP在Runtime的头文件中的的定义如下：
```objc
typedef id (*IMP)(id, SEL, ...);
```
IMP是一个函数指针，它是由编译器生成的。当你发起一个消息后，这个函数指针决定了最终执行哪段代码。
#### 8.Cache
Cache在Runtime的头文件中的的定义如下：
```objc
typedef struct objc_cache *Cache
```
objc_cache的定义如下：
```objc
struct objc_cache {
    unsigned int mask                   OBJC2_UNAVAILABLE;
    unsigned int occupied               OBJC2_UNAVAILABLE;
    Method buckets[1]                   OBJC2_UNAVAILABLE;
};
```
每调用一次方法后，不会直接在isa指向的类的方法列表（methodLists）中遍历查找能够响应消息的方法，因为这样效率太低。它会把该方法缓存到cache列表中，下次的时候，就直接优先从cache列表中寻找，如果cache没有，才从isa指向的类的方法列表（methodLists）中查找方法。提高效率。
### 二、发送消息（objc_msgSend）
在Objective-C中，调用方法是经常使用的。用Objective-C的术语来说，这叫做“传递消息”（pass a message）。消息有“名称”（name）或者“选择子”（selector），也可以接受参数，而且可能还有返回值。
如果向某个对象传递消息，在底层，所有的方法都是普通的C语言函数，然而对象收到消息之后，究竟该调用哪个方法则完全取决于运行期决定，甚至可能在运行期改变，这些特性使得Objective-C变成一门真正的动态语言。
给对象发送消息可以这样来写：
```objc
id returnValue = [someObject message:parm];
```
someObject叫做“接收者”（receiver），message是“选择子”（selector），选择子和参数结合起来就叫做“消息”（message）。编译器看到此消息后，将其转换成C语言函数调用，所调用的函数乃是消息传递机制中的核心函数，叫做```objc_msgSend```，其原型如下：
```objc
id objc_msgSend (id self, SEL _cmd, ...);
```
后面的...表示这是个“参数个数可变的函数”，能接受两个或两个以上的参数。第一个参数是接收者（receiver），第二个参数是选择子（selector），后续参数就是消息中传递的那些参数（parm），其顺序不变。

编译器会把上面的那个消息转换成:
```objc
id returnValue objc_mgSend(someObject, @selector(message:), parm);
```
传递消息的几种函数：

``` objc_msgSend ```：普通的消息都会通过该函数发送。

``` objc_msgSend_stret ```：消息中有结构体作为返回值时，通过此函数发送和接收返回值。

``` objc_msgSend_fpret ```：消息中返回的是浮点数，可交由此函数处理。

``` objc_msgSendSuper ```：和``` objc_msgSend ```类似，这里把消息发送给超类。

``` objc_msgSendSuper_stret ```：和``` objc_msgSend_stret ```类似，这里把消息发送给超类。

``` objc_msgSendSuper_fpret ```：和``` objc_msgSend_fpret ```类似，这里把消息发送给超类。

编译器会根据情况选择一个函数来执行。

``` objc_msgSend ```发送消息的原理：
* 第一步：检测这个selector是不是要被忽略的。
* 第二步：检测这个target对象是不是nil对象。（nil对象执行任何一个方法都不会Crash，因为会被忽略掉）
* 第三步：首先会根据target对象的isa指针获取它所对应的类（class）。
* 第四步：优先在类（class）的cache里面查找与选择子（selector）名称相符，如果找不到，再到methodLists查找。
* 第五步：如果没有在类（class）找到，再到父类（super_class）查找，再到元类（metaclass），直至根metaclass。
* 第六步：一旦找到与选择子（selector）名称相符的方法，就跳至其实现代码。如果没有找到，就会执行消息转发（message forwarding）。（下节会详解）

### 三、消息转发（message forwarding）
上面说了消息的传递机制，下面就来说一下，如果对象在收到无法解读的消息之后会发生上面情况。
当一个对象在收到无法解读的消息之后，它会将消息实施转发。转发的主要步骤如下：

**消息转发步骤：**
* 第一步：对象在收到无法解读的消息后，首先调用```resolveInstanceMethod：```方法决定是否动态添加方法。如果返回YES，则调用```class_addMethod```动态添加方法，消息得到处理，结束；如果返回NO，则进入下一步；
* 第二步：当前接收者还有第二次机会处理未知的选择子，在这一步中，运行期系统会问：能不能把这条消息转给其他接收者来处理。会进入```forwardingTargetForSelector:```方法，用于指定备选对象响应这个selector，不能指定为self。如果返回某个对象则会调用对象的方法，结束。如果返回nil，则进入下一步；
* 第三步：这步我们要通过```methodSignatureForSelector:```方法签名，如果返回nil，则消息无法处理。如果返回methodSignature，则进入下一步；
* 第四步：这步调用```forwardInvocation：```方法，我们可以通过anInvocation对象做很多处理，比如修改实现方法，修改响应对象等，如果方法调用成功，则结束。如果失败，则进入```doesNotRecognizeSelector```方法，抛出异常，此异常表示选择子最终未能得到处理。

```objc
/**
 消息转发第一步：对象在收到无法解读的消息后，首先调用此方法，可用于动态添加方法，方法决定是否动态添加方法。如果返回YES，则调用class_addMethod动态添加方法，消息得到处理，结束；如果返回NO，则进入下一步；
 */
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    return NO;
}

/**
 当前接收者还有第二次机会处理未知的选择子，在这一步中，运行期系统会问：能不能把这条消息转给其他接收者来处理。会进入此方法，用于指定备选对象响应这个selector，不能指定为self。如果返回某个对象则会调用对象的方法，结束。如果返回nil，则进入下一步；
 */
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return nil;
}

/**
 这步我们要通过该方法签名，如果返回nil，则消息无法处理。如果返回methodSignature，则进入下一步。
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([NSStringFromSelector(aSelector) isEqualToString:@"study"])
    {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

/**
 这步调用该方法，我们可以通过anInvocation对象做很多处理，比如修改实现方法，修改响应对象等，如果方法调用成功，则结束。如果失败，则进入doesNotRecognizeSelector方法。
 */
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setSelector:@selector(play)];
    [anInvocation invokeWithTarget:self];
}

/**
 抛出异常，此异常表示选择子最终未能得到处理。
 */
- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    NSLog(@"无法处理消息：%@", NSStringFromSelector(aSelector));
}
```
![](http://easyread.ph.126.net/2xXezKIBals0tJ0cNKl9tg==/8796093022299154103.jpg)
> 接收者在每一步中均有机会处理消息，步骤越靠后，处理消息的代价越大。最好在第一步就能处理完，这样系统就可以把此方法缓存起来了。

### 四、关联对象 （AssociatedObject）
有时我们需要在对象中存放相关信息，Objective-C中有一种强大的特性可以解决此类问题，就是“关联对象”。 
可以给某个对象关联许多其他对象，这些对象通过“键”来区分。存储对象值时，可以指明“存储策略”，用以维护相应地“内存管理语义”。存储策略由名为“objc_AssociationPolicy” 的枚举所定义。下表中列出了该枚举值得取值，同时还列出了与之等下的@property属性：假如关联对象成为了属性，那么他就会具备对应的语义。

| 关联类型                           | 等效的@property属性                                   |
|:---------------------------------:|:----------------------------------------------------:| 
| OBJC_ASSOCIATION_ASSIGN           | @property (assign) or @ property (unsafe_unretained)| 
| OBJC_ASSOCIATION_RETAIN_NONATOMIC | @property (nonatomic, strong)                       | 
| OBJC_ASSOCIATION_COPY_NONATOMIC   | @property (nonatomic, copy)                         |  
| OBJC_ASSOCIATION_RETAIN           | @property (atomic, strong)                          |
| OBJC_ASSOCIATION_COPY             | @property (atomic, copy)                            |

下列方法可以管理关联对象：
```objc
// 以给定的键和策略为某对象设置关联对象值。
objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)
// 根据给定的键从某对象中获取对应的对象值。
id objc_getAssociatedObject(id object, void *key)
// 移除指定对象的全部关联对象。
void objc_removeAssociatedObjects(id object)
```
### 五、方法交换（method swizzing）
在Objective-C中，对象收到消息之后，究竟会调用哪种方法需要在运行期才能解析出来。查找消息的唯一依据是选择子(selector)，选择子(selector)与相应的方法(IMP)对应，利用Objective-C的动态特性，可以实现在运行时偷换选择子（selector）对应的方法实现，这就是方法交换（method swizzling）。

![](http://upload-images.jianshu.io/upload_images/1321491-fab02075750e2129.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

类的方法列表会把每个选择子都映射到相关的IMP之上

![](http://upload-images.jianshu.io/upload_images/1321491-34dff4504826ae5c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们可以新增选择子，也可以改变某个选择子所对应的方法实现，还可以交换两个选择子所映射到的指针。
#### Objective-C中提供了三种API来动态替换类方法或实例方法的实现：
* 1.```class_replaceMethod```替换类方法的定义。

```objc
class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
```
* 2.```method_exchangeImplementations```交换两个方法的实现。

```objc
method_exchangeImplementations(Method m1, Method m2)
```
* 3.```method_setImplementation```设置一个方法的实现

```objc
method_setImplementation(Method m, IMP imp)
```
先说下这三个方法的区别：
* ```class_replaceMethod```：当类中没有想替换的原方法时，该方法调用```class_addMethod```来为该类增加一个新方法，也正因如此，```class_replaceMethod```在调用时需要传入types参数，而其余两个却不需要。
* ```method_exchangeImplementations```：内部实现就是调用了两次```method_setImplementation```方法。

再来看看他们的使用场景：
```objc
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SEL originalSelector = @selector(willMoveToSuperview:);
        SEL swizzledSelector = @selector(myWillMoveToSuperview:);

        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(self, 
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(self, 
                                swizzledSelector, 
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)myWillMoveToSuperview:(UIView *)newSuperview
{
    NSLog(@"WillMoveToSuperview: %@", self); 
    [self myWillMoveToSuperview:newSuperview];
}
```
#### 总结
> 1.```class_replaceMethod```，当需要替换的方法有可能不存在时，可以考虑使用该方法。
2.```method_exchangeImplementations```，当需要交换两个方法的时使用。
3.```method_setImplementation```是最简单的用法，当仅仅需要为一个方法设置其实现方式时实现。

## 使用实例
前面讲的全部是理论知识，比较枯燥，下面说一些实际的栗子。
### 一、动态的创建一个类
```objc
// 创建一个名为People的类，它是NSObject的子类
Class People = objc_allocateClassPair([NSObject class], "People", 0);

// 为该类添加一个eat的方法
class_addMethod(People, NSSelectorFromString(@"eat"), (IMP) eatFun, "v@:");

// 注册该类
objc_registerClassPair(People);

// 创建一个People的实例对象p
id p = [[People alloc] init];

// 调用eat方法
[p performSelector:@selector(eat)];
```
### 二、动态的给某个类添加方法
```objc
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if ([NSStringFromSelector(sel) isEqualToString:@"doSomething"])
    {
        class_addMethod(self, sel, (IMP) doSomething, "v@:@");
    }
    return YES;
}
```
> 动态的给某个类添加方法，```class_addMethod```的参数：
self：给哪个类添加方法
sel：添加方法的方法编号（选择子）
IMP：添加方法的函数实现(函数地址)
types 函数的类型,(返回值+参数类型) v:void @:对象->self :表示SEL->_cmd

### 三、关联对象
类别不可以添加属性，我们可以在类别中设置关联，举个栗子：
Person+Category.h 文件
```objc
#import "Person.h"

@interface Person (Category)

@property (nonatomic, copy) NSString *name;

@end
```
Person+Category.m 文件
```objc
#import "Person+Category.h"
#import <objc/runtime.h>

@implementation Person (Category)

static char *key;

- (void)setName:(NSString *)name
{
    objc_setAssociatedObject(self, 
                             key, 
                             name,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)name
{
    return objc_getAssociatedObject(self, key);
}

@end
```
当然你也可以这么写

Person+Category.m 文件
```objc
#import "Person+Category.h"
#import <objc/runtime.h>

@implementation Person (Category)

- (void)setName:(NSString *)name
{
    objc_setAssociatedObject(self, 
                             @selector(name), 
                             name,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)name
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
```
> ```objc_setAssociatedObject```和```objc_getAssociatedObject```传入的参数key：要求是唯一并且是常量，可以使用static char，然而一个更简单方便的方法就是：使用选择子。由于选择子是唯一并且是常量，你可以使用选择子作为关联的key。（PS：_cmd表示当前调用的方法，它就是一个方法选择器SEL，类似self表示当前对象）

### 四、方法交换
* 1.如果我现在想检查一下项目中有没有内存循环，怎么办？是不是要重写```dealloc```函数，看下```dealloc```有没有执行，项目小的时候，一个一个```controller```的写，还不麻烦，如果项目大，要是一个一个的写，估计你会疯掉的。这时候方法交换就派上用场了，你就可以尝试用自己的方法交换系统的```dealloc```方法，几句代码就搞定了。

```objc
#import "UIViewController+Dealloc.h"
#import <objc/runtime.h>

@implementation UIViewController (Dealloc)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method method1 = class_getInstanceMethod(self, NSSelectorFromString(@"dealloc"));
        Method method2 = class_getInstanceMethod(self, @selector(my_dealloc));
        method_exchangeImplementations(method1, method2);
    });
}

- (void)my_dealloc
{
    NSLog(@"%@销毁了", self);
    [self my_dealloc];
}

@end
```
* 2.数组越界，向数组中添加一个```nil```对象等等，都会造成闪退，我们可以用自己的方法交换数组相对应的方法。下面是一个交换数组```addObject:```方法的栗子：

```objc
#import "NSMutableArray+Category.h"
#import <objc/runtime.h>

@implementation NSMutableArray (Category)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SEL originalSelector = @selector(addObject:);
        SEL swizzledSelector = @selector(lj_AddObject:);

        // NSMutableArray是类簇，真正的类名是__NSArrayM
        Method originalMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), originalSelector);
        Method swizzledMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), swizzledSelector);

        BOOL didAddMethod = class_addMethod(self,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod));

        if (didAddMethod)
        {
            class_replaceMethod(self,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        else
        {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)lj_AddObject:(id)object
{
    if (object != nil)
    {
        [self lj_AddObject:object];
    }
}

@end

```
> PS：我不太建议大家平时开发的时候使用这类数组安全操作的做法，不利于代码的调试，如果真的加入了nil对象，你可能就不会那么容易找出问题在哪，还是在项目发布的时候使用比较合适。

### 五、归档
大家都知道在归档的时候，需要先将属性一个一个的归档，然后再将属性一个一个的解档，3-5个属性还好，假如100个怎么办，那不得写累死。有了Runtime，就不用担心这个了，下面就是如何利用Runtime实现自动归档和解档。
NSObject+Archive.h文件：
```objc
#import <Foundation/Foundation.h>

@interface NSObject (Archive)

/**
 *  归档
 */
- (void)encode:(NSCoder *)aCoder;

/**
 *  解档
 */
- (void)decode:(NSCoder *)aDecoder;

/**
 *  这个数组中的成员变量名将会被忽略：不进行归档
 */
@property (nonatomic, strong) NSArray *ignoredIvarNames;

@end
```
NSObject+Archive.m文件：
```objc
#import "NSObject+Archive.h"
#import <objc/runtime.h>

@implementation NSObject (Archive)

- (void)encode:(NSCoder *)aCoder
{
    unsigned int outCount = 0;
    Ivar *ivars = class_copyIvarList([self class], &outCount);
    for (unsigned int i = 0; i < outCount; i++)
    {
        Ivar ivar = ivars[i];
        NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([self.ignoredIvarNames containsObject:key])
        {
            continue;
        }
        id value = [self valueForKey:key];
        [aCoder encodeObject:value forKey:key];
    }
    free(ivars);
}

- (void)decode:(NSCoder *)aDecoder
{
    unsigned int outCount = 0;
    Ivar *ivars = class_copyIvarList([self class], &outCount);
    for (unsigned int i = 0; i < outCount; i++)
    {
        Ivar ivar = ivars[i];
        NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([self.ignoredIvarNames containsObject:key])
        {
            continue;
        }
        id value = [aDecoder decodeObjectForKey:key];
        [self setValue:value forKey:key];
    }
    free(ivars);
}

- (void)setIgnoredIvarNames:(NSArray *)ignoredIvarNames
{
    objc_setAssociatedObject(self,
                             @selector(ignoredIvarNames),
                             ignoredIvarNames,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)ignoredIvarNames
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
```

然后再去需要归档的类实现文件里面写上这几行代码：

```objc
@implementation Person

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [self encode:aCoder];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        [self decode:aDecoder];
    }
    return self;
}

@end
```
这几行代码都是固定写法，你也可以把它们定义成宏，这样就可以实现一行代码就归档了，思路源自MJExtension！

### 六、字典转模型
利用Runtime，遍历模型中所有成员变量，根据模型的属性名，去字典中查找key，取出对应的value，给模型的属性赋值，实现的思路主要借鉴MJExtension。

NSObject+Property.h文件：
```objc
#import <Foundation/Foundation.h>

@protocol KeyValue <NSObject>

@optional
/**
 *  数组中需要转换的模型类
 *
 *  @return 字典中的key是数组属性名，value是数组中存放模型的Class（Class类型或者NSString类型）
 */
+ (NSDictionary *)objectClassInArray;

/**
 *  将属性名换为其他key去字典中取值
 *
 *  @return 字典中的key是属性名，value是从字典中取值用的key
 */
+ (NSDictionary *)replacedKeyFromPropertyName;

@end

@interface NSObject (Property) <KeyValue>

+ (instancetype)objectWithDictionary:(NSDictionary *)dictionary;

@end
```
NSObject+Property.m文件：
```objc
#import "NSObject+Property.h"
#import <objc/runtime.h>

@implementation NSObject (Property)

+ (instancetype)objectWithDictionary:(NSDictionary *)dictionary
{
    id obj = [[self alloc] init];

    // 获取所有的成员变量
    unsigned int count;
    Ivar *ivars = class_copyIvarList(self, &count);

    for (unsigned int i = 0; i < count; i++)
    {
        Ivar ivar = ivars[i];

        // 取出的成员变量，去掉下划线
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        NSString *key = [ivarName substringFromIndex:1];

        id value = dictionary[key];

        // 当这个值为空时，判断一下是否执行了replacedKeyFromPropertyName协议，如果执行了替换原来的key查值
        if (!value)
        {
            if ([self respondsToSelector:@selector(replacedKeyFromPropertyName)])
            {
                NSString *replaceKey = [self replacedKeyFromPropertyName][key];
                value = dictionary[replaceKey];
            }
        }

        // 字典嵌套字典
        if ([value isKindOfClass:[NSDictionary class]])
        {
            NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
            NSRange range = [type rangeOfString:@"\""];
            type = [type substringFromIndex:range.location + range.length];
            range = [type rangeOfString:@"\""];
            type = [type substringToIndex:range.location];
            Class modelClass = NSClassFromString(type);

            if (modelClass)
            {
                value = [modelClass objectWithDictionary:value];
            }
        }

        // 字典嵌套数组
        if ([value isKindOfClass:[NSArray class]])
        {
            if ([self respondsToSelector:@selector(objectClassInArray)])
            {
                NSMutableArray *models = [NSMutableArray array];

                NSString *type = [self objectClassInArray][key];
                Class classModel = NSClassFromString(type);
                for (NSDictionary *dict in value)
                {
                    id model = [classModel objectWithDictionary:dict];
                    [models addObject:model];
                }
                value = models;
            }
        }

        if (value)
        {
            [obj setValue:value forKey:key];
        }
    }

    // 释放ivars
    free(ivars);

    return obj;
}

@end
```
## 参考
[Associated Objects](http://nshipster.com/associated-objects/)

[Objective-C Runtime](http://yulingtianxia.com/blog/2014/11/05/objective-c-runtime/)

[Objective-C Runtime 1小时入门教程](https://www.ianisme.com/ios/2019.html)

[Objective-C的hook方案（一）: Method Swizzling](http://blog.csdn.net/yiyaaixuexi/article/details/9374411)

iOS开发进阶

Effective Objective-C 2.0

## 最后
由于笔者水平有限，文中如果有错误的地方，还望大神指正。

附上本文的demo下载链接，[【GitHub】](https://github.com/leejayID/RuntimeDemo)、[【OSChina】](https://git.oschina.net/Lee_Jay/RuntimeDemo)，如果你觉得看完后对你有所帮助，还望点个star。赠人玫瑰，手有余香。
