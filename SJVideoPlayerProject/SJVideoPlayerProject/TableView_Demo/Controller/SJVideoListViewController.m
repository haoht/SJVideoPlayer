//
//  SJVideoListViewController.m
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2018/1/13.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJVideoListViewController.h"
#import <SJUIFactory.h>
#import <Masonry.h>
#import "SJVideoListTableViewCell.h"
#import "SJVideoModel.h"
#import "SJVideoPlayer.h"
#import <SJFullscreenPopGesture/UIViewController+SJVideoPlayerAdd.h>
#import <UIView+SJUIFactory.h>
#import <NSMutableAttributedString+ActionDelegate.h>

static NSString *const SJVideoListTableViewCellID = @"SJVideoListTableViewCell";

@interface SJVideoListViewController ()<UITableViewDelegate, UITableViewDataSource, SJVideoListTableViewCellDelegate, NSAttributedStringActionDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong) NSArray<SJVideoModel *> *videosM;
@property (nonatomic, strong) SJVideoPlayer *videoPlayer;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) BOOL showTitle;

@end

@implementation SJVideoListViewController

@synthesize tableView = _tableView;

- (void)dealloc {
    NSLog(@"%zd - %s", __LINE__, __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _setRightNavItems_Test];
    
    // setup views
    [self _videoListSetupViews];
    
    self.tableView.alpha = 0.001;
    
    // prepare test data.
    [self.indicator startAnimating];
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 生成测试数据
        NSArray<SJVideoModel *> *videos = [SJVideoModel videoModelsWithActionDelegate:self];
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            [self.indicator stopAnimating];
            self.videosM = videos;
            [UIView animateWithDuration:0.25 animations:^{
                self.tableView.alpha = 1;
            }];
            [self.tableView reloadData];
        });
    });
    
    // pop gesture
    self.sj_viewWillBeginDragging = ^(SJVideoListViewController *vc) {
        // video player stop roatation
        vc.videoPlayer.disableRotation = YES;   // 触发全屏手势时, 禁止播放器旋转
    };
    
    self.sj_viewDidEndDragging = ^(SJVideoListViewController *vc) {
        // video player enable roatation
        vc.videoPlayer.disableRotation = NO;    // 恢复
    };
    
    // Do any additional setup after loading the view.
}

// 测试
- (void)_setRightNavItems_Test {
    UIBarButtonItem *show = [[UIBarButtonItem alloc] initWithTitle:@"ShowTitle" style:UIBarButtonItemStyleDone target:self action:@selector(show_Title)];
    UIBarButtonItem *hidden = [[UIBarButtonItem alloc] initWithTitle:@"HiddenTitle" style:UIBarButtonItemStyleDone target:self action:@selector(hidden_Title)];
    self.navigationItem.rightBarButtonItems = @[show, hidden];
}

- (void)show_Title {
    self.showTitle = YES;
    [self clickedPlayOnTabCell:self.tableView.visibleCells.firstObject playerParentView:[self.tableView.visibleCells.firstObject valueForKey:@"coverImageView"]];
}

- (void)hidden_Title {
    self.showTitle = NO;
    [self clickedPlayOnTabCell:self.tableView.visibleCells.firstObject playerParentView:[self.tableView.visibleCells.firstObject valueForKey:@"coverImageView"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _videoPlayer.disableRotation = NO;  // 恢复旋转
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _videoPlayer.disableRotation = YES; // 消失的时候, 禁止播放器旋转
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ( !_videoPlayer.userPaused ) [_videoPlayer play]; // 是否恢复播放
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_videoPlayer pause];   // 消失的时候, 暂停播放
}

#pragma mark -
- (UIActivityIndicatorView *)indicator {
    if ( _indicator ) return _indicator;
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _indicator.csj_size = CGSizeMake(80, 80);
    _indicator.center = self.view.center;
    _indicator.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.670];
    _indicator.clipsToBounds = YES;
    _indicator.layer.cornerRadius = 6;
    [self.view addSubview:_indicator];
    return _indicator;
}

#pragma mark -

- (void)_videoListSetupViews {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
}

- (UITableView *)tableView {
    if ( _tableView ) return _tableView;
    _tableView = [SJUITableViewFactory tableViewWithStyle:UITableViewStylePlain backgroundColor:[UIColor whiteColor] separatorStyle:UITableViewCellSeparatorStyleNone showsVerticalScrollIndicator:YES delegate:self dataSource:self];
    [_tableView registerClass:NSClassFromString(SJVideoListTableViewCellID) forCellReuseIdentifier:SJVideoListTableViewCellID];
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _videosM.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SJVideoListTableViewCell heightWithContentHeight:_videosM[indexPath.row].contentHelper.contentHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SJVideoListTableViewCell * cell = (SJVideoListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SJVideoListTableViewCellID forIndexPath:indexPath];
    cell.model = _videosM[indexPath.row];
    cell.delegate = self;
    return cell;
}

#pragma mark

- (void)clickedPlayOnTabCell:(SJVideoListTableViewCell *)cell playerParentView:(UIView *)playerParentView {
    // old player fade out
    [_videoPlayer stopAndFadeOut];
    
    // create new player
    _videoPlayer = [SJVideoPlayer player];
    _videoPlayer.view.alpha = 0.001;
    [playerParentView addSubview:_videoPlayer.view];
    [_videoPlayer.view mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    _videoPlayer.generatePreviewImages = NO;
    
    // setting player
    __weak typeof(self) _self = self;

    _videoPlayer.willRotateScreen = ^(SJVideoPlayer * _Nonnull player, BOOL isFullScreen) {
        __strong typeof(_self) self = _self;
        if ( !self ) return ;
        [self setNeedsStatusBarAppearanceUpdate];
    };
    
    // Call when the `control view` is `hidden` or `displayed`.
    _videoPlayer.controlViewDisplayStatus = ^(SJVideoPlayer * _Nonnull player, BOOL displayed) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self setNeedsStatusBarAppearanceUpdate];
    };
    
    // fade in
    [UIView animateWithDuration:0.5 animations:^{
        _videoPlayer.view.alpha = 1;
    }];
    
    // set asset
    _videoPlayer.URLAsset =
    [[SJVideoPlayerURLAsset alloc] initWithAssetURL:[NSURL URLWithString:@"http://vod.lanwuzhe.com/b12ad5034df14bedbdf0e5654cbf7224/6fc3ba23d31743ea8b3c0192c1b83f86-5287d2089db37e62345123a1be272f8b.mp4?video="]
                                             scrollView:self.tableView
                                              indexPath:[self.tableView indexPathForCell:cell]
                                           superviewTag:playerParentView.tag];
    
    _videoPlayer.URLAsset.title = @"DIY心情转盘 #手工##手工制作#";
    _videoPlayer.URLAsset.alwaysShowTitle = self.showTitle;
}

#pragma mark -

- (BOOL)prefersStatusBarHidden {
    if ( _videoPlayer.isFullScreen ) return !_videoPlayer.controlViewDisplayed; // 全屏播放时, 使状态栏根据视频的控制层显示或隐藏
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ( _videoPlayer.isFullScreen ) return UIStatusBarStyleLightContent; // 全屏播放时, 使状态栏变成白色
    return UIStatusBarStyleDefault;
}

#pragma mark - other
- (void)attributedString:(NSAttributedString *)attrStr action:(NSAttributedString *)action {
    UIViewController *vc = [[self class] new];
    vc.title = action.string;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
