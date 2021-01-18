//
//  ZBFeaturedPackagesCollectionView.m
//  Zebra
//
//  Created by Andrew Abosh on 2021-01-06.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedPackagesCollectionView.h"

#import <Managers/ZBPackageManager.h>
#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <UI/Packages/Views/Cells/ZBFeaturedPackageCollectionViewCell.h>

#import <Extensions/NSArray+Random.h>

@import SDWebImage;

@interface ZBFeaturedPackagesCollectionView () {
    UIActivityIndicatorView *spinner;
}
@end

@implementation ZBFeaturedPackagesCollectionView

NSString *const ZBFeaturedCollectionViewCellReuseIdentifier = @"ZBFeaturedPackageCollectionViewCell"; // TODO: Move this to ZBFeaturedPackageCollectionViewCell?

#pragma mark - Initializers

- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16);
    
    self = [super initWithFrame:CGRectZero collectionViewLayout:layout];
    
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        [self registerNib:[UINib nibWithNibName:@"ZBFeaturedPackageCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:ZBFeaturedCollectionViewCellReuseIdentifier];
        [self setBackgroundColor:[UIColor systemBackgroundColor]];
        [self setShowsHorizontalScrollIndicator:NO];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.itemSize = CGSizeMake(0, spinner.frame.size.height + 16);
    }
    
    return self;
}

#pragma mark - Properties

- (void)setItemSize:(CGSize)itemSize {
    @synchronized (self) {
        if (_itemSize.height != itemSize.height) {
            _itemSize = itemSize;
            
            [self setNeedsLayout];
        }
    }
}

- (void)setFeaturedPackages:(NSArray *)posts {
    @synchronized (_featuredPackages) {
        _featuredPackages = posts;
        
        [self hideSpinner];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }
}

#pragma mark - Fetching Data

- (void)fetch {
    [self fetchFromSource:NULL];
}

- (void)fetchFromSource:(ZBSource *)source {
    [self showSpinner];
    
    NSMutableArray *sourcesToFetch = [NSMutableArray new];
    if (source) {
        [sourcesToFetch addObject:source];
    } else { // If sources is NULL, load from all sources
        [sourcesToFetch addObjectsFromArray:[[ZBSourceManager sharedInstance] sources]];
    }
    
    dispatch_group_t featuredGroup = dispatch_group_create();
    NSMutableArray *packages = [NSMutableArray new];
    for (ZBSource *source in sourcesToFetch) {
        if (!source.supportsFeaturedPackages) continue;
        
        NSURL *featuredPackagesURL = [[NSURL alloc] initWithString:@"sileo-featured.json" relativeToURL:source.mainDirectoryURL];
        if (!featuredPackagesURL) continue;
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:featuredPackagesURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSError *parseError = NULL;
            NSDictionary *featuredPackages = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:&parseError];
            if (featuredPackages && !error && !parseError) {
                NSArray *banners = featuredPackages[@"banners"];
                for (NSDictionary *banner in banners) {
                    NSString *identifier = banner[@"package"];
                    NSString *sourceUUID = source.uuid;
                    NSString *name = banner[@"title"];
                    NSString *description = [[ZBPackageManager sharedInstance] descriptionForPackageIdentifier:identifier fromSource:source];
                    NSURL *bannerURL = [NSURL URLWithString:banner[@"url"]];
                    
                    if (identifier && sourceUUID && name && description && bannerURL) {
                        NSDictionary *dictionary = @{@"identifier": identifier, @"source": sourceUUID, @"name": name, @"description": description, @"bannerURL": bannerURL};
                        [packages addObject:dictionary];
                    }
                }
            }
            dispatch_group_leave(featuredGroup);
        }];
        
        dispatch_group_enter(featuredGroup);
        [task resume];
    }
    
    dispatch_group_notify(featuredGroup, dispatch_get_main_queue(), ^{
        self.featuredPackages = source != NULL ? packages : [packages shuffleWithCount:10];
    });
}

#pragma mark - Activity Indicator

- (void)showSpinner {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundView = self->spinner;
        [self->spinner startAnimating];
    });
}

- (void)hideSpinner {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundView = nil;
        [self->spinner stopAnimating];
    });
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _featuredPackages.count > 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return MIN(_featuredPackages.count, 10);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZBFeaturedPackageCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:ZBFeaturedCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(ZBFeaturedPackageCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.itemSize.width == 0) {
        self.itemSize = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    }
    
    if (indexPath.row < _featuredPackages.count) {
        NSDictionary *package = _featuredPackages[indexPath.row];
        
        cell.repoLabel.text = [[ZBSourceManager sharedInstance] sourceWithUUID:package[@"source"]].label.uppercaseString;
        cell.packageLabel.text = package[@"name"];
        cell.descriptionLabel.text = package[@"description"];
        [cell.bannerImageView sd_setImageWithURL:package[@"bannerURL"]];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end