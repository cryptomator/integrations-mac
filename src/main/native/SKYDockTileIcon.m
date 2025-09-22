//
//  SKYDockTileIcon.m
//  Integrations
//
//  Created by Tobias Hagemann on 22.09.25.
//  Copyright © 2025 Cryptomator. All rights reserved.
//

#import "SKYDockTileIcon.h"
#import <AppKit/AppKit.h>

@implementation SKYDockTileIcon

+ (BOOL)applyDockTileIconNamed:(NSString *_Nonnull)resourceName ofType:(NSString *)resourceType {
	NSString *path = [NSBundle.mainBundle pathForResource:resourceName ofType:resourceType];
	NSImage *icon = [[NSImage alloc] initWithContentsOfFile:path];
	if (icon == nil) {
		return NO;
	}
	NSDockTile *dockTile = NSApp.dockTile;
	NSSize tileSize = dockTile.size;
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, tileSize.width, tileSize.height)];
	imageView.image = icon;
	imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
	imageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	imageView.imageAlignment = NSImageAlignCenter;
	dockTile.contentView = imageView;
	[dockTile display];
	return YES;
}

@end
