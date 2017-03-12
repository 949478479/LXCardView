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
	LXCardViewDirectionTop,
	LXCardViewDirectionBottom,
};

@protocol LXCardViewDelegate <NSObject>

@required

/// 卡片总数量，若返回零，则不显示任何卡片
- (NSUInteger)numberOfCardsInCardView:(LXCardView *)cardView;
/// 索引位置卡片所对应的视图
- (UIView *)cardView:(LXCardView *)cardView viewForCardAtIndex:(NSUInteger)index;

@optional

/// 顶层卡片处于拖拽之中
- (void)cardView:(LXCardView *)cardView didDragTopCard:(UIView *)topCard anchorPoint:(CGPoint)anchorPoint translation:(CGPoint)translation;
/// 顶层卡片即将回复原位
- (void)cardView:(LXCardView *)cardView willResetTopCard:(UIView *)topCard;
/// 顶层卡片完全回复原位
- (void)cardView:(LXCardView *)cardView didResetTopCard:(UIView *)topCard;
/// 顶层卡片完全被扔出
- (void)cardView:(LXCardView *)cardView didThrowTopCard:(UIView *)topCard;
/// 顶层卡片完全显示
- (void)cardView:(LXCardView *)cardView didDisplayTopCard:(UIView *)topCard;

@end

@interface LXCardView : UIView

/// 是否允许拖拽卡片，默认允许
@property (nonatomic, getter=isDragEnabled) BOOL dragEnabled;
/// 顶层卡片拖拽点最大偏移量绝对值，若不设置，则以顶层卡片宽高一半来计算
@property (nonatomic) UIOffset maxOffset;
/// 最大可见卡片数量，默认为 3
@property (nonatomic) NSUInteger maxCountOfVisibleCards;

@property (nullable, nonatomic, weak) IBOutlet id<LXCardViewDelegate> delegate;

/// 刷新数据，需主动调用
- (void)reloadData;

/**
 沿指定方向扔出顶层卡片

 @param direction 飞出方向
 @param angle     飞出方向和 x 正轴夹角
 */
- (void)throwTopCardOnDirection:(LXCardViewDirection)direction angle:(CGFloat)angle;

/// 顶层卡片
- (nullable UIView *)topCard;
/// 顶层卡片的索引
- (NSUInteger)indexForTopCard;
/// 屏幕上可见卡片数量
- (NSUInteger)countOfVisibleCards;

@end

NS_ASSUME_NONNULL_END
