//
// ASJTagsView.m
//
// Copyright (c) 2016 Sudeep Jaiswal
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ASJTagsView.h"
#import "ASJTag.h"

#pragma mark - ASJTagsView

@interface ASJTagsView ()

@property (weak, nonatomic) ASJTag *tagView;
@property (copy, nonatomic) NSArray *tags;
@property (readonly, weak, nonatomic) NSBundle *tagsBundle;
@property (readonly, weak, nonatomic) NSNotificationCenter *notificationCenter;

- (void)setup;
- (void)setupDefaults;
- (void)listenForOrientationChanges;
- (void)orientationDidChange:(NSNotification *)note;
- (void)empty;
- (void)addTags;
- (void)setupBlocksForTagView:(ASJTag *)tagView;

@end

@implementation ASJTagsView

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    [self setup];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}

#pragma mark - Setup

- (void)setup
{
  [self setupDefaults];
  [self listenForOrientationChanges];
}

- (void)setupDefaults
{
  _tags = [[NSArray alloc] init];
  _tagColor = [UIColor clearColor];
  _tagTextColor = [UIColor whiteColor];
  _tagFont = [UIFont systemFontOfSize:15.0f];
  _cornerRadius = 4.0f;
  _tagSpacing = 8.0f;
  _isEditable = false;
}

#pragma mark - Orientation

