//
//  MMStatusCell.m
//  WeChatTimeLine
//
//  Created by CorbinChen on 2017/3/24.
//  Copyright © 2017年 CorbinChen. All rights reserved.
//

#import "MMStatusCell.h"
#import "MMStatusMediaView.h"
#import "MMStatusImageMediaView.h"
#import "MMStatusLinkMediaView.h"
#import "MMStatus.h"
#import "MMStatusMediaObject.h"
#import "MMStatusImageMediaObject.h"
#import "MMStatusLinkMediaObject.h"

@implementation MMStatusCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.profileImageView.wantsLayer = true;
    self.profileImageView.layer.borderWidth = 0.5;
    self.profileImageView.layer.borderColor = [NSColor whiteColor].CGColor;
    self.profileImageView.layer.cornerRadius = 5;
    self.profileImageView.layer.masksToBounds = true;
}

- (void)updateViewWithStatus:(MMStatus *)status mediaView:(MMStatusMediaView *)mediaView {
    _status = status;
    self.profileImageView.image = [WeChatService(MMAvatarService) defaultAvatarImage];
    MMAvatarService *service = [[CBGetClass(MMServiceCenter) defaultCenter] getService:CBGetClass(MMAvatarService)];
    [service getAvatarImageWithUrl:status.profileImageURLString completion:^(NSImage *image) {
        self.profileImageView.image = image;
    }];
    self.nameTextField.stringValue = status.nameString;
    self.tagTextField.stringValue = [NSString stringWithFormat:@"%@%@", status.timeString, [status hasSource] ? [NSString stringWithFormat:@" - %@", status.sourceString] : @""];
    self.toContentTextFieldLayoutConstraint.active = [status hasContent];
    self.toTagTextFieldLayoutConstraint.active = ![status hasContent];
    self.contentTextField.attributedStringValue = status.contentAttributedString;
    self.likeButton.state = status.isLiked ? NSOnState : NSOffState;
    self.likeCountTextField.integerValue = status.likeCount;
    self.commentCountTextField.integerValue = status.commentCount;
    
    [self updateMediaView:mediaView];
    [self updateMediaView];
}

- (void)updateMediaView:(MMStatusMediaView *)mediaView {
    [self.mediaRealView removeFromSuperview];
    self.mediaRealView = nil;
    self.mediaRealView = mediaView;
    [self addSubview:mediaView];
    self.mediaRealView.translatesAutoresizingMaskIntoConstraints = false;
    if (self.mediaRealView) {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaRealView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.mediaView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaRealView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.mediaView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaRealView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.mediaView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.mediaRealView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.mediaView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    }
}

- (void)updateMediaView {
    switch (self.status.mediaType) {
        case MMStatusMediaObjectTypeImage:
            [self updateImageMediaView];
            break;
        case MMStatusMediaObjectTypeLink:
            [self updateLinkMediaView];
            break;
        default:
            break;
    }
}

- (void)updateImageMediaView {
    MMStatusImageMediaObject *mediaObject = (MMStatusImageMediaObject *)self.status.mediaObject;
    MMStatusImageMediaView *mediaView = (MMStatusImageMediaView *)self.mediaRealView;
    for (NSImageView *imageView in mediaView.imageViews) {
        imageView.hidden = true;
    }
    for (NSInteger i = 0; i < mediaObject.imageURLStrings.count; i ++) {
        NSString *imageURLString = mediaObject.imageURLStrings[i];
        NSImageView *imageView = mediaView.imageViews[i];
        imageView.hidden = false;
        imageView.image = nil;
        MMAvatarService *service = [[CBGetClass(MMServiceCenter) defaultCenter] getService:CBGetClass(MMAvatarService)];
        [service getAvatarImageWithUrl:imageURLString completion:^(NSImage *image) {
            imageView.image = image;
        }];
    }
}

- (void)updateLinkMediaView {
    MMStatusLinkMediaObject *mediaObject = (MMStatusLinkMediaObject *)self.status.mediaObject;
    MMStatusLinkMediaView *mediaView = (MMStatusLinkMediaView *)self.mediaRealView;
    mediaView.iconImageView.image = nil;
    MMAvatarService *service = [[CBGetClass(MMServiceCenter) defaultCenter] getService:CBGetClass(MMAvatarService)];
    [service getAvatarImageWithUrl:mediaObject.imageURLString completion:^(NSImage *image) {
        mediaView.iconImageView.image = image;
    }];
    mediaView.titleTextField.stringValue = mediaObject.title;
}

#pragma mark - Event

- (void)mouseUp:(NSEvent *)event {
    CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    
    if ([self mouse:point inRect:self.profileImageView.frame] || [self mouse:point inRect:self.nameTextField.frame]) {
        if ([self.delegate respondsToSelector:@selector(cell:didClickUser:)]) {
            [self.delegate cell:self didClickUser:self.status.username];
            return;
        }
    }
    
    if ([self.status hasMediaObject]) {
        switch (self.status.mediaType) {
            case MMStatusMediaObjectTypeLink: {
                BOOL isClickLinkView = [self mouse:point inRect:self.mediaRealView.frame];
                if (isClickLinkView && [self.delegate respondsToSelector:@selector(cell:didClickMediaLink:)]) {
                    [self.delegate cell:self didClickMediaLink:[(MMStatusLinkMediaObject *)self.status.mediaObject linkURLString]];
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)mouseDown:(NSEvent *)event {
    
}

#pragma mark - Height

+ (CGFloat)calculateHeightForStatus:(MMStatus *)status inTableView:(NSTableView *)tableView {
    CGFloat height = 55;
    if ([status hasContent]) {
        height += 5;
        NSRect rect = [status.contentAttributedString boundingRectWithSize:NSMakeSize(tableView.frame.size.width - 80, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
        height += rect.size.height; 
    }
    
    switch (status.mediaType) {
        case MMStatusMediaObjectTypeImage: {
            CGFloat imageSize = (tableView.frame.size.width - 80) / 3.0;
            MMStatusImageMediaObject *mediaObject = (MMStatusImageMediaObject *)status.mediaObject;
            NSInteger rowCount = (mediaObject.imageURLStrings.count - 1) / 3 + 1;
            height += (NSInteger)(rowCount * imageSize);
        }
            break;
        case MMStatusMediaObjectTypeLink:
            height += 40;
        default:
            break;
    }
    height += 30;
    return height;
}

@end
