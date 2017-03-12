//
//  LXCardView.m
//  LXCardViewDemo
//
//  Created by 从今以后 on 16/4/20.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "LXCardView.h"

typedef NSMutableDictionary<NSString *, NSMutableSet<LXReusableCard *> *> LXReusableCardCache;

static CGFloat const kThrowingSpeedThreshold = 1000;
static NSTimeInterval const kThrowAnimationDuration = 0.25;
static NSTimeInterval const kResetAnimationDuration = 0.5;
static NSTimeInterval const kInsertAnimationDuration = 0.5;

@interface LXCardView () <UIDynamicAnimatorDelegate>

@property (nonatomic) NSUInteger numberOfCards;
@property (nonatomic) NSUInteger indexForTopCard;
@property (nonatomic) NSUInteger maxIndexForVisibleCard;
@property (nonatomic) NSMutableArray<UIView *> *visibleCards;
@property (nonatomic) LXReusableCardCache *reusableCardCache;

@property (nonatomic) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic) UIAttachmentBehavior *attachmentBehavior;
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
	_dragEnabled = YES;
    _maxCountOfVisibleCards = 3;
    _visibleCards = [NSMutableArray new];
	_reusableCardCache = [NSMutableDictionary new];

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panGestureHandle:)];
    [self addGestureRecognizer:_panGestureRecognizer];

	_dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
	_dynamicAnimator.delegate = self;
}

#pragma mark - 刷新数据

- (void)reloadData
{
    [self.visibleCards makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleCards removeAllObjects];
	[self.reusableCardCache removeAllObjects];

    self.numberOfCards = [self.delegate numberOfCardsInCardView:self];
    NSUInteger countOfVisibleCards = MIN(self.numberOfCards, self.maxCountOfVisibleCards);

    if (countOfVisibleCards == 0) {
		self.panGestureRecognizer.enabled = NO;
		return;
    }

	for (NSUInteger idx = 0; idx < countOfVisibleCards; ++idx) {
		[self _setupConstraintsForCard:[self _getAndAppendCardForIndex:idx]];
	}

	self.indexForTopCard = 0;
	self.maxIndexForVisibleCard = countOfVisibleCards - 1;
	self.panGestureRecognizer.enabled = self.isDragEnabled;

	[self _configureVisibleCard];

	if ([self.delegate respondsToSelector:@selector(cardView:didDisplayTopCard:)]) {
		[self.delegate cardView:self didDisplayTopCard:[self topCard]];
	}
}

#pragma mark - 创建卡片

- (UIView *)_getAndAppendCardForIndex:(NSUInteger)index
{
	UIView *card = [self.delegate cardView:self viewForCardAtIndex:index];
	NSAssert(card, @"-[LXCardViewDelegate cardView:viewForCardAtIndex:] 方法不能返回 nil.");
	[self insertSubview:card atIndex:0];
	[self.visibleCards addObject:card];
	return card;
}

- (LXReusableCard *)dequeueReusableCardWithReuseIdentifier:(NSString *)identifier
{
	NSMutableSet<LXReusableCard *> *cacheForIdentifier = self.reusableCardCache[identifier];

	if (!cacheForIdentifier) {
		return nil;
	}

	if (cacheForIdentifier.count == 0) {
		return nil;
	}

	LXReusableCard *card = [cacheForIdentifier anyObject];
	[card prepareForReuse];
	[cacheForIdentifier removeObject:card];
	return card;
}

#pragma mark - 配置卡片

- (void)_setupConstraintsForCard:(UIView *)card
{
	if (card.translatesAutoresizingMaskIntoConstraints) {
		card.translatesAutoresizingMaskIntoConstraints = NO;
		CGFloat constants[] = { CGRectGetWidth(card.bounds), CGRectGetHeight(card.bounds) };
		NSLayoutAttribute attributes[] = { NSLayoutAttributeWidth, NSLayoutAttributeHeight };
		for (int i = 0; i < 2; ++i) {
			[NSLayoutConstraint constraintWithItem:card
										 attribute:attributes[i]
										 relatedBy:NSLayoutRelationEqual
											toItem:nil
										 attribute:attributes[i]
										multiplier:1
										  constant:constants[i]].active = YES;
		}

	}
	NSLayoutAttribute attributes[] = { NSLayoutAttributeCenterX, NSLayoutAttributeCenterY };
	for (int i = 0; i < 2; ++i) {
		[NSLayoutConstraint constraintWithItem:card
									 attribute:attributes[i]
									 relatedBy:NSLayoutRelationEqual
										toItem:self
									 attribute:attributes[i]
									multiplier:1
									  constant:0].active = YES;
	}
}

- (void)_configureVisibleCard
{
	[self.visibleCards enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
		[self _configureCard:obj atIndex:idx];
	}];
}