- (void)listenForOrientationChanges
{
  [self.notificationCenter addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationDidChange:(NSNotification *)note
{
  [self reloadTagsView];
}

- (void)dealloc
{
  [self.notificationCenter removeObserver:self];
}

- (NSNotificationCenter *)notificationCenter
{
  return [NSNotificationCenter defaultCenter];
}

#pragma mark - Public

- (void)addTag:(NSString *)tag
{
  if (!tag.length) {
    return;
  }
  
  NSMutableArray *temp = [NSMutableArray array];
  [temp addObjectsFromArray:_tags];
  [temp addObject:tag];
  _tags = [NSArray arrayWithArray:temp];
  [self reloadTagsView];
}

- (void)appendTags:(NSArray<NSString *> *)tags
{
  if (!tags.count) {
    return;
  }
  
  for (__attribute__((unused)) id object in tags) {
    NSAssert([object isKindOfClass:[NSString class]], @"Tags must be of type NSString.");
  }
  
  NSMutableArray *temp = _tags.mutableCopy;
  [temp addObjectsFromArray:tags];
  _tags = [NSArray arrayWithArray:temp];
  [self reloadTagsView];
}

- (void)replaceTags:(NSArray<NSString *> *)tags
{
  if (!tags.count) {
    return;
  }
  
  for (__attribute__((unused)) id object in tags) {
    NSAssert([object isKindOfClass:[NSString class]], @"Tags must be of type NSString.");
  }
  
  NSMutableArray *temp = _tags.mutableCopy;
  [temp removeAllObjects];
  [temp addObjectsFromArray:tags];
  _tags = [NSArray arrayWithArray:temp];
  [self reloadTagsView];
}

- (void)deleteTag:(NSString *)tag
{
  NSMutableArray *temp = _tags.mutableCopy;
  [temp removeObject:tag];
  _tags = [NSArray arrayWithArray:temp];
  [self reloadTagsView];
}

- (void)deleteTagAtIndex:(NSInteger)idx
{
  NSMutableArray *temp = _tags.mutableCopy;
  [temp removeObjectAtIndex:idx];
  _tags = [NSArray arrayWithArray:temp];
  [self reloadTagsView];
}

- (void)deleteAllTags
{
    for (id view in self.subviews)
    {
        if (![view isKindOfClass:[ASJTag class]]) {
            continue;
        }
        [view removeFromSuperview];
    }
    
    _tags = nil;
}

#pragma mark - Creation

- (void)reloadTagsView
{
  [self empty];
  [self addTags];
}

- (void)empty
{
  for (id view in self.subviews)
  {
    if (![view isKindOfClass:[ASJTag class]]) {
      continue;
    }
    [view removeFromSuperview];
  }
}

- (void)addTags
{
  __block CGFloat padding = _tagSpacing;
  __block CGFloat x = padding;
  __block CGFloat y = padding;
  __block CGFloat containerWidth = self.bounds.size.width;
  
  [_tags enumerateObjectsUsingBlock:^(NSString *tag, NSUInteger idx, BOOL *stop)
   {
     ASJTag *tagView = self.tagView;
     tagView.tagText = tag;
     tagView.layer.borderColor = _borderColor.CGColor;
     tagView.layer.borderWidth = _borderWidth;
     tagView.layer.cornerRadius = _cornerRadius;
     tagView.tag = idx;
     
     CGSize size = [tagView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize
                          withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
                                verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
     
     CGFloat maxWidth = containerWidth - (2 * padding);
     if (size.width > maxWidth) {
       size = CGSizeMake(maxWidth, size.height);
     }
     
     CGRect rect = tagView.frame;
     rect.origin = CGPointMake(x, y);
     rect.size = size;
     tagView.frame = rect;
     x += (size.width + padding);
     
     if ((x >= containerWidth - padding) && (idx > 0))
     {
       x = padding;
       y += size.height + padding;
       
       CGRect rect = tagView.frame;
       rect.origin = CGPointMake(x, y);
       rect.size = size;
       tagView.frame = rect;
       
       x += (size.width + padding);
     }
     
     [self addSubview:tagView];
     
     // content size
     CGFloat bottom = tagView.frame.origin.y + tagView.frame.size.height + padding;
     self.contentSize = CGSizeMake(containerWidth, bottom);
   }];
}

- (ASJTag *)tagView
{
  NSString *nibName = NSStringFromClass([ASJTag class]);
  // int option = self.isEditable ? 1 : 0;
    
  ASJTag *tagView = (ASJTag *)[self.tagsBundle loadNibNamed:nibName owner:self options:nil][0];
  tagView.userInteractionEnabled = self.isEditable;
    
  // use the default theme if tag color is not set
  if (!_tagColor) {
      _tagColor = [UIColor clearColor];
  }
  
  tagView.backgroundColor = _tagColor;
  tagView.tagTextColor = _tagTextColor;
  tagView.crossImage = _crossImage;
  tagView.tagFont = _tagFont;
  
  [self setupBlocksForTagView:tagView];
  return tagView;
}

- (NSBundle *)tagsBundle
{
  return [NSBundle bundleForClass:[self class]];
}

- (void)setupBlocksForTagView:(ASJTag *)tagView
{
  [tagView setTapBlock:^(NSString *tagText, NSInteger idx)
   {
     if (_tapBlock) {
       _tapBlock(tagText, idx);
     }
   }];
  
  [tagView setDeleteBlock:^(NSString *tagText, NSInteger idx)
   {
     if (_deleteBlock) {
       _deleteBlock(tagText, idx);
     }
   }];
}

#pragma mark - Property setters

- (void)setIsEditable:(Boolean)isEditable
{
    _isEditable = isEditable;
}

- (void)setTagColor:(UIColor *)tagColor
{
  _tagColor = tagColor;
  [self reloadTagsView];
}

- (void)setTagTextColor:(UIColor *)tagTextColor
{
  _tagTextColor = tagTextColor;
  [self reloadTagsView];
}

- (void)setBorderColor:(UIColor *)borderColor
{
  _borderColor = borderColor;
  [self reloadTagsView];
}

- (void)setCrossImage:(UIImage *)crossImage
{
  _crossImage = crossImage;
  [self reloadTagsView];
}

- (void)setTagFont:(UIFont *)tagFont
{
  _tagFont = tagFont;
  [self reloadTagsView];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
  _borderWidth = borderWidth;
  [self reloadTagsView];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
  _cornerRadius = cornerRadius;
  [self reloadTagsView];
}

- (void)setTagSpacing:(CGFloat)tagSpacing
{
  _tagSpacing = tagSpacing;
  [self reloadTagsView];
}

@end
