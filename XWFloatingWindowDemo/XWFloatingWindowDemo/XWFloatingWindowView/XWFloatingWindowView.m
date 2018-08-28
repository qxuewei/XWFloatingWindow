//
//  XWFloatingWindowView.m
//  XWFloatingWindowDemo
//
//  Created by 邱学伟 on 2018/7/22.
//  Copyright © 2018 邱学伟. All rights reserved.
//

#import "XWFloatingWindowView.h"

#define XW_ISIPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#pragma mark - Macros
//全局浮窗
static XWFloatingWindowView *xw_floatingWindowView;
//浮窗宽度
static const CGFloat cFloatingWindowWidth = 60.0;
//默认缩放动画时间
static const NSTimeInterval cFloatingWindowPathAnimtiontDuration = 0.3;
//浮窗左右两边最小间距
static const CGFloat cFloatingWindowMargin = 20.0;
//红色浮窗隐藏视图宽度
static const CGFloat cFloatingWindowContentWidth = 160.0;
//默认动画时间
static const NSTimeInterval cFloatingWindowAnimtionDefaultDuration = 0.25;
//浮窗上下两边最小间距 非 iPhoneX
static const CGFloat cFloatingWindowTopBottomMargin = 64.0;
//浮窗上下两边最小间距 iPhoneX
static const CGFloat cFloatingWindowTopBottomMarginIphoneX = 86.0;

#pragma mark - *** 红色隐藏视图 ****
/// 视图右下红色隐藏视图,浮窗拖入消失
@interface XWFloatingWindowContentView : UIView
/**
 扩散效果
 */
- (void)spreadAnimation;
/**
 取消扩散效果
 */
- (void)cancelSpreadAnimation;
@end

#pragma mark - *** 震动器 ****
@interface XWFloatingShakeManager : NSObject
/**
 震动器单例

 @return 震动器
 */
+ (instancetype)share;

/**
 震动方法
 */
- (void)shake;
@end

#pragma mark - **************************************** 转场动画视图 ******************************************************
/// 转场扩散动画视图
@interface XWFloatingAnimationView : UIView <CAAnimationDelegate>
@property (nonatomic, strong) UIImage *screenImage;
@end

@implementation XWFloatingAnimationView {
    UIImageView *p_imageView;
    CAShapeLayer *p_shapeLayer;
    UIView *p_theView;
}
#pragma mark - public
/// 扩散动画
- (void)startAnimatingWithView:(UIView *)view fromRect:(CGRect)fromRect toRect:(CGRect)toRect {
    p_theView = view;
    
    p_shapeLayer = [CAShapeLayer layer];
    p_shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:fromRect cornerRadius:cFloatingWindowWidth * 0.5].CGPath;
    p_shapeLayer.fillColor = [UIColor lightGrayColor].CGColor;
    p_imageView.layer.mask = p_shapeLayer;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    anim.toValue = (__bridge id)[UIBezierPath bezierPathWithRoundedRect:toRect cornerRadius:cFloatingWindowWidth * 0.5].CGPath;
    anim.duration = cFloatingWindowPathAnimtiontDuration;
    anim.delegate = self;
    anim.fillMode = kCAFillModeForwards;
    anim.removedOnCompletion = NO;
    
    [p_shapeLayer addAnimation:anim forKey:@"XWFloatingAnimation"];
}

#pragma mark system
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

#pragma mark  private
- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    p_imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:p_imageView];
}
- (void)setScreenImage:(UIImage *)screenImage {
    p_imageView.image = screenImage;
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    p_theView.hidden = NO;
    [self removeFromSuperview];
}
@end

#pragma mark - ***************************************** 转场工具类 *****************************************************
@interface XWFloatingAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign) CGPoint currentFloatingCenter;
@property (nonatomic, assign) UINavigationControllerOperation operation;
@property (nonatomic, assign) BOOL isInteractive;
@end

@implementation XWFloatingAnimator

