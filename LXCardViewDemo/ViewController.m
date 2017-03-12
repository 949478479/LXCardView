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

	LXTestCardView *card = [cardView dequeueReusableCardWithReuseIdentifier:@"LXTestCardView"];
	if (!card) {
		card = [LXTestCardView cardView];
		card.frame = ({
			CGSize screenSize = [UIScreen mainScreen].bounds.size;
			CGRect frame = card.frame;
			frame.size = CGSizeMake(screenSize.width - 40, screenSize.height - 64 - 80);
			frame;
		});
		__weak LXCardView *weakCardView = cardView;
		card.addAction = ^{
			[weakCardView throwTopCardOnDirection:LXCardViewDirectionTop angle:M_PI_2 / 2];
		};
		card.removeAction = ^{
			[weakCardView throwTopCardOnDirection:LXCardViewDirectionBottom angle:M_PI_2 * 3 / 2];
		};
	}

	card.indexLabel.text = [NSString stringWithFormat:@"%lu", index];

    return card;
}

- (void)cardView:(LXCardView *)cardView didDisplayTopCard:(UIView *)topCard
{
	NSLog(@"%@ - %@", @(__FUNCTION__), @([cardView indexForTopCard]));
}

- (void)cardView:(LXCardView *)cardView didDragTopCard:(LXTestCardView *)topCard anchorPoint:(CGPoint)anchorPoint translation:(CGPoint)translation
{
	CGFloat alpha = fmax(0, fmin(1, (fabs(translation.x) / CGRectGetWidth(topCard.bounds) * 2)));

    if (translation.x > 0) {
		[(LXTestCardView *)topCard addLabel].alpha = alpha;
    } else if (translation.x < 0) {
        [(LXTestCardView *)topCard removeLabel].alpha = alpha;
    } else {
        [(LXTestCardView *)topCard addLabel].alpha = 0;
        [(LXTestCardView *)topCard removeLabel].alpha = 0;
    }
}

- (void)cardView:(LXCardView *)cardView willResetTopCard:(UIView *)topCard
{
	NSLog(@"%@ - %@", @(__FUNCTION__), @([cardView indexForTopCard]));

	[(LXTestCardView *)topCard addLabel].alpha = 0;
	[(LXTestCardView *)topCard removeLabel].alpha = 0;
}

- (void)cardView:(LXCardView *)cardView didResetTopCard:(UIView *)topCard
{
	NSLog(@"%@ - %@", @(__FUNCTION__), @([cardView indexForTopCard]));
}

- (void)cardView:(LXCardView *)cardView didThrowTopCard:(UIView *)topCard
{
    NSLog(@"%@ - %@", @(__FUNCTION__), @([cardView indexForTopCard]));
}

@end
