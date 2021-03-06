//
//  SJVideoPlayerPresentView.m
//  SJVideoPlayerProject
//
//  Created by BlueDancer on 2017/11/29.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJVideoPlayerPresentView.h"
#import <AVFoundation/AVPlayerLayer.h>
#import <Masonry/Masonry.h>

NS_ASSUME_NONNULL_BEGIN

@interface SJVideoPlayerPresentView ()

@property (nonatomic, strong, readonly) UIImageView *placeholderImageView;

@end

NS_ASSUME_NONNULL_END

@implementation SJVideoPlayerPresentView

@synthesize placeholderImageView = _placeholderImageView;

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)avLayer {
    return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ( !self ) return nil;
    [self _presentSetupView];
    [self _addObserver];
    return self;
}

#pragma mark -

- (void)_addObserver {
    [self.avLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
#ifndef DEBUG
    NSLog(@"%zd - %s", __LINE__, __func__);
#endif
    [self.avLayer removeObserver:self forKeyPath:@"readyForDisplay"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ( [keyPath isEqualToString:@"readyForDisplay"] ) {
        if ( self.readyForDisplay ) self.readyForDisplay(self, self.avLayer.videoRect);
    }
}

#pragma mark -

- (void)setPlayer:(AVPlayer *)player {
    if ( player == _player ) return;
    self.avLayer.player = player;
}

- (void)setPlaceholder:(UIImage *)placeholder {
    if ( placeholder == _placeholder ) return;
    _placeholder = placeholder;
    _placeholderImageView.image = placeholder;
}

- (void)setPlayState:(SJVideoPlayerPlayState)playState {
    _playState = playState;
    [UIView animateWithDuration:0.5 animations:^{
        switch ( playState ) {
            case SJVideoPlayerPlayState_Unknown:
            case SJVideoPlayerPlayState_Prepare: {
                _placeholderImageView.alpha = 1;
            }
                break;
            case SJVideoPlayerPlayState_Playing: {
                _placeholderImageView.alpha = 0.001;
            }
                break;
            case SJVideoPlayerPlayState_Buffing:
            case SJVideoPlayerPlayState_Paused:
            case SJVideoPlayerPlayState_PlayEnd:
            case SJVideoPlayerPlayState_PlayFailed: break;
        }
    }];
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    [self avLayer].videoGravity = videoGravity.copy;
}

- (AVLayerVideoGravity)videoGravity {
    return [self avLayer].videoGravity;
}

#pragma mark -

- (void)_presentSetupView {
    self.backgroundColor = [UIColor blackColor];
    [self addSubview:self.placeholderImageView];
    [_placeholderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
}

- (UIImageView *)placeholderImageView {
    if ( _placeholderImageView ) return _placeholderImageView;
    _placeholderImageView = [UIImageView new];
    _placeholderImageView.contentMode = UIViewContentModeScaleAspectFill;
    _placeholderImageView.clipsToBounds = YES;
    return _placeholderImageView;
}

@end
