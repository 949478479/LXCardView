//
//  ViewController.m
//  LXCardViewDemo
//
//  Created by 从今以后 on 16/4/20.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "ViewController.h"
#import "LXCardView.h"
#import "LXTestCardView.h"

@interface ViewController () <LXCardViewDelegate>
@property (nonatomic) IBOutlet LXCardView *cardView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIWindow *window = [UIApplication sharedApplication].keyWindow;

    [window addSubview:self.cardView];

    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView.leadingAnchor constraintEqualToAnchor:window.leadingAnchor].active = YES;
    [self.cardView.trailingAnchor constraintEqualToAnchor:window.trailingAnchor].active = YES;
    [self.cardView.bottomAnchor constraintEqualToAnchor:window.bottomAnchor].active = YES;
    [self.cardView.topAnchor constraintEqualToAnchor:window.topAnchor constant:64].active = YES;
}

- (IBAction)reloadData:(UIBarButtonItem *)sender
{
    [self.cardView reloadData];
}

#pragma mark - <LXCardViewDelegate>

- (NSUInteger)numberOfCardsInCardView:(LXCardView *)cardView
{
    return 10;
}

- (UIView *)cardView:(LXCardView *)cardView viewForCardAtIndex:(NSUInteger)index
{
    NSLog(@"%@ - %@", @(__FUNCTION__), @(index));

    LXTestCardView *card = [LXTestCardView cardView];

    __weak LXCardView *weakCardView = cardView;
    card.addAction = ^{
        [weakCardView removeTopCardOnDirection:LXCardViewDirectionRight];
    };
    card.removeAction = ^{
        [weakCardView removeTopCardOnDirection:LXCardViewDirectionLeft];
    };
    
    return card;
}

- (void)topCard:(UIView *)card didChangeCenterOffset:(CGPoint)offset inCardView:(LXCardView *)cardView
{
    if (offset.x > 0) {
        [(LXTestCardView *)card addLabel].alpha = offset.x / (CGRectGetWidth(card.bounds) / 2);
    } else if (offset.x < 0) {
        [(LXTestCardView *)card removeLabel].alpha = -offset.x / (CGRectGetWidth(card.bounds) / 2);
    } else {
        [(LXTestCardView *)card addLabel].alpha = 0;
        [(LXTestCardView *)card removeLabel].alpha = 0;
    }
}

- (void)cardView:(LXCardView *)cardView didRemoveTopCard:(UIView *)card onDirection:(LXCardViewDirection)direction atIndex:(NSUInteger)index
{
    NSLog(@"%@ - %@ - %@ - %@", @(__FUNCTION__), card, (direction == LXCardViewDirectionLeft) ? @"left" : @"right", @(index));
}

- (void)cardView:(LXCardView *)cardView didDisplayTopCard:(UIView *)card atIndex:(NSUInteger)index
{
    NSLog(@"%@ - %@ - %@", @(__FUNCTION__), card, @(index));
}

@end
