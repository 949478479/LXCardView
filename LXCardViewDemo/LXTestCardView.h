//
//  LXTestCardView.h
//  LXCardViewDemo
//
//  Created by 从今以后 on 16/4/23.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXTestCardView : UIView

@property (nonatomic) IBOutlet UILabel *addLabel;
@property (nonatomic) IBOutlet UILabel *removeLabel;

@property (nonatomic) void (^addAction)(void);
@property (nonatomic) void (^removeAction)(void);

+ (instancetype)cardView;

@end
