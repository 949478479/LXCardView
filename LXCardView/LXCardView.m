//
//  LXCardView.m
//  LXCardViewDemo
//
//  Created by 从今以后 on 16/4/20.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "LXCardView.h"

@interface LXCardView ()
@property (nonatomic) NSUInteger numberOfCards;
@property (nonatomic) NSUInteger indexOfTopCard;
@property (nonatomic) NSUInteger maxIndexOfVisibleCard;
@property (nonatomic) NSMutableArray<UIView *> *visibleCards;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@end

@implementation LXCardView

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    _maxCountOfVisibleCards = 3;
    _visibleCards = [NSMutableArray new];

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panGestureHandle:)];
    [self addGestureRecognizer:_panGestureRecognizer];
}

#pragma mark - 添加移除卡片

- (void)reloadData
{
    [self.visibleCards removeAllObjects];

    self.numberOfCards = [self.delegate numberOfCardsInCardView:self];
    NSUInteger countOfVisibleCards = MIN(self.numberOfCards, self.maxCountOfVisibleCards);
    NSAssert(countOfVisibleCards > 0, @"可见卡片数量必须大于0");

    for (NSUInteger idx = 0; idx < countOfVisibleCards; ++idx) {
        [self _insertCardAtIndex:idx];
    }

    self.indexOfTopCard = 0;
    self.maxIndexOfVisibleCard = countOfVisibleCards - 1;
}

- (void)removeTopCardOnDirection:(LXCardViewDirection)direction
{
    UIView *topCardView = self.visibleCards[0];

    CGFloat factor = (direction ==LXCardViewDirectionLeft) ? -1.0 : 1.0;
    CGFloat horizontalDistance = (CGRectGetWidth(self.bounds) + CGRectGetWidth(topCardView.bounds)) / 2;

    CGPoint finalPosition;
    finalPosition.y = CGRectGetMidY(self.bounds) - 100.0;
    finalPosition.x = CGRectGetMidX(self.bounds) + factor * horizontalDistance;

    [self _updateTopCardWithFinalPosition:finalPosition];
}

- (void)_insertCardAtIndex:(NSUInteger)index
{
    UIView *cardView = [self.delegate cardView:self viewForCardAtIndex:index];
    [self insertSubview:cardView atIndex:0];
    [self.visibleCards addObject:cardView];
    [self _addConstraintsToCardView:cardView];
    [self _configureCardView:cardView atIndex:index];
}

- (void)_removeTopCardByAnimationWithFinalPosition:(CGPoint)position completion:(void (^)(void))completion
{
    UIView *topCard = self.visibleCards[0];
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        topCard.center = position;
    } completion:^(BOOL finished) {
        [self.visibleCards removeObjectAtIndex:0];
        [topCard removeFromSuperview];
        if ([self.delegate respondsToSelector:@selector(cardView:didRemoveTopCard:onDirection:atIndex:)]) {
            LXCardViewDirection direction = (topCard.center.x > CGRectGetMidX(self.bounds)) ?
            LXCardViewDirectionRight : LXCardViewDirectionLeft;
            [self.delegate cardView:self didRemoveTopCard:topCard onDirection:direction atIndex:self.indexOfTopCard];
        }
        !completion ?: completion();
    }];
}

- (void)_resetTopCard
{
    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.5 animations:^{
        self.visibleCards[0].center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
    } completion:^(BOOL finished) {
        self.userInteractionEnabled = YES;
    }];
}

- (void)_updateTopCardWithFinalPosition:(CGPoint)finalPosition
{
    self.userInteractionEnabled = NO;
    [self _removeTopCardByAnimationWithFinalPosition:finalPosition completion:^{
        if (self.indexOfTopCard < self.numberOfCards - 1) {
            self.indexOfTopCard += 1;
        }
        if (self.maxIndexOfVisibleCard < self.numberOfCards - 1) {
            self.maxIndexOfVisibleCard += 1;
            [self _insertCardAtIndex:self.maxIndexOfVisibleCard];
        }
        [self _configureVisibleCardsByAnimationWithCompletion:^{
            self.userInteractionEnabled = YES;
        }];
    }];
}

#pragma mark - 配置卡片

- (void)_addConstraintsToCardView:(UIView *)cardView
{
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutAttribute attributes[] = { NSLayoutAttributeCenterX, NSLayoutAttributeCenterY };
    for (int i = 0; i < 2; ++i) {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:attributes[i]
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cardView
                                                         attribute:attributes[i]
                                                        multiplier:1.0
                                                          constant:0.0]];
    }
}