- (void)_configureCard:(UIView *)card atIndex:(NSUInteger)index
{
	// 随着索引变化，透明度变化 30%，水平缩放变化 10%，向下平移 10点
	card.alpha = 1 - 0.3 * index;
	card.transform = CGAffineTransformMake(1 - 0.1 * index, 0, 0, 1, 0, 10.0 * index);
}

#pragma mark - 卡片光栅化

- (void)_enableTopCardRasterize
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");

	topCard.layer.shouldRasterize = YES;
	topCard.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

- (void)_disableTopCardRasterize
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");

	topCard.layer.shouldRasterize = NO;
}

#pragma mark - 拖拽处理

- (void)_panGestureHandle:(UIPanGestureRecognizer *)panGR
{
	switch (panGR.state) {
		case UIGestureRecognizerStateBegan: {
			// 顶层卡片不存在，或者触摸点不在顶层卡片上，直接取消手势
			if (![self topCard] || !CGRectContainsPoint([self topCard].frame, [panGR locationInView:self])) {
				panGR.enabled = NO;
			} else {
				[self _enableTopCardRasterize];
				[self _setupAttachmentBehaviorForTopCard];
			}
		} break;

		case UIGestureRecognizerStateChanged: {
			[self _updateTopCardPositionByPan];
		} break;

		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled: {
			// 手势被手动取消了
			if (!panGR.isEnabled) {
				panGR.enabled = YES;
				break;
			}

			[self _removeAllBehaviors];

			UIView *topCard = [self topCard];
			NSAssert(topCard, @"topCard 不存在.");

			CGPoint currentPosition = topCard.layer.presentationLayer.position;
			CGPoint originalPosition = { CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) };
			CGFloat offsetH = ABS(currentPosition.x - originalPosition.x);
			CGFloat offsetV = ABS(currentPosition.y - originalPosition.y);
			UIOffset maxOffset = {
				self.maxOffset.horizontal > 0 ? self.maxOffset.horizontal : CGRectGetWidth(topCard.bounds) / 2,
				self.maxOffset.vertical > 0 ? self.maxOffset.vertical : CGRectGetHeight(topCard.bounds) / 2,
			};

			CGPoint velocity = [panGR velocityInView:self];
			CGFloat speed = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2));

			if (speed > kThrowingSpeedThreshold) {
				UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[topCard]];
				[dynamicItemBehavior addLinearVelocity:velocity forItem:topCard];
				[self _throwTopCardWithDynamicBehavior:dynamicItemBehavior];
			}
			else if (offsetH > maxOffset.horizontal || maxOffset.vertical < offsetV) {
				CGVector vector = { currentPosition.x - originalPosition.x, currentPosition.y - originalPosition.y };
				UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[topCard] mode:UIPushBehaviorModeInstantaneous];
				pushBehavior.pushDirection = vector;
				[self _throwTopCardWithDynamicBehavior:pushBehavior];
			}
			else {
				[self _resetTopCard];
			}
		} break;

		default: break;
	}
}

- (void)_setupAttachmentBehaviorForTopCard
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");

	CGPoint location = [self.panGestureRecognizer locationInView:self];
	CGPoint locationInCard = [self.panGestureRecognizer locationInView:topCard];
	CGPoint position = CGPointMake(CGRectGetMidX(topCard.bounds), CGRectGetMidY(topCard.bounds));
	UIOffset offset = UIOffsetMake(locationInCard.x - position.x, locationInCard.y - position.y);

	[self.dynamicAnimator removeAllBehaviors];
	self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:topCard offsetFromCenter:offset attachedToAnchor:location];
	[self.dynamicAnimator addBehavior:self.attachmentBehavior];
}

- (void)_updateTopCardPositionByPan
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");
	NSAssert(self.attachmentBehavior, @"attachmentBehavior 属性为 nil.");
	NSAssert(self.dynamicAnimator.behaviors.count == 1, @"尚有其他 Dynamic Behavior.");
	NSAssert(self.dynamicAnimator.behaviors[0] == self.attachmentBehavior, @"尚未添加 Attachment Behavior.");

	CGPoint translation = [self.panGestureRecognizer translationInView:self];
	CGPoint location = [self.panGestureRecognizer locationInView:self];
	self.attachmentBehavior.anchorPoint = location;

	if ([self.delegate respondsToSelector:@selector(cardView:didDragTopCard:anchorPoint:translation:)]) {
		[self.delegate cardView:self didDragTopCard:topCard anchorPoint:location translation:translation];
	}
}

- (void)_removeAllBehaviors
{
	self.attachmentBehavior = nil;
	[self.dynamicAnimator removeAllBehaviors];
}

#pragma mark - 复原卡片

