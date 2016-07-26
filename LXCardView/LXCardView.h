//
//  LXCardView.h
//  LXCardViewDemo
//
//  Created by 从今以后 on 16/4/20.
//  Copyright © 2016年 从今以后. All rights reserved.
//

@import UIKit;
@class LXCardView;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LXCardViewDirection) {
    LXCardViewDirectionLeft,
    LXCardViewDirectionRight,
};

@protocol LXCardViewDelegate <NSObject>

@required

/// 卡片总数量
- (NSUInteger)numberOfCardsInCardView:(LXCardView *)cardView;

/// 索引对应的卡片所对应的视图
- (UIView *)cardView:(LXCardView *)cardView viewForCardAtIndex:(NSUInteger)index;

@optional

/// 顶层卡片位置发生变化
- (void)topCard:(UIView *)card didChangeCenterOffset:(CGPoint)offset inCardView:(LXCardView *)cardView;

/// 顶层卡片被移除
- (void)cardView:(LXCardView *)cardView didRemoveTopCard:(UIView *)card onDirection:(LXCardViewDirection)direction atIndex:(NSUInteger)index;
@end


@interface LXCardView : UIView

/// 是否允许拖拽卡片，默认允许
@property (nonatomic) BOOL enablePan;

/// 顶层卡片在水平方向上的最大偏移量，若不设置，则以顶层卡片宽度一半来计算
@property (nonatomic) CGFloat maxOffsetXForTopCard;

/// 最大可见卡片数量，默认为3
@property (nonatomic) NSUInteger maxCountOfVisibleCards;

@property (nullable, nonatomic, weak) IBOutlet id<LXCardViewDelegate> delegate;

/// 刷新数据，需手动调用
- (void)reloadData;

/// 沿指定方向移除顶层卡片，不会触发卡片位置变化的代理方法，但会触发卡片被移除的代理方法
- (void)removeTopCardOnDirection:(LXCardViewDirection)direction;

@end

NS_ASSUME_NONNULL_END