- (void)_configureCardView:(UIView *)cardView atIndex:(NSUInteger)index
{
    // 随着索引变化，透明度变化30%，缩放变化10%，向下平移10点
    cardView.alpha = 1 - 0.3 * index;
    [cardView.layer setValue:@(1 - 0.1 * index) forKeyPath:@"transform.scale.x"];
    [cardView.layer setValue:@(10.0 * index) forKeyPath:@"transform.translation.y"];
}

#pragma mark - 动画处理

- (void)_configureVisibleCardsByAnimationWithCompletion:(void (^)(void))completion
{
    NSUInteger countOfVisibleCards = self.visibleCards.count;
    NSUInteger maxCountOfVisibleCards = self.maxCountOfVisibleCards;
    NSUInteger endIndex = countOfVisibleCards - 1;

    // 以最大数量卡片显示时，新插入到后方的卡片不要使用动画，直接和前一张卡片重合
    if (countOfVisibleCards == maxCountOfVisibleCards) {
        [self _configureCardView:self.visibleCards[endIndex] atIndex:endIndex];
    }

    [UIView animateWithDuration:0.5 animations:^{
        [self.visibleCards enumerateObjectsUsingBlock:^(UIView * _Nonnull obj,
                                                        NSUInteger idx,
                                                        BOOL * _Nonnull stop) {
            if (idx != endIndex || countOfVisibleCards != maxCountOfVisibleCards) {
                [self _configureCardView:obj atIndex:idx];
            }
        }];
    } completion:^(BOOL finished) {
        !completion ?: completion();
    }];
}

#pragma mark - 拖拽处理

- (void)setEnablePan:(BOOL)enablePan
{
    _enablePan = enablePan;

    self.panGestureRecognizer.enabled = enablePan;
}

- (void)_panGestureHandle:(UIPanGestureRecognizer *)panGR
{
    switch (panGR.state) {
        case UIGestureRecognizerStateBegan: {
            UIView *topCardView = self.visibleCards.firstObject;
            if (!topCardView || !CGRectContainsPoint(topCardView.frame, [panGR locationInView:self])) {
                panGR.enabled = NO;
            }
        } break;
        case UIGestureRecognizerStateChanged: {

            UIView *topCard = self.visibleCards[0];

            CGPoint translation = [panGR translationInView:self];
            [panGR setTranslation:CGPointZero inView:self];

            CGPoint center = ({
                CGPoint center = topCard.center;
                center.x += translation.x;
                center.y += translation.y;
                center;
            });

            topCard.center = center;

            if ([self.delegate respondsToSelector:@selector(topCard:didChangeCenterOffset:inCardView:)]) {
                CGPoint offset = {
                    center.x - CGRectGetMidX(self.bounds),
                    center.y - CGRectGetMidY(self.bounds)
                };
                [self.delegate topCard:topCard didChangeCenterOffset:offset inCardView:self];
            }

        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {

            if (!panGR.isEnabled) {
                panGR.enabled = YES;
                break;
            }

            UIView *topCard = self.visibleCards[0];

            CGPoint currentCenter = topCard.center;
            CGPoint originalCenter = { CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) };

            CGFloat offsetX = ABS(currentCenter.x - originalCenter.x);
            CGFloat maxOffsetX = self.maxOffsetXForTopCard > 0 ?
            self.maxOffsetXForTopCard :
            CGRectGetWidth(topCard.bounds) / 2;

            if (offsetX > maxOffsetX) {

                // 在水平方向上，令顶层卡片刚好能离开父视图范围，并根据其当前中心点与原始中心点的连线确定最终的y坐标
                CGFloat factor = (currentCenter.x < originalCenter.x) ? -1.0 : 1.0;
                CGFloat horizontalDistance = (CGRectGetWidth(self.bounds) + CGRectGetWidth(topCard.bounds)) / 2;

                CGPoint finalCenter;
                finalCenter.x = originalCenter.x + factor * horizontalDistance;
                finalCenter.y = factor * horizontalDistance * (currentCenter.y - originalCenter.y)
                / (currentCenter.x - originalCenter.x) + originalCenter.y;

                [self _updateTopCardWithFinalPosition:finalCenter];

            } else {

                if ([self.delegate respondsToSelector:@selector(topCard:didChangeCenterOffset:inCardView:)]) {
                    [self.delegate topCard:topCard didChangeCenterOffset:CGPointZero inCardView:self];
                }

                [self _resetTopCard];
            }
        } break;
        default: break;
    }
}

@end