- (void)_resetTopCard
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");
	NSAssert(self.dynamicAnimator.behaviors.count == 0, @"尚未清空 Dynamic Behavior.");

	self.userInteractionEnabled = NO;

	if ([self.delegate respondsToSelector:@selector(cardView:willResetTopCard:)]) {
		[self.delegate cardView:self willResetTopCard:topCard];
	}

	topCard.center = topCard.layer.presentationLayer.position;
	[UIView animateWithDuration:kResetAnimationDuration animations:^{
		topCard.transform = CGAffineTransformIdentity;
		topCard.center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
	} completion:^(BOOL finished) {
		[self _disableTopCardRasterize];
		self.userInteractionEnabled = YES;
		if ([self.delegate respondsToSelector:@selector(cardView:didResetTopCard:)]) {
			[self.delegate cardView:self didResetTopCard:topCard];
		}
	}];
}

#pragma mark - 移除卡片

- (void)_throwTopCardWithDynamicBehavior:(UIDynamicBehavior *)dynamicBehavior
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");
	NSAssert(self.dynamicAnimator.behaviors.count == 0, @"尚未清空 Dynamic Behavior.");

	topCard.center = topCard.layer.presentationLayer.position;

	self.userInteractionEnabled = NO;

	__block int count = 0;
	__weak typeof(self) weakSelf = self;
	dynamicBehavior.action = ^{
		__strong typeof(weakSelf) self = weakSelf;
		// 由于此block调用非常频繁，因此限制一下判断次数
		if (count++ % 2) {
			return;
		}
		if (!CGRectIntersectsRect(self.bounds, topCard.frame)) {
			[self _removeAllBehaviors];
			[self _recycleThrowedCard];
			[self _updateVisibleCardAfterThrow];
		}
	};

	[self.dynamicAnimator addBehavior:dynamicBehavior];
}

- (void)throwTopCardOnDirection:(LXCardViewDirection)direction angle:(CGFloat)angle
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");

	CGFloat factorH = (angle < M_PI_2) ? +1.0 : -1.0;
	CGFloat factorV = (direction == LXCardViewDirectionTop) ? -1.0 : +1.0;
	CGFloat horizontalDistance = (CGRectGetWidth(self.bounds) + CGRectGetWidth(topCard.bounds)) / 2;
	CGPoint position = {};
	position.x = CGRectGetMidX(self.bounds) + factorH * horizontalDistance;
	position.y = CGRectGetMidY(self.bounds) + factorV * tan(angle) * position.x;

	[self _enableTopCardRasterize];

	self.userInteractionEnabled = NO;
	[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		topCard.center = position;
	} completion:^(BOOL finished) {
		if ([self.delegate respondsToSelector:@selector(cardView:didThrowTopCard:)]) {
			[self.delegate cardView:self didThrowTopCard:topCard];
		}
		[self _recycleThrowedCard];
		[self _updateVisibleCardAfterThrow];
	}];
	
}

#pragma mark - 回收卡片

- (void)_recycleThrowedCard
{
	LXReusableCard *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");

	NSMutableSet<LXReusableCard *> *cacheForIdentifier = self.reusableCardCache[topCard.reuseIdentifier];
	if (!cacheForIdentifier) {
		cacheForIdentifier = [NSMutableSet new];
		self.reusableCardCache[topCard.reuseIdentifier] = cacheForIdentifier;
	}
	[cacheForIdentifier addObject:topCard];
}

#pragma mark - 更新卡片

- (void)_updateVisibleCardAfterThrow
{
	UIView *topCard = [self topCard];
	NSAssert(topCard, @"topCard 不存在.");

	[topCard removeFromSuperview];
	[self _disableTopCardRasterize];
	[self.visibleCards removeObjectAtIndex:0];

	if (self.countOfVisibleCards == 0) {
		self.userInteractionEnabled = YES;
		return;
	}

	if (self.indexForTopCard < self.numberOfCards - 1) {
		self.indexForTopCard += 1;
	}

	if (self.maxIndexForVisibleCard < self.numberOfCards - 1) {
		self.maxIndexForVisibleCard += 1;
		[self _setupConstraintsForCard:[self _getAndAppendCardForIndex:self.maxIndexForVisibleCard]];
	}

	// 新插入到后方的卡片不要使用动画，直接和前一张卡片重合
	if (self.countOfVisibleCards == self.maxCountOfVisibleCards) {
		[self _configureCard:self.visibleCards.lastObject atIndex:self.countOfVisibleCards - 1];
	}

	[UIView animateWithDuration:kInsertAnimationDuration animations:^{
		[self.visibleCards enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
			[self _configureCard:obj atIndex:idx];
		}];
	} completion:^(BOOL finished) {
		self.userInteractionEnabled = YES;
		if ([self.delegate respondsToSelector:@selector(cardView:didDisplayTopCard:)]) {
			[self.delegate cardView:self didDisplayTopCard:[self topCard]];
		}
	}];
}

#pragma mark - 拖拽开关

- (void)setDragEnabled:(BOOL)dragEnabled
{
	_dragEnabled = dragEnabled;
	self.panGestureRecognizer.enabled = dragEnabled;
}

#pragma mark - 卡片信息

- (UIView *)topCard
{
	return self.visibleCards.firstObject;
}

- (NSUInteger)countOfVisibleCards
{
	return self.visibleCards.count;
}

@end
