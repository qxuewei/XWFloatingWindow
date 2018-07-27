# XWFloatingWindow
一行代码集成微信浮窗功能

## 1. 效果

![演示Gif](https://raw.githubusercontent.com/qxuewei/XWFloatingWindow/master/Gif/gif_demo1.gif)

## 2. 使用

在需要浮窗展示的地方调用：

``` objective-c
// self 为需要浮窗展示的控制器
[XWFloatingWindowView showWithViewController:self];
```

现在你的控制器就已经集成微信浮窗功能了😀


### 其他方法
#### 1. 当然你可能需要知道当前控制器是否在浮窗内展示，你可以  👇：

```objective-c
// self 为当前控制器
BOOL isShowing = [XWFloatingWindowView isShowingWithViewController:self]
```

他会告诉你当前控制器是否已集成在浮窗内。

#### 2. 获取你希望移除这个浮窗，除了拖动到右下红色区域内自动移除以外，你也可以 👇：

```objective-c
// 移除浮窗，释放控制器
[XWFloatingWindowView remove];
```

## 3.扩展

>##### 1.界面跳转效果使用 `UINavigationController` 转场动画
>##### 2.震动效果使用 `UIImpactFeedbackGenerator` 此类仅支持iOS10及以上机型，微信能震动多数情况下此库也会震
>##### 3.一些界面绘制使用了 `CALayer` 和 相关子类.
>##### 4.使用了简单的 `CABasicAnimation` 核心动画
>##### 5.分享一个笔者创建单例对象的代码块，任何需要创建单例的类，引入此段代码，并将 `XXClassManager` 替换为你自定义的类就可以了。

```objective-c
#pragma mark - 单例对象
static XXClassManager *_defaultManager;
+ (instancetype)shareInstance {
    if (!_defaultManager) {
        _defaultManager = [[self alloc] init];
    }
    return _defaultManager;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!_defaultManager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _defaultManager = [super allocWithZone:zone];
        });
    }
    return _defaultManager;
}
- (id)copyWithZone:(NSZone *)zone{
    return _defaultManager;
}
- (id)mutableCopyWithZone:(NSZone *)zone{
    return _defaultManager;
}
```


-------

##### ⚠️ 调用此库之前需要确定你的控制器为 `NavigationController` 所管理，否则将无法集成

### 详情实现可下载源码查看： [XWFloatingWindow](https://github.com/qxuewei/XWFloatingWindow)

* ✍️ 笔者博客：[极客学伟的技术分享社区](https://blog.csdn.net/qxuewei)