#pragma mark  UIViewControllerAnimatedTransitioning
- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = transitionContext.containerView;
    
    if (_operation == UINavigationControllerOperationPush) {
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        [containerView addSubview:toView];
        XWFloatingAnimationView *animationV = [[XWFloatingAnimationView alloc] initWithFrame:toView.bounds];
        UIGraphicsBeginImageContext(toView.bounds.size);
        [toView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        animationV.screenImage = image;
        toView.hidden = YES;
        UIGraphicsEndImageContext();
        [containerView addSubview:animationV];
        [animationV startAnimatingWithView:toView fromRect:CGRectMake(_currentFloatingCenter.x, _currentFloatingCenter.y, cFloatingWindowWidth, cFloatingWindowWidth) toRect:toView.frame];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(cFloatingWindowPathAnimtiontDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [transitionContext completeTransition:YES];
        });
        
    }else if (_operation == UINavigationControllerOperationPop) {
        
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        [containerView addSubview:toView];
        UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        [containerView bringSubviewToFront:fromView];
        if (_isInteractive) {
            /// 可交互式动画
            [UIView animateWithDuration:0.3f animations:^{
                fromView.frame = CGRectOffset(fromView.frame, [UIScreen mainScreen].bounds.size.width, 0.f);
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                if (!transitionContext.transitionWasCancelled) {
                    xw_floatingWindowView.alpha = 1.f;
                }
            }];
            
        } else {
            /// 非可交互式动画
            XWFloatingAnimationView *theView = [[XWFloatingAnimationView alloc] initWithFrame:fromView.bounds];
            UIGraphicsBeginImageContext(fromView.bounds.size);
            [fromView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            theView.screenImage = image;
            UIGraphicsEndImageContext();
            CGRect fromRect = fromView.frame;
            fromView.frame = CGRectZero;
            [containerView addSubview:theView];
            [theView startAnimatingWithView:theView fromRect:fromRect toRect:CGRectMake(_currentFloatingCenter.x, _currentFloatingCenter.y, 60.f, 60.f)];
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            xw_floatingWindowView.alpha = 1.f;
        }
    }
}
- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 1.0;
}
@end


#pragma mark - ****************************************** 滑动pop适配器 ****************************************************
@interface XWInteractiveTransition : UIPercentDrivenInteractiveTransition
@property (nonatomic, assign) BOOL isInteractive;
@property (nonatomic, assign) CGPoint curPoint;
- (void)transitionToViewController:(UIViewController *)toViewController;
@end

@implementation XWInteractiveTransition {
    __weak UIViewController *presentedViewController;
    BOOL shouldComplete;
    CGFloat transitionX;
}

- (void)dealloc {
    NSLog(@"%@ +++ %s",NSStringFromClass([self class]),__func__);
}

- (void)transitionToViewController:(UIViewController *)toViewController {
    presentedViewController = toViewController;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    toViewController.view.userInteractionEnabled = YES;
    [toViewController.view addGestureRecognizer:panGesture];
}

- (void)panAction:(UIPanGestureRecognizer *)gesture {
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            _isInteractive = YES;
            [nav popViewControllerAnimated:YES];
            break;
            
        case UIGestureRecognizerStateChanged: {
            //监听当前滑动的距离
            CGPoint transitionPoint = [gesture translationInView:presentedViewController.view];
            CGFloat ratio = transitionPoint.x/[UIScreen mainScreen].bounds.size.width;
            transitionX = transitionPoint.x;
            xw_floatingWindowView.alpha = ratio;
            if (ratio >= 0.5) {
                shouldComplete = YES;
            } else {
                shouldComplete = NO;
            }
            [self updateInteractiveTransition:ratio];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            
            if (shouldComplete) {
                UIView *fromView = presentedViewController.view;
                XWFloatingAnimationView *theView = [[XWFloatingAnimationView alloc] initWithFrame:fromView.bounds];
                UIGraphicsBeginImageContext(fromView.bounds.size);
                [fromView.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                theView.screenImage = image;
                UIGraphicsEndImageContext();
                CGRect fromRect = fromView.frame;
                fromView.frame = CGRectZero;
                [fromView.superview addSubview:theView];
                [theView startAnimatingWithView:theView fromRect:CGRectMake(transitionX, 0.f, fromRect.size.width, fromRect.size.height) toRect:CGRectMake(_curPoint.x, _curPoint.y, 60.f, 60.f)];
                [self finishInteractiveTransition];
                nav.delegate = nil;
            } else {
                xw_floatingWindowView.alpha = 0.f;
                [self cancelInteractiveTransition];
            }
            _isInteractive = NO;
        }
            break;
        default:
            break;
    }
}
@end

#pragma mark - ****************************************** 浮窗视图 ****************************************************
@interface XWFloatingWindowView() <UINavigationControllerDelegate>
@end

