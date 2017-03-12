//
//  LXTestCardView.m
//  LXCardViewDemo
//
//  Created by 从今以后 on 16/4/23.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "LXTestCardView.h"

@interface LXTestCardView ()

@property (nonatomic) IBInspectable NSString *reuseIdentifier;

@property (nonatomic) IBOutlet UIButton *addButton;
@property (nonatomic) IBOutlet UIButton *removeButton;

@end

@implementation LXTestCardView

- (void)awakeFromNib
{
    [super awakeFromNib];

	NSLog(@"%@", @(__FUNCTION__));

    self.layer.cornerRadius = 10;

    self.addLabel.layer.borderWidth = 5;
    self.addLabel.layer.borderColor = [UIColor redColor].CGColor;
    self.addLabel.layer.cornerRadius = CGRectGetWidth(self.addLabel.bounds) / 2;

    self.removeLabel.layer.borderWidth = 5;
    self.removeLabel.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.removeLabel.layer.cornerRadius = CGRectGetWidth(self.removeLabel.bounds) / 2;

    self.removeButton.layer.borderWidth = 1;
    self.removeButton.layer.borderColor = [UIColor colorWithRed:0.400 green:1.000 blue:0.400 alpha:1.000].CGColor;
    self.removeButton.layer.cornerRadius = CGRectGetHeight(self.removeButton.bounds) / 2;

    self.addButton.layer.borderWidth = 1;
    self.addButton.layer.borderColor = [UIColor colorWithRed:1.000 green:0.502 blue:0.000 alpha:1.000].CGColor;
    self.addButton.layer.cornerRadius = CGRectGetHeight(self.addButton.bounds) / 2;
}

+ (instancetype)cardView
{
    return [[UINib nibWithNibName:@"LXTestCardView" bundle:nil] instantiateWithOwner:nil options:nil][0];
}

- (IBAction)addAction:(id)sender
{
    !self.addAction ?: self.addAction();
}

- (IBAction)removeAction:(id)sender
{
    !self.removeAction ?: self.removeAction();
}

- (void)prepareForReuse
{
	self.addLabel.alpha = 0;
	self.removeLabel.alpha = 0;
}

@end
