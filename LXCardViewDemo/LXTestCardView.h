//
//  LXTestCardView.h
//  LXCardViewDemo
//
//  Created by 从今以后 on 16/4/23.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXCardView.h"

@interface LXTestCardView : UIView <LXCardViewReusableCard>

@property (nonatomic) IBOutlet UILabel *indexLabel;

@property (nonatomic) IBOutlet UILabel *addLabel;
@property (nonatomic) IBOutlet UILabel *removeLabel;

@property (nonatomic) void (^addAction)(void);
@property (nonatomic) void (^removeAction)(void);

@property (nonatomic, readonly) NSString *reuseIdentifier;

- (void)prepareForReuse;

+ (instancetype)cardView;

@end