@implementation XWFloatingWindowView {
    CGSize screenSize;
    CGPoint lastPointInSuperView;
    CGPoint lastPointInSelf;
    XWInteractiveTransition *weakInteractiveTransition;
    BOOL p_isShowing;
    UIViewController *p_containerVC;
    BOOL isShake;
}
//全局隐藏浮窗视图
static XWFloatingWindowContentView *xw_floatingWindowContentView;

#pragma mark - publish
+ (void)showWithViewController:(UIViewController *)viewController {
    UINavigationController *nav = viewController.navigationController;
    if (!nav) {
        NSLog(@"展示浮窗必须添加到 NavigationController 管理的视图上!");
        return;
    }
    if (xw_floatingWindowView && xw_floatingWindowView->p_isShowing) {
        if (viewController == xw_floatingWindowView->p_containerVC) {
            NSLog(@"当前控制器的浮窗已经添加了...");
            return;
        }
        NSLog(@"正在展示一个浮窗 - 视图: %@",xw_floatingWindowView->p_containerVC);
        xw_floatingWindowView->p_containerVC = nil;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat minY =  XW_ISIPhoneX ? cFloatingWindowTopBottomMarginIphoneX : cFloatingWindowTopBottomMargin;
        xw_floatingWindowView = [[XWFloatingWindowView alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width - cFloatingWindowWidth - cFloatingWindowMargin, minY, cFloatingWindowWidth, cFloatingWindowWidth)];
        xw_floatingWindowContentView = [[XWFloatingWindowContentView alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height, cFloatingWindowContentWidth, cFloatingWindowContentWidth)];
    });
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!xw_floatingWindowContentView.superview) {
        [keyWindow addSubview:xw_floatingWindowContentView];
        [keyWindow bringSubviewToFront:xw_floatingWindowContentView];
    }
    if (!xw_floatingWindowView.superview) {
        [keyWindow addSubview:xw_floatingWindowView];
        [keyWindow bringSubviewToFront:xw_floatingWindowView];
    }
    
    xw_floatingWindowView->p_containerVC = viewController;
    xw_floatingWindowView->p_isShowing = YES;
    
    nav.delegate = xw_floatingWindowView;
    [nav popViewControllerAnimated:YES];
}

+ (void)remove {
    UINavigationController *navi = xw_floatingWindowView->p_containerVC.navigationController;
    navi.delegate = nil;
    xw_floatingWindowView->weakInteractiveTransition = nil;
    xw_floatingWindowView->p_containerVC = nil;
    [xw_floatingWindowView removeFloatingWindow];
}

+ (BOOL)isShowingWithViewController:(UIViewController *)viewController {
    if (!xw_floatingWindowView) {
        return NO;
    }
    if (xw_floatingWindowView->p_containerVC != viewController) {
        return NO;
    }
    return xw_floatingWindowView->p_isShowing;
}

