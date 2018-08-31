//
//  imgASCAppDelegate.h
//  imgASC
//
//  Created by Masanori Kanda on 11/05/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface imgASCAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