#pragma mark - system
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    lastPointInSuperView = [touch locationInView:self.superview];
    lastPointInSelf = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint curentPoint = [touch locationInView:self.superview];
    
    /// 展开 右下浮窗隐藏视图
    if (!CGPointEqualToPoint(lastPointInSuperView, curentPoint)) {
        /// 有移动才展开
        CGRect rect = CGRectMake(screenSize.width - cFloatingWindowContentWidth, screenSize.height - cFloatingWindowContentWidth, cFloatingWindowContentWidth, cFloatingWindowContentWidth);
        if (!CGRectEqualToRect(xw_floatingWindowContentView.frame, rect)) {
            [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
                xw_floatingWindowContentView.frame = rect;
            }];
        }
    }
    
    /// 调整浮窗中心点
    CGFloat halfWidth = self.frame.size.width * 0.5;
    CGFloat halfHeight = self.frame.size.height * 0.5;
    CGFloat centerX = curentPoint.x + (halfWidth - lastPointInSelf.x);
    CGFloat centerY = curentPoint.y + (halfHeight - lastPointInSelf.y);
    CGFloat x = MIN(screenSize.width - halfWidth, MAX(centerX, halfWidth));
    CGFloat y = MIN(screenSize.height - halfHeight, MAX(centerY, halfHeight));
    self.center = CGPointMake(x,y);
    
    /// 震动
    CGFloat distance = sqrtf( (pow(self->screenSize.width - xw_floatingWindowView.center.x,2) + pow(self->screenSize.height - xw_floatingWindowView.center.y, 2)) );
    if (!isShake && (distance < (cFloatingWindowContentWidth - cFloatingWindowWidth * 0.5) ) ) {
        [[XWFloatingShakeManager share] shake];
        isShake = YES;
        [xw_floatingWindowContentView spreadAnimation];
    }else if (distance > (cFloatingWindowContentWidth - cFloatingWindowWidth * 0.5)) {
        isShake = NO;
        [xw_floatingWindowContentView cancelSpreadAnimation];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.superview];
    
    if (CGPointEqualToPoint(lastPointInSuperView, currentPoint)) {
        [self toContainerVC];
    }else{
        
        /// 收缩 右下浮窗隐藏视图
        [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
            /// 浮窗在隐藏视图内部,移除浮窗
            CGFloat distance = sqrtf( (pow(self->screenSize.width - xw_floatingWindowView.center.x,2) + pow(self->screenSize.height - xw_floatingWindowView.center.y, 2)) );
            if (distance < (cFloatingWindowContentWidth - cFloatingWindowWidth * 0.5)) {
                [XWFloatingWindowView remove];
            }
            xw_floatingWindowContentView.frame = CGRectMake(self->screenSize.width, self->screenSize.height, cFloatingWindowContentWidth, cFloatingWindowContentWidth);
        }];
        CGFloat left = currentPoint.x;
        CGFloat right = screenSize.width - currentPoint.x;
        
        CGFloat y = self.center.y;
        if (XW_ISIPhoneX) {
            y = MIN(screenSize.height - cFloatingWindowTopBottomMarginIphoneX, MAX(y, cFloatingWindowTopBottomMarginIphoneX));
        }else{
            y = MIN(screenSize.height - cFloatingWindowTopBottomMargin, MAX(y, cFloatingWindowTopBottomMargin));
        }
        if (left <= right) {
            [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
                self.center = CGPointMake(cFloatingWindowMargin + self.bounds.size.width * 0.5, y);
            }];
        }else{
            [UIView animateWithDuration:cFloatingWindowAnimtionDefaultDuration animations:^{
                self.center = CGPointMake(self->screenSize.width - cFloatingWindowMargin - self.bounds.size.width * 0.5, y);
            }];
        }
    }
}

#pragma mark - private
- (void)setupUI {
    screenSize = UIScreen.mainScreen.bounds.size;
    self.backgroundColor = [UIColor clearColor];
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"WebView_Minimize_Float_IconHL"].CGImage;
}

- (void)toContainerVC {
    XWInteractiveTransition * interactiveTransition = [[XWInteractiveTransition alloc] init];
    weakInteractiveTransition = interactiveTransition;
    interactiveTransition.curPoint = self.frame.origin;
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (![rootVC isKindOfClass:[UINavigationController class]]) {
        NSLog(@"根控制器不是 UINavigationController");
        return;
    }
    UINavigationController *navi = (UINavigationController *)rootVC;
    navi.delegate = self;
    [interactiveTransition transitionToViewController:p_containerVC];
    [navi pushViewController:p_containerVC animated:YES];
}

- (void)removeFloatingWindow {
    [self removeFromSuperview];
    p_isShowing = NO;
}

#pragma mark - getter

#pragma mark - UINavigationControllerDelegate
- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC {
    
    if ((operation == UINavigationControllerOperationPush && toVC != self->p_containerVC) || (operation == UINavigationControllerOperationPop && fromVC != self->p_containerVC) ) {
        return NULL;
    }
    
    if (operation == UINavigationControllerOperationPush) {
        self.alpha = 0.0;
    }
    XWFloatingAnimator *floatingAnimator = [[XWFloatingAnimator alloc] init];
    floatingAnimator.currentFloatingCenter = self.frame.origin;
    floatingAnimator.operation = operation;
    floatingAnimator.isInteractive = weakInteractiveTransition.isInteractive;
    return floatingAnimator;
}
- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                                   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController {
    return weakInteractiveTransition.isInteractive ? weakInteractiveTransition : nil;
}
@end

#pragma mark - ****************************************** 浮窗右下红色容器视图 ****************************************************

@implementation XWFloatingWindowContentView {
    CAShapeLayer *p_shapeLayer;
    CALayer *p_imageLayer;
    CATextLayer *p_textLayer;
    
    UIBezierPath *spreadPath;
    UIBezierPath *originPath;
    CABasicAnimation *imageLayerScaleAnim;
}
#pragma mark - public
- (void)spreadAnimation {
    if (!spreadPath) {
        spreadPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width, self.frame.size.height) radius:self.frame.size.width + 10 startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];
        [spreadPath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [spreadPath closePath];
    }
    p_shapeLayer.path = spreadPath.CGPath;
    
    if (!imageLayerScaleAnim) {
        imageLayerScaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        imageLayerScaleAnim.toValue = [NSNumber numberWithFloat:1.2];
        imageLayerScaleAnim.duration = 0.1;
        imageLayerScaleAnim.repeatCount = 1.0;
        imageLayerScaleAnim.removedOnCompletion = NO;
        imageLayerScaleAnim.fillMode = kCAFillModeForwards;
    }
    [p_imageLayer addAnimation:imageLayerScaleAnim forKey:@"imageLayerScale"];
}

- (void)cancelSpreadAnimation {
    if (!originPath) {
        originPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width, self.frame.size.height) radius:self.frame.size.width startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];
        [originPath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [originPath closePath];
    }
    p_shapeLayer.path = originPath.CGPath;
    [p_imageLayer removeAnimationForKey:@"imageLayerScale"];
}

#pragma mark - system
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}
#pragma mark - private
- (void)setupUI {
    [self.layer addSublayer:self.shapeLayer];
    [self.layer addSublayer:self.imageLayer];
    [self.layer addSublayer:self.textLayer];
    CGFloat imageW = 50.0;
    p_imageLayer.frame = CGRectMake(0.5 * (self.frame.size.width - imageW), 0.5 * (self.frame.size.height - imageW), imageW, imageW);
    p_textLayer.frame = CGRectMake(p_imageLayer.frame.origin.x, CGRectGetMaxY(p_imageLayer.frame) + 3.0, p_imageLayer.frame.size.width, 20);
}

#pragma mark - getter
- (CAShapeLayer *)shapeLayer {
    if(!p_shapeLayer){
        p_shapeLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width, self.frame.size.height) radius:self.frame.size.width startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];
        [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [path closePath];
        p_shapeLayer.path = path.CGPath;
        p_shapeLayer.fillColor = [UIColor colorWithRed:206/255.0 green:85/255.0 blue:85/255.0 alpha:1].CGColor;;
    }
    return p_shapeLayer;
}
- (CALayer *)imageLayer {
    if(!p_imageLayer){
        p_imageLayer = [[CALayer alloc] init];
        p_imageLayer.contents = (__bridge id)[UIImage imageNamed:@"WebView_Minimize_Corner_Icon_remove"].CGImage;
    }
    return p_imageLayer;
}
- (CATextLayer *)textLayer {
    if(!p_textLayer){
        p_textLayer = [[CATextLayer alloc] init];
        p_textLayer.string = @"取消浮窗";
        p_textLayer.fontSize = 12.0;
        p_textLayer.contentsScale = [UIScreen mainScreen].scale;
        p_textLayer.foregroundColor = [UIColor colorWithRed:234.f/255.0 green:160.f/255.0 blue:160.f/255.0 alpha:1].CGColor;
    }
    return p_textLayer;
}
@end


#pragma mark - **************************************** 震动器 ******************************************************
@implementation XWFloatingShakeManager {
    API_AVAILABLE(ios(10.0))
    UIImpactFeedbackGenerator *_generator;
}
/// 单例对象
static XWFloatingShakeManager *p_floatingShakeManager;
#pragma mark - public
- (void)shake {
    if (@available(iOS 10.0, *)) {
        [_generator prepare];
        [_generator impactOccurred];
    }
}
#pragma mark - system
- (instancetype)init {
    if (self = [super init]) {
        if (@available(iOS 10.0, *)) {
            /// ios10 以上才可震动
            _generator = [[UIImpactFeedbackGenerator alloc] initWithStyle: UIImpactFeedbackStyleLight];
        }
    }
    return self;
}
#pragma mark - 单例对象
+ (instancetype)share {
    if (!p_floatingShakeManager) {
        p_floatingShakeManager = [[self alloc] init];
    }
    return p_floatingShakeManager;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!p_floatingShakeManager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            p_floatingShakeManager = [super allocWithZone:zone];
        });
    }
    return p_floatingShakeManager;
}
- (id)copyWithZone:(NSZone *)zone{
    return p_floatingShakeManager;
}
- (id)mutableCopyWithZone:(NSZone *)zone{
    return p_floatingShakeManager;
}
@end
