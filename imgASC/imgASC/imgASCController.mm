//
//  imgASCController.m
//  imgASC
//
//  Created by Masanori Kanda on 11/05/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "imgASCController.h"


/*
@interface IKImageClipView : NSClipView
- (NSRect)docRect;
@end

@implementation ScrollViewWorkaround
- (void)reflectScrolledClipView:(NSClipView *)cView;
{
    NSView *_imageView = [self documentView];
    [super reflectScrolledClipView:cView];
    if ([_imageView isKindOfClass:[IKImageView class]] &&
        [[self contentView] isKindOfClass:[IKImageClipView class]] &&
        [[self contentView] respondsToSelector:@selector(docRect)]) {
        NSSize docSize = [(IKImageClipView *)[self contentView] docRect].size;
        NSSize scrollViewSize = [self contentSize];
        // NSLog(@"doc %@ scrollView %@", NSStringFromSize(docSize), NSStringFromSize(scrollViewSize));
        if (docSize.height > scrollViewSize.height || docSize.width > scrollViewSize.width)
            ((IKImageView *)_imageView).autohidesScrollers = NO;
        else
            ((IKImageView *)_imageView).autohidesScrollers = YES;
    }
}
@end
*/

/* for image undo object */
@interface myImageObject : NSObject
{
    NSString* path;
    NSString* chartext;
}
@end

@implementation myImageObject

-(id)init
{
    return [super init];
}

- (void)dealloc
{
//    remove([path UTF8String]);
    [path release];
    [chartext release];
    [super dealloc];
}

- (void)setPath:(NSString *)newpath
{
    if(path != newpath)
    {
//        remove([path UTF8String]);
        [path release];
        path = [newpath retain];
    }
}

- (NSString*)getPath
{
    return path;
}

- (void)setChartext:(NSString *)newchartext
{
    if(chartext != newchartext)
    {
        [chartext release];
        chartext = [newchartext retain];
    }
}

- (NSString*)getChartext
{
    return chartext;
}

#pragma mark -

@end


/* for image undo object */
@interface myIplImageObject : NSObject
{
    IplImage* iplimage;
    NSString* chartext;
}
@end

@implementation myIplImageObject

-(id)init
{
    iplimage=NULL;
    return [super init];
}

- (void)dealloc
{
    if( iplimage ){
        //cvReleaseImage(&iplimage);
        iplimage=NULL;
    }
    [chartext release];
    [super dealloc];
}

- (void)setIplimage:(IplImage*)newiplimage
{
    if( iplimage ){
        //cvReleaseImage(&iplimage);
        iplimage=NULL;
    }
    iplimage=newiplimage;
}

- (IplImage*)getIplimage
{
    return iplimage;
}

- (void)setChartext:(NSString *)newchartext
{
    if(chartext != newchartext)
    {
        [chartext release];
        chartext = [newchartext retain];
    }
}

- (NSString*)getChartext
{
    return chartext;
}

#pragma mark -

@end


@implementation DraggableImageView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	return self;
}

- (void)setParentController:(id)parent
{
	parentController=parent;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if( ![parentController isTracingNow] ){
		BOOL result=[super performDragOperation:sender];
		//NSLog(@"performDragOperation.");
		if( result ){
			[self setImage:nil imageProperties:nil];
			[self setImageWithURL:nil];
			NSPasteboard* pb = [sender draggingPasteboard];
			NSArray *arOfFilename = [pb propertyListForType:NSFilenamesPboardType];
			if ( [arOfFilename count] == 1 ){
				NSString* imgpath=[arOfFilename lastObject];
				NSURL* url=[NSURL fileURLWithPath:imgpath];
				[parentController openDragImage:url];
			}		
		}
		return TRUE;
	}
	return FALSE;
}

- (void)mouseUp:(NSEvent*)event
{
    if([event clickCount] == 2) {
        // Double click
        //NSLog(@"I got double click! mouseUp");
    }
    [super mouseUp:event];
}

- (void)mouseDown:(NSEvent *)event
{
    if([event clickCount] == 2) {
        // Double click
        //NSLog(@"I got double click! mouseDown");
    }
    else {
        [super mouseDown:event];
    }
}

@end



@implementation imgASCController

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)inSender
{
	return YES;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults* userdefault = [NSUserDefaults standardUserDefaults];
    
    m_tracemode=0;
    m_useZenkakuSpace=0;
    if( userdefault ){
        m_fontName = [userdefault stringForKey:@"fontname"];
        m_fontSize = [userdefault integerForKey:@"fontsize"];
        m_tracemode = [userdefault integerForKey:@"tracemode"];
        m_customCharset = [userdefault stringForKey:@"customcharset"];
        m_useZenkakuSpace = [userdefault integerForKey:@"usezenkakuSpace"];
    }
    NSString* tracetitlestr=@"";
    switch(m_tracemode){
        case 0: tracetitlestr=@"Pattern"; break;
        case 1: tracetitlestr=@"Edge"; break;
        case 2: tracetitlestr=@"Custom"; break;
    }
	[m_tracemodetool setTitle:tracetitlestr];

    if( m_fontSize==0 ){ m_fontSize=10; }
    if( [m_fontName length]==0 ){
        m_fontName=@"Courier";
        NSFont* reqfont=[NSFont fontWithName:@"MS-PGothic" size:10];
        if( reqfont!=nil ){
            m_fontName=@"MS-PGothic";
        }
    }
    if( [m_customCharset length]==0 ){	
        m_customCharset=NSLocalizedString(@"customtracecharacters",nil); 
    }
 
    NSString* titlestr=[NSString stringWithFormat:@"%@ %d", m_fontName, m_fontSize];
    [m_fonttool setTitle:titlestr];

    // Insert code here to initialize your application
}
 - (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // cleanup tempfolder
    NSString* systemcomstr =  [NSString stringWithFormat: @"rm -rf %@/com.mkanda.imgASCMAC", NSTemporaryDirectory()];
    system([systemcomstr UTF8String]);
    
    NSUserDefaults* userdefault = [NSUserDefaults standardUserDefaults];
	[userdefault setInteger:m_fontSize forKey:@"fontsize"];
	[userdefault setObject:m_fontName forKey:@"fontname"];
	[userdefault setObject:m_customCharset forKey:@"customcharset"];
	[userdefault setInteger:m_tracemode forKey:@"tracemode"];
    [userdefault setInteger:m_useZenkakuSpace forKey:@"usezenkakuSpace"];
    
    [userdefault synchronize];
}

-(IBAction)OnOKEditCustomChar:(id)sender
{
    m_customCharset=[m_edit_customchar stringValue];
    m_useZenkakuSpace=[m_check_useZenkakuspace intValue];
    m_tracemode=[m_segment_tracemode selectedSegment];
    NSString* tracetitlestr=@"";
    switch(m_tracemode){
        case 0: tracetitlestr=@"Pattern"; break;
        case 1: tracetitlestr=@"Edge"; break;
        case 2: tracetitlestr=@"Custom"; break;
    }
	[m_tracemodetool setTitle:tracetitlestr];

   	[NSApp endSheet:m_customCharWindow];
}

-(IBAction)OnChangeTraceModeSegmentCtrl:(id)sender
{
    m_tracemode=[m_segment_tracemode selectedSegment];
    switch(m_tracemode){
        case 0:
            [m_edit_PatterOrEdgeChar setStringValue:NSLocalizedString(@"patterntracecharacters", nil)];
            [m_edit_PatterOrEdgeChar setFont:[NSFont fontWithName:m_fontName size:12]];
            [m_edit_PatterOrEdgeChar setHidden:NO];
            [m_edit_customchar setHidden:YES];
             break;
        case 1:
            [m_edit_PatterOrEdgeChar setStringValue:NSLocalizedString(@"edgetracecharacters", nil)];
            [m_edit_PatterOrEdgeChar setFont:[NSFont fontWithName:m_fontName size:12]];
            [m_edit_PatterOrEdgeChar setHidden:NO];
            [m_edit_customchar setHidden:YES];
            break;
        case 2:
            [m_edit_customchar setStringValue:m_customCharset];
            [m_edit_customchar setFont:[NSFont fontWithName:m_fontName size:12]];
            [m_edit_PatterOrEdgeChar setHidden:YES];
            [m_edit_customchar setHidden:NO];
            break;

    }

}

-(IBAction)OnCancelEditCustomChar:(id)sender
{
   	[NSApp endSheet:m_customCharWindow];
}

- (void)customcharSheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:self];
	//NSLog(@"returnCode %d",returnCode);
}

-(IBAction)OnChangeTraceMode:(id)sender
{
    [m_edit_customchar setStringValue:m_customCharset];
    [m_segment_tracemode setSelectedSegment:m_tracemode];
    [m_check_useZenkakuspace setIntValue:m_useZenkakuSpace];
    [self OnChangeTraceModeSegmentCtrl:nil];
    
    // open custom character set
    [NSApp beginSheet:m_customCharWindow
       modalForWindow:m_dialog	//[[NSApplication sharedApplication] mainWindow]
        modalDelegate:self 
       didEndSelector:@selector(customcharSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
        
}

- (NSString*)tmpNameWithSuffix:(NSString*)path
{
    // create appfolder into the tempfolder
	NSString* tempfolderName = [NSString stringWithFormat: @"%@/com.mkanda.imgASCMAC", NSTemporaryDirectory()];
    mkdir([tempfolderName UTF8String] ,0744);
	NSString* newName = [NSString stringWithFormat: @"%@/com.mkanda.imgASCMAC/XXXXXX%@", NSTemporaryDirectory(), path];
	char *templatestr = (char*) [newName fileSystemRepresentation];
	int fd = mkstemps(templatestr, (int)[path length]);
	close(fd);
	return [NSString stringWithUTF8String:templatestr];
}

- (NSString*)tmpWorkNameWithSuffix:(NSString*)path
{
    // create appfolder into the tempfolder
	NSString* tempfolderName = [NSString stringWithFormat: @"%@/com.mkanda.imgASCMAC/work", NSTemporaryDirectory()];
    mkdir([tempfolderName UTF8String] ,0744);
	NSString* newName = [NSString stringWithFormat: @"%@/com.mkanda.imgASCMAC/work/XXXXXX%@", NSTemporaryDirectory(), path];
	char *templatestr = (char*) [newName fileSystemRepresentation];
	int fd = mkstemps(templatestr, (int)[path length]);
	close(fd);
	return [NSString stringWithUTF8String:templatestr];
}

-(IplImage*)NSImageToIplImage:(NSImage*)img
{
	NSBitmapImageRep *orig = [[img representations] objectAtIndex: 0];
	
	// [NSImage -representations] operates in-place, so we have to make
	// a copy or else the color-channel shift that we do later on will affect the original NSImage!
	NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[orig representationUsingType:NSTIFFFileType properties:NULL]];
	
	int depth = (int)[rep bitsPerSample];
	int channels = (int)[rep samplesPerPixel];
	int height = (int)[rep size].height;
	int width = (int)[rep size].width;
	
	// note- channels had better be "3", or else the loop down below will act pretty funky...
    // NSTIFFFileType seems to always give three-channel images, so I think it's okay...
	IplImage* to_return = cvCreateImage(cvSize(width, height), depth, channels); 
	
	// found this cvSetData trick here: http://www.osxentwicklerforum.de/thread.php?postid=89767
	cvSetData(to_return, [rep bitmapData], (int)[rep bytesPerRow]);
	
	// Reorder BGR to RGB
	// no, I don't know why it's in BGR after cvSetData
    /*
	for (int i = 0; i < to_return->imageSize; i += 3) {
		uchar tempR, tempG, tempB;
		tempR = to_return->imageData[i+2];
		tempG = to_return->imageData[i+1];
		tempB = to_return->imageData[i];
		
		to_return->imageData[i] = tempR;
		to_return->imageData[i+1] =tempG;
		to_return->imageData[i+2] = tempB;		
	}
     */
	return to_return;
}

-(NSImage*)IplImageToNSImage:(IplImage*)img
{
 	char *d = img->imageData; // Get a pointer to the IplImage image data.
	
	NSString *COLORSPACE;
	if(img->nChannels == 1){
		COLORSPACE = NSDeviceWhiteColorSpace;
	}
	else{
		COLORSPACE = NSDeviceRGBColorSpace;
	}
	
	NSBitmapImageRep *bmp = [[NSBitmapImageRep alloc]  
							 initWithBitmapDataPlanes:NULL 
							 pixelsWide:img->width 
							 pixelsHigh:img->height 
							 bitsPerSample:img->depth 
							 samplesPerPixel:img->nChannels  
							 hasAlpha:NO isPlanar:NO 
							 colorSpaceName:COLORSPACE 
							 bytesPerRow:img->widthStep bitsPerPixel:0];
	
	// Move the IplImage data into the NSBitmapImageRep. widthStep is used in the inner for loop due to the
	//   difference between actual bytes in the former and pixel locations in the latter.
	// Assignment to colors[] is reversed because that's how an IplImage stores the data.
	
	if(img->nChannels > 1){
		unsigned char* pBitmap=[bmp bitmapData];
		for(long y=0; y<img->height; y++){
			memcpy(pBitmap, d+(y*img->widthStep),img->width);
			pBitmap+=img->widthStep;
		}
	}
	else {
		int x, y;
		unsigned int colors[3];
		for(y=0; y<img->height; y++){
			for(x=0; x<img->width; x++){
				if(img->nChannels > 1){
					colors[2] = (unsigned int) d[(y * img->widthStep) + (x*3)]; // x*3 due to difference between pixel coords and actual byte layout.
					colors[1] = (unsigned int) d[(y * img->widthStep) + (x*3)+1];
					colors[0] = (unsigned int) d[(y * img->widthStep) + (x*3)+2];
				}
				else{
					colors[0] = (unsigned int)d[(y * img->widthStep) + x];
					//NSLog(@"colors[0] = %d", colors[0]);
				}
				[bmp setPixel:(NSUInteger*)colors atX:(NSInteger)x y:(NSInteger)y];
			}
		}
	}
    
	
	NSData *tif = [bmp TIFFRepresentation];
	NSImage *im = [[NSImage alloc] initWithData:tif];
	
	return [im autorelease];
}

/*
-(NSImage*)converToGray:(NSImage*)image
{
	CGImageRef imgRef = image.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
 	CGFloat height = CGImageGetHeight(imgRef);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGContextRef grayscalecontext = CGBitmapContextCreate (nil,
														   width,
														   height,
														   8,      // bits per component
														   0,
														   colorSpace,
														   kCGImageAlphaNone);
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawImage(grayscalecontext, CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = [UIImage imageWithCGImage:CGBitmapContextCreateImage(grayscalecontext)];
	CGContextRelease(grayscalecontext);
	return imageCopy;
}
*/


-(NSImage *)monochromeImage:(NSImage*)theImage
{
    // get NSImage to bitmaprep nil
    //NSBitmapImageRep* abitmap = (NSBitmapImageRep*)[theImage bestRepresentationForDevice:nil];
    CGFloat imgwigth=[theImage size].width;
    CGFloat imgheight=[theImage size].height;
    NSRect imgrect=NSMakeRect(0,0,imgwigth,imgheight);
    NSBitmapImageRep* abitmap = (NSBitmapImageRep*)[theImage bestRepresentationForRect:imgrect context:nil hints:nil];
    long pw = [abitmap pixelsWide];
    long ph = [abitmap pixelsHigh];
    
    NSBitmapImageRep * bitmap =  [[NSBitmapImageRep alloc]
                                  initWithBitmapDataPlanes:NULL pixelsWide:pw
                                  pixelsHigh:ph bitsPerSample:8 samplesPerPixel:1
                                  hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace
                                  bytesPerRow:0 bitsPerPixel:0];
    
    [bitmap setSize: [theImage size]];
    
    NSImage * image =[ [NSImage alloc] initWithSize:[theImage size ] ];
    
    NSGraphicsContext *nsContext = [NSGraphicsContext
                                    graphicsContextWithBitmapImageRep:bitmap];
    
    [NSGraphicsContext saveGraphicsState];
    
    [NSGraphicsContext setCurrentContext: nsContext];
    
    // Do I need a lockFocus here?
    [ theImage drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect
                 operation:NSCompositeCopy fraction:1.0];
    
    // Restore the previous graphics context and state.
    [NSGraphicsContext restoreGraphicsState];
    
    [image addRepresentation: bitmap];
    [bitmap release];
    return [image autorelease];
}



-(void)awakeFromNib
{

	[m_imageView setDelegate:self];
	[m_imageView setImage:nil imageProperties:nil];
	[m_imageView setCurrentToolMode:IKToolModeMove]; // IKToolModeCrop IKToolModeRotate
    [m_imageView setParentController:self];
    [m_imageView setAutohidesScrollers:NO];
    [m_imageView setHasVerticalScroller:YES];
    [m_imageView setHasHorizontalScroller:YES];
    
	[m_toolbar setDelegate:self];
    [m_menuFile setDelegate:self];
	[m_menuEdit setDelegate:self];
    m_imageloaded=NO;
    m_undolist = [[NSMutableArray alloc] init];
    m_redolist = [[NSMutableArray alloc] init];
    
    m_tracingnow=NO;
    
    [m_handtool setEnabled:NO];
    [m_areatool setEnabled:NO];
    [m_croptool setEnabled:NO];
    [m_zoomintool setEnabled:NO];
    [m_zoomouttool setEnabled:NO];
    
    [m_btnresizeUp setEnabled:NO];
    [m_btnresizedown setEnabled:NO];
    [m_btninvert setEnabled:NO];
    [m_btnedge setEnabled:NO];
    [m_btnblackwhite setEnabled:NO];
    [m_btntrace setEnabled:NO];
    [m_btncopy setEnabled:NO];
   
    [m_editview setHorizontallyResizable:YES];
    //[m_editview setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [[m_editview textContainer] setContainerSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
    [[m_editview textContainer] setWidthTracksTextView:NO]; 
    
    const float LargeNumberForText = 1.0e7;
    
    NSScrollView *scrollView = [m_editview enclosingScrollView];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    //[scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    NSTextContainer *textContainer = [m_editview textContainer];
    [textContainer setContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [textContainer setWidthTracksTextView:NO];
    [textContainer setHeightTracksTextView:NO];
    
    [m_editview setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [m_editview setHorizontallyResizable:YES];
    [m_editview setVerticallyResizable:YES];
    [m_editview setAutoresizingMask:NSViewNotSizable];    

}

- (void)dealloc
{
    [m_undolist release];
    [m_redolist release];

    [m_img release];
    //if( m_iplImage ){
    //    cvReleaseImage(&m_iplImage);
    //}
   
    [super dealloc];
}

-(void)saveImage:(NSImage*)image
{
    NSString* imagesizestr=[NSString stringWithFormat:@"%.f x %.f",
                            [image size].width,[image size].height];
    [m_imagesize setStringValue:imagesizestr];

    NSData* imgdata=[image TIFFRepresentation];
    NSBitmapImageRep* jpegImageRep = [NSBitmapImageRep imageRepWithData:imgdata];

    NSData* pngData = [jpegImageRep representationUsingType:NSPNGFileType
                                                  properties:nil];	
    NSString* tempFileTemplate=[self tmpNameWithSuffix:@"imgasctmp.png"];
    NSURL* tempurl=[NSURL fileURLWithPath:tempFileTemplate];
    
    [pngData writeToURL:tempurl atomically:YES];
        

    [m_imageView setImageWithURL:tempurl];

}

-(CGImageRef)nsImageToCGImage:(NSImage*)image
{
    NSData * imgData = [image TIFFRepresentation];
    CGImageRef imgRef = 0;
    if(imgData)
    {
        CGImageSourceRef imageSource =
        CGImageSourceCreateWithData((CFDataRef)imgData,  NULL);
        
        imgRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
    
    return imgRef;
} 

-(void)doMakeUndo
{
    CGImageRef cgimage=[m_imageView image];
    
    NSBitmapImageRep *bitmap_rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSImage* viewimage = [[[NSImage alloc] init] autorelease];
    [viewimage addRepresentation:bitmap_rep];
    
    NSData* pngData = [bitmap_rep representationUsingType:NSPNGFileType
                                                  properties:nil];	
    NSString* tempFileTemplate=[self tmpNameWithSuffix:@"imgasctmp.png"];
    NSURL* tempurl=[NSURL fileURLWithPath:tempFileTemplate];
    
    [pngData writeToURL:tempurl atomically:YES];

    myImageObject* p = [[myImageObject alloc] init];
    [p setPath:[tempurl path]];
    [m_undolist addObject:p];
    
    [p release];
  
    [bitmap_rep release];
}



-(void)doMakeRedo
{
    CGImageRef cgimage=[m_imageView image];
    
    NSBitmapImageRep *bitmap_rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSImage* viewimage = [[[NSImage alloc] init] autorelease];
    [viewimage addRepresentation:bitmap_rep];
    
    NSData* pngData = [bitmap_rep representationUsingType:NSPNGFileType
                                                properties:nil];	
    NSString* tempFileTemplate=[self tmpNameWithSuffix:@"imgasctmp.png"];
    NSURL* tempurl=[NSURL fileURLWithPath:tempFileTemplate];
    
    [pngData writeToURL:tempurl atomically:YES];
    
    myImageObject* p = [[myImageObject alloc] init];
    [p setPath:[tempurl path]];
    [m_redolist addObject:p];
    
    [p release];
    
    [bitmap_rep release];
}

-(IplImage*)getImageFromImageView
{
    CGImageRef cgimage=[m_imageView image];
    
    NSBitmapImageRep *bitmap_rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSImage* viewimage = [[[NSImage alloc] init] autorelease];
    [viewimage addRepresentation:bitmap_rep];
    
    IplImage* bwimage=[self NSImageToIplImage:viewimage];
    [bitmap_rep release];
    return bwimage;
}

-(IBAction)imgBlackWhite:(id)sender
{
    [self doMakeUndo];
    IplImage* viewimage=[self getImageFromImageView];
    
    cvThreshold(viewimage, viewimage, 0, 255, CV_THRESH_BINARY|CV_THRESH_OTSU);
    
	NSImage* nsimage=[self IplImageToNSImage:viewimage];
    [self saveImage:nsimage];

}

-(IBAction)imgEdge:(id)sender
{
    [self doMakeUndo];
    IplImage* viewimage=[self getImageFromImageView];

    cvAdaptiveThreshold (viewimage, viewimage, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 7, 6);
    cvSmooth (viewimage, viewimage, CV_MEDIAN, 3);
    
    NSImage* nsimage=[self IplImageToNSImage:viewimage];
    [self saveImage:nsimage];

}

-(IBAction)imgDilation:(id)sender
{
    [self doMakeUndo];
    IplImage* viewimage=[self getImageFromImageView];
    IplImage* dstimage=cvCloneImage(viewimage);
    IplImage* tmpimg=cvCloneImage(viewimage);
    
    IplConvKernel* element=cvCreateStructuringElementEx(5, 5, 2, 2, CV_SHAPE_CROSS, NULL);
    //cvMorphologyEx (viewimage, dstimage, tmpimg, element, CV_MOP_OPEN, 1);
    cvDilate (viewimage, dstimage, element, 1);
    //cvErode (viewimage, dstimage, NULL, 1);
    
    cvReleaseStructuringElement(&element);
    
    NSImage* nsimage=[self IplImageToNSImage:dstimage];
    [self saveImage:nsimage];
    
    cvReleaseImage(&dstimage);
    cvReleaseImage(&tmpimg);

}

-(IBAction)imgErosion:(id)sender
{
    [self doMakeUndo];
    IplImage* viewimage=[self getImageFromImageView];
    IplImage* dstimage=cvCloneImage(viewimage);
    IplImage* tmpimg=cvCloneImage(viewimage);
   
    IplConvKernel* element=cvCreateStructuringElementEx(5, 5, 2, 2, CV_SHAPE_CROSS, NULL);
    //cvMorphologyEx (viewimage, dstimage, tmpimg, element, CV_MOP_CLOSE, 1);
    //cvDilate (viewimage, dstimage, NULL, 1);
    cvErode (viewimage, dstimage, element, 1);
    
    cvReleaseStructuringElement(&element);
    
    NSImage* nsimage=[self IplImageToNSImage:dstimage];
    [self saveImage:nsimage];
    
    cvReleaseImage(&dstimage);
    cvReleaseImage(&tmpimg);
}

void myThinningInit(CvMat** kpw, CvMat** kpb)
{
    //cvFilter2D用のカーネル
    //アルゴリズムでは白、黒のマッチングとなっているのをkpwカーネルと二値画像、
    //kpbカーネルと反転した二値画像の2組に分けて畳み込み、その後でANDをとる
    for (int i=0; i<8; i++){
        *(kpw+i) = cvCreateMat(3, 3, CV_8UC1);
        *(kpb+i) = cvCreateMat(3, 3, CV_8UC1);
        cvSet(*(kpw+i), cvRealScalar(0), NULL);
        cvSet(*(kpb+i), cvRealScalar(0), NULL);
    }
    //cvSet2Dはy,x(row,column)の順となっている点に注意
    //kernel1
    cvSet2D(*(kpb+0), 0, 0, cvRealScalar(1));
    cvSet2D(*(kpb+0), 0, 1, cvRealScalar(1));
    cvSet2D(*(kpb+0), 1, 0, cvRealScalar(1));
    cvSet2D(*(kpw+0), 1, 1, cvRealScalar(1));
    cvSet2D(*(kpw+0), 1, 2, cvRealScalar(1));
    cvSet2D(*(kpw+0), 2, 1, cvRealScalar(1));
    //kernel2
    cvSet2D(*(kpb+1), 0, 0, cvRealScalar(1));
    cvSet2D(*(kpb+1), 0, 1, cvRealScalar(1));
    cvSet2D(*(kpb+1), 0, 2, cvRealScalar(1));
    cvSet2D(*(kpw+1), 1, 1, cvRealScalar(1));
    cvSet2D(*(kpw+1), 2, 0, cvRealScalar(1));
    cvSet2D(*(kpw+1), 2, 1, cvRealScalar(1));
    //kernel3
    cvSet2D(*(kpb+2), 0, 1, cvRealScalar(1));
    cvSet2D(*(kpb+2), 0, 2, cvRealScalar(1));
    cvSet2D(*(kpb+2), 1, 2, cvRealScalar(1));
    cvSet2D(*(kpw+2), 1, 0, cvRealScalar(1));
    cvSet2D(*(kpw+2), 1, 1, cvRealScalar(1));
    cvSet2D(*(kpw+2), 2, 1, cvRealScalar(1));
    //kernel4
    cvSet2D(*(kpb+3), 0, 2, cvRealScalar(1));
    cvSet2D(*(kpb+3), 1, 2, cvRealScalar(1));
    cvSet2D(*(kpb+3), 2, 2, cvRealScalar(1));
    cvSet2D(*(kpw+3), 0, 0, cvRealScalar(1));
    cvSet2D(*(kpw+3), 1, 0, cvRealScalar(1));
    cvSet2D(*(kpw+3), 1, 1, cvRealScalar(1));
    //kernel5
    cvSet2D(*(kpb+4), 1, 2, cvRealScalar(1));
    cvSet2D(*(kpb+4), 2, 2, cvRealScalar(1));
    cvSet2D(*(kpb+4), 2, 1, cvRealScalar(1));
    cvSet2D(*(kpw+4), 0, 1, cvRealScalar(1));
    cvSet2D(*(kpw+4), 1, 1, cvRealScalar(1));
    cvSet2D(*(kpw+4), 1, 0, cvRealScalar(1));
    //kernel6
    cvSet2D(*(kpb+5), 2, 0, cvRealScalar(1));
    cvSet2D(*(kpb+5), 2, 1, cvRealScalar(1));
    cvSet2D(*(kpb+5), 2, 2, cvRealScalar(1));
    cvSet2D(*(kpw+5), 0, 2, cvRealScalar(1));
    cvSet2D(*(kpw+5), 0, 1, cvRealScalar(1));
    cvSet2D(*(kpw+5), 1, 1, cvRealScalar(1));
    //kernel7
    cvSet2D(*(kpb+6), 1, 0, cvRealScalar(1));
    cvSet2D(*(kpb+6), 2, 0, cvRealScalar(1));
    cvSet2D(*(kpb+6), 2, 1, cvRealScalar(1));
    cvSet2D(*(kpw+6), 0, 1, cvRealScalar(1));
    cvSet2D(*(kpw+6), 1, 1, cvRealScalar(1));
    cvSet2D(*(kpw+6), 1, 2, cvRealScalar(1));
    //kernel8
    cvSet2D(*(kpb+7), 0, 0, cvRealScalar(1));
    cvSet2D(*(kpb+7), 1, 0, cvRealScalar(1));
    cvSet2D(*(kpb+7), 2, 0, cvRealScalar(1));
    cvSet2D(*(kpw+7), 1, 1, cvRealScalar(1));
    cvSet2D(*(kpw+7), 1, 2, cvRealScalar(1));
    cvSet2D(*(kpw+7), 2, 2, cvRealScalar(1));
}


BOOL IsContourP(int x,int y, IplImage *Src_Img)   
{      
    BOOL p[10] ={0};   
    int LineBytes =Src_Img->widthStep;   
    unsigned char* lpPtr= (unsigned char*)(Src_Img->imageData+LineBytes*y)+x;    
    
    p[2]=*(lpPtr-LineBytes) ? true:false;   
    p[3]=*(lpPtr-LineBytes+1) ? true:false;   
    p[4]=*(lpPtr+1) ? true:false;   
    p[5]=*(lpPtr+LineBytes+1) ? true:false;   
    p[6]=*(lpPtr+LineBytes) ? true:false;   
    p[7]=*(lpPtr+LineBytes-1) ? true:false;   
    p[8]=*(lpPtr-1) ? true:false;   
    p[9]=*(lpPtr-LineBytes-1) ? true:false;   
    
    int Np=0;    int Tp=0;
    for (int i=2; i<10; i++){   
        Np += p[i];   
        int k= (i<9) ? (i+1) : 2;   
        
        if ( p[k] -p[i]>0){   
            Tp++;   
        }   
    }   
    int p246= p[2] && p[4] && p[6];   
    int p468= p[4] && p[6] && p[8];   
    
    int p24= p[2] && !p[3] && p[4] && !p[5] && !p[6] && !p[7] && !p[8] && !p[9];   
    int p46= !p[2] && !p[3] && p[4] && !p[5] && p[6] && !p[7] && !p[8] && !p[9];   
    int p68= !p[2] && !p[3] && !p[4] && !p[5] && p[6] && !p[7] && p[8] && !p[9];   
    int p82= p[2] && !p[3] && !p[4] && !p[5] && !p[6] && !p[7] && p[8] && !p[9];   
    
    int p782= p[2] && !p[3] && !p[4] && !p[5] && !p[6] && p[7] && p[8] && !p[9];   
    int p924= p[2] && !p[3] && p[4] && !p[5] && !p[6] && !p[7] && !p[8] && p[9];   
    int p346= !p[2] && p[3] && p[4] && !p[5] && p[6] && !p[7] && !p[8] && !p[9];   
    int p568= !p[2] && !p[3] && !p[4] && p[5] && p[6] && !p[7] && p[8] && !p[9];   
    
    int p689= !p[2] && !p[3] && !p[4] && !p[5] && p[6] && !p[7] && p[8] && p[9];   
    int p823= p[2] && p[3] && !p[4] && !p[5] && !p[6] && !p[7] && p[8] && !p[9];   
    int p245= p[2] && !p[3] && p[4] && p[5] && !p[6] && !p[7] && !p[8] && !p[9];   
    int p467= !p[2] && !p[3] && p[4] && !p[5] && p[6] && p[7] && !p[8] && !p[9];   
    
    int p2468= p24 || p46 || p68 || p82;   
    int p3333= p782 || p924 || p346 || p568 || p689 || p823 || p245 || p467;   
    
    return ( !p246 && !p468 && (Np<7) && (Np>1) && (Tp==1) ) || p2468 || p3333;    
}   

void thin( IplImage *Src_Img)
{   
    int i,j,Remove_Num=0;   
    CvSize img_size = cvGetSize(Src_Img);   
    
    do{  
        Remove_Num=0;   
        for (j = 1; j<img_size.height-1; j++){        
            for(i = 1; i<img_size.width-1; i++)   
            {              
                unsigned char gray_value = ((unsigned char*)(Src_Img->imageData + Src_Img->widthStep*j))[i];   
                if ( gray_value && IsContourP( i, j, Src_Img)){             
                    ((unsigned char*)(Src_Img->imageData + Src_Img->widthStep*j))[i]=0;   
                    Remove_Num++;   
                }//if   
            }//for i   
        }//for j   
    } while( Remove_Num);      
}   

void setPattern(CvPoint* w3p, CvPoint* b3p, int *pCount)
{
    if (*pCount == 8){
        *pCount=1;
    }else{
        (*pCount)++;
    }
    switch(*pCount){
        case 1:
            w3p[0]=cvPoint(1,1);w3p[1]=cvPoint(2,1);w3p[2]=cvPoint(1,2);
            b3p[0]=cvPoint(0,0);b3p[1]=cvPoint(1,0);b3p[2]=cvPoint(0,1);
            break;
        case 2:
            b3p[0]=cvPoint(0,0);b3p[1]=cvPoint(1,0);b3p[2]=cvPoint(2,0);
            w3p[0]=cvPoint(1,1);w3p[1]=cvPoint(0,2);w3p[2]=cvPoint(1,2);
            break;
        case 3:
            b3p[0]=cvPoint(1,0);b3p[1]=cvPoint(2,0);b3p[2]=cvPoint(2,1);
            w3p[0]=cvPoint(0,1);w3p[1]=cvPoint(1,1);w3p[2]=cvPoint(1,2);
            break;
        case 4:
            b3p[0]=cvPoint(2,0);b3p[1]=cvPoint(2,1);b3p[2]=cvPoint(2,2);
            w3p[0]=cvPoint(0,0);w3p[1]=cvPoint(0,1);w3p[2]=cvPoint(1,1);
            break;
        case 5:
            b3p[0]=cvPoint(2,1);b3p[1]=cvPoint(2,2);b3p[2]=cvPoint(1,2);
            w3p[0]=cvPoint(1,0);w3p[1]=cvPoint(1,1);w3p[2]=cvPoint(0,1);
            break;
        case 6:
            b3p[0]=cvPoint(0,2);b3p[1]=cvPoint(1,2);b3p[2]=cvPoint(2,2);
            w3p[0]=cvPoint(2,0);w3p[1]=cvPoint(1,0);w3p[2]=cvPoint(1,1);
            break;
        case 7:
            b3p[0]=cvPoint(0,1);b3p[1]=cvPoint(0,2);b3p[2]=cvPoint(1,2);
            w3p[0]=cvPoint(1,0);w3p[1]=cvPoint(1,1);w3p[2]=cvPoint(2,1);
            break;
        case 8:
            b3p[0]=cvPoint(0,0);b3p[1]=cvPoint(0,1);b3p[2]=cvPoint(0,2);
            w3p[0]=cvPoint(1,1);w3p[1]=cvPoint(2,1);w3p[2]=cvPoint(2,2);
            break;
    }
}

//ROIとして取得した3x3の画像と白黒テーブルを比較、一致すれば1を返す
int myMatching(IplImage *win,CvPoint *w3p,CvPoint *b3p)
{
    if (((unsigned char*)(win->imageData+w3p[0].y*win->widthStep))[w3p[0].x] ==255 &&
        ((unsigned char*)(win->imageData+w3p[1].y*win->widthStep))[w3p[1].x] ==255 &&
        ((unsigned char*)(win->imageData+w3p[2].y*win->widthStep))[w3p[2].x] ==255 &&
        ((unsigned char*)(win->imageData+b3p[0].y*win->widthStep))[b3p[0].x] ==0 &&
        ((unsigned char*)(win->imageData+b3p[1].y*win->widthStep))[b3p[1].x] ==0 &&
        ((unsigned char*)(win->imageData+b3p[2].y*win->widthStep))[b3p[2].x] ==0 ){
        return 1;
    }
    return 0;
}

-(IBAction)imgThinning:(id)sender
{
    [self doMakeUndo];
    
    IplImage* viewimage=[self getImageFromImageView];
    IplImage* dstimage=cvCloneImage(viewimage);
    
//    IplImage* tmp_img = cvCreateImage (cvGetSize(viewimage), IPL_DEPTH_16S, 1);    
//    cvLaplace(viewimage,tmp_img,3);
//    cvConvertScaleAbs (tmp_img, dstimage);
//    cvReleaseImage(&tmp_img);
    
    int nCannyInitValue=100;
    cvCanny(viewimage, dstimage, nCannyInitValue,nCannyInitValue*3);
    cvNot(dstimage,dstimage);
    
    //thin( dstimage );
    NSImage* nsimage=[self IplImageToNSImage:dstimage];
    [self saveImage:nsimage];
    cvReleaseImage(&dstimage);

 /*   
    CvPoint *white3Points=(CvPoint*)cvAlloc(sizeof(CvPoint)*3);
    CvPoint *black3Points=(CvPoint*)cvAlloc(sizeof(CvPoint)*3);
    
    IplImage* dst=[self getImageFromImageView];
    IplImage* src=cvCloneImage(dst);
    cvThreshold(dst,src,128,255,CV_THRESH_BINARY);
    cvCopy(src,dst,NULL);
    IplImage* bufferimg=cvCloneImage(src);
    //3x3のROIコピー用
    IplImage* ROIimg=cvCreateImage(cvSize(3,3),IPL_DEPTH_8U,1);

    //終了条件は1ターン(8パターン)完了時で変更が無かった場合
    //8パターンを1ターンとするカウント
    int patternCount=0;
    int turnCount=1;
    long isChanged=1;
    int x,y;
    while(patternCount !=8 || isChanged>0){
        //1ターンでカウントをリセット
        if (patternCount==8){
            turnCount++;
            isChanged=0;
        }
        //パターン変更
        setPattern(white3Points,black3Points,&patternCount);
        for (y=0; y<dst->height-3; y++){
            for (x=0; x<dst->width-3; x++){
                //ROIとして3x3を切り出し
                cvSetImageROI(dst,cvRect(x,y,3,3));
                cvCopy(dst,ROIimg,NULL);
                //マッチング関数に放り込み、一致してれば3x3の中心に相当するbufferimgの画素を0に
                if (myMatching(ROIimg,white3Points,black3Points)){
                    isChanged++;
                    ((unsigned char*)(bufferimg->imageData+(y+1)*bufferimg->widthStep))[x+1] = 0;
                }
                cvResetImageROI(dst);
            }
        }
        //デバッグ用画像
        //各パターンで削られていく様子が分かる
        //sprintf(fname,"thinning_turn%02d_pattern%d.jpg",turnCount,patternCount);
        //printf("turn%02d, pattern%d\n",turnCount,patternCount);
        //cvSaveImage(fname,bufferimg);
        //各パターンでのスキャン終了時にbufferimg->dstを行なう
        cvCopy(bufferimg,dst,NULL);
    }
    cvCopy(bufferimg,dst,NULL);
    
    NSImage* nsimage=[self IplImageToNSImage:dst];
    [self saveImage:nsimage];

    cvFree(&white3Points);
    cvFree(&black3Points);
    
    cvReleaseImage(&src);
    cvReleaseImage(&bufferimg);
    cvReleaseImage(&ROIimg);
    */
 
/*    
    CvMat** kpb = new CvMat *[8];
    CvMat** kpw = new CvMat *[8];
    myThinningInit(kpw, kpb);
    
    IplImage* viewimage=[self getImageFromImageView];
    IplImage* dstimage=cvCloneImage(viewimage);
    
    IplImage* src_w=cvCreateImage(cvGetSize(viewimage), IPL_DEPTH_32F, 1);
    IplImage* src_b=cvCreateImage(cvGetSize(viewimage), IPL_DEPTH_32F, 1);
    IplImage* src_f=cvCreateImage(cvGetSize(viewimage), IPL_DEPTH_32F, 1);
    cvNot(viewimage,viewimage);
    cvScale(viewimage, src_f, 1/255.0, 0);
    
    cvThreshold(src_f,src_f,0.5,1.0,CV_THRESH_BINARY);
    cvThreshold(src_f,src_w,0.5,1.0,CV_THRESH_BINARY);
    cvThreshold(src_f,src_b,0.5,1.0,CV_THRESH_BINARY_INV);
    
    double sum=1;
    while(sum>0){
        sum=0;
        for (int i=0; i<8; i++){
            cvFilter2D(src_w, src_w, *(kpw+i));
            cvFilter2D(src_b, src_b, *(kpb+i));
            //各カーネルで注目するのは3画素ずつなので、マッチした注目画素の濃度は3となる
            //カーネルの値を1/9にしておけば、しきい値は0.99で良い
            cvThreshold(src_w,src_w,2.99,1,CV_THRESH_BINARY); //2.5->2.99に修正
            cvThreshold(src_b,src_b,2.99,1,CV_THRESH_BINARY); //2.5->2.99
            cvAnd(src_w, src_b, src_w);
            //この時点でのsrc_wが消去候補点となり、全カーネルで候補点が0となった時に処理が終わる
            sum += cvSum(src_w).val[0];
            //原画像から候補点を消去(二値画像なのでXor)
            cvXor(src_f, src_w, src_f);
            //作業バッファを更新
            cvCopyImage(src_f, src_w);
            cvThreshold(src_f,src_b,0.5,1,CV_THRESH_BINARY_INV);
        }
    }
    delete [] kpb;
    delete [] kpw;
    cvConvertScaleAbs(src_f, dstimage, 255, 0);
    cvNot(dstimage,dstimage);

    NSImage* nsimage=[self IplImageToNSImage:dstimage];
    [self saveImage:nsimage];
    cvReleaseImage(&dstimage);

    cvReleaseImage(&src_f);
    cvReleaseImage(&src_w);
    cvReleaseImage(&src_b);
*/
    
}

-(IBAction)imgResizeUp:(id)sender
{
    [self doMakeUndo];
    IplImage* viewimage=[self getImageFromImageView];
    CvSize resize=cvSize((int)((double)viewimage->width*1.25),(int)((double)viewimage->height*1.25));
    IplImage* dstimage=cvCreateImage(resize, viewimage->depth, viewimage->nChannels);
    cvResize(viewimage, dstimage);

    NSImage* nsimage=[self IplImageToNSImage:dstimage];
 	[m_imageView setImage:[self nsImageToCGImage:nsimage] imageProperties:nil];
    [self saveImage:nsimage];
    
    cvReleaseImage(&dstimage);
}

-(IBAction)imgResizeDown:(id)sender
{
    [self doMakeUndo];
    IplImage* viewimage=[self getImageFromImageView];
    CvSize resize=cvSize((int)((double)viewimage->width*0.75),(int)((double)viewimage->height*0.75));
    IplImage* dstimage=cvCreateImage(resize, viewimage->depth, viewimage->nChannels);
    cvResize(viewimage, dstimage);
    
    NSImage* nsimage=[self IplImageToNSImage:dstimage];
    [self saveImage:nsimage];
    
    cvReleaseImage(&dstimage);
}

-(IBAction)imgReverse:(id)sender
{
    [self doMakeUndo];
    IplImage* viewimage=[self getImageFromImageView];
    cvNot(viewimage, viewimage);
    
    NSImage* nsimage=[self IplImageToNSImage:viewimage];
    [self saveImage:nsimage];
}

- (void)updateToolbarDelayed:(NSTimer*)timer
{    
    NSURL* url=[timer userInfo];
    NSImage* orgimage=[[NSImage alloc] initWithContentsOfURL:url];
    NSImage* monoimage=[self monochromeImage:orgimage];
    [orgimage release];
    
    [m_imageView setAutoresizes:YES];

    [self saveImage:monoimage];
           
    NSString* imagesizestr=[NSString stringWithFormat:@"%.f x %.f",
                            [monoimage size].width,[monoimage size].height];
    [m_imagesize setStringValue:imagesizestr];
    
    [m_dialog setTitleWithRepresentedFilename: [url path]];
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
    
    [m_undolist removeAllObjects];
    [m_redolist removeAllObjects];
    
    
    m_imageloaded=YES;

    [m_handtool setEnabled:YES];
    [m_areatool setEnabled:YES];
    [m_croptool setEnabled:[m_imageView currentToolMode]!=IKToolModeMove];
    [m_zoomintool setEnabled:YES];
    [m_zoomouttool setEnabled:YES];
 
    [m_btnresizeUp setEnabled:YES];
    [m_btnresizedown setEnabled:YES];
    [m_btninvert setEnabled:YES];
    [m_btnedge setEnabled:YES];
    [m_btnblackwhite setEnabled:YES];
    [m_btntrace setEnabled:YES];
    
    
}

- (void)updateToolbarDelayedforClipboard:(NSTimer*)timer
{    
    NSURL* url=[timer userInfo];
    NSImage* orgimage=[[NSImage alloc] initWithContentsOfURL:url];
    NSImage* monoimage=[self monochromeImage:orgimage];
    [orgimage release];
    
    [m_imageView setAutoresizes:YES];
    
    [self saveImage:monoimage];
    
    NSString* imagesizestr=[NSString stringWithFormat:@"%.f x %.f",
                            [monoimage size].width,[monoimage size].height];
    [m_imagesize setStringValue:imagesizestr];
    
    [m_undolist removeAllObjects];
    [m_redolist removeAllObjects];
    
    
    m_imageloaded=YES;
    
    [m_handtool setEnabled:YES];
    [m_areatool setEnabled:YES];
    [m_croptool setEnabled:[m_imageView currentToolMode]!=IKToolModeMove];
    [m_zoomintool setEnabled:YES];
    [m_zoomouttool setEnabled:YES];
    
    [m_btnresizeUp setEnabled:YES];
    [m_btnresizedown setEnabled:YES];
    [m_btninvert setEnabled:YES];
    [m_btnedge setEnabled:YES];
    [m_btnblackwhite setEnabled:YES];
    [m_btntrace setEnabled:YES];
    
    
}




-(void)openDragImage:(NSURL*)url
{
    [NSTimer scheduledTimerWithTimeInterval: 0.1
                                     target:self
                                   selector:@selector(updateToolbarDelayed:)
                                   userInfo:url
                                    repeats:NO];
    

 
}
     
- (void)openPanelDidEnd: (NSOpenPanel *)panel 
             returnCode: (int)returnCode
            contextInfo: (void  *)contextInfo
{
    if (returnCode == NSOKButton)
    {
        NSURL* url=[[panel URLs] objectAtIndex:0];
        [self openDragImage:url];    
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	//NSLog(@"application openFile %@", filename);
	NSURL* url=[NSURL fileURLWithPath:filename];
    [self openDragImage:url];    

	return YES;
}

-(IBAction)openImg:(id)sender
{
    // present open panel...
    // present open panel...
    NSOpenPanel * openPanel = [[NSOpenPanel openPanel] retain];
    NSString *    extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG/pdf/png/bmp/PDF/PNG/BMP";
    NSArray *     types = [extensions pathComponents];
	
    [openPanel setAllowedFileTypes:types];
    [openPanel setDelegate:self];
    
    [openPanel beginSheetModalForWindow:m_dialog
                      completionHandler:^(NSInteger returnCode) {
                          if (returnCode==NSFileHandlingPanelOKButton)
                          {
                             // NSURL* url=[NSURL fileURLWithPath:filename];
                              [self openDragImage:[[openPanel URLs] objectAtIndex:0]];    
                         }
                          [openPanel release];
                      }];

/*   
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    NSString *    extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG/pdf/png/bmp/PDF/PNG/BMP";
    NSArray *     types = [extensions pathComponents];
    
 
    [openPanel beginSheetForDirectory: NULL
                                 file: NULL
                                types: types
                       modalForWindow: m_dialog
                        modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo: NULL];
*/
}

- (void)newFromClipboard:(id)sender
{
	NSPasteboard *pb = [ NSPasteboard generalPasteboard ];
	NSImage* cbimage = [[NSImage alloc] initWithPasteboard:pb];
    NSImage* monoimage=[self monochromeImage:cbimage];
    [cbimage release];
    
    NSData* imgdata=[monoimage TIFFRepresentation];
    NSBitmapImageRep* jpegImageRep = [NSBitmapImageRep imageRepWithData:imgdata];

    NSData* pngData = [jpegImageRep representationUsingType:NSPNGFileType
                                                  properties:nil];	
    NSString* tempFileTemplate=[self tmpNameWithSuffix:@"imgasctmp.png"];
    NSURL* tempurl=[NSURL fileURLWithPath:tempFileTemplate];
    
    [pngData writeToURL:tempurl atomically:YES];

    
	[m_dialog setTitleWithRepresentedFilename:@""];
	[m_dialog setTitle:@"From Clipboard"];
    [NSTimer scheduledTimerWithTimeInterval: 0.1
                                     target:self
                                   selector:@selector(updateToolbarDelayedforClipboard:)
                                   userInfo:tempurl
                                    repeats:NO];
	
}

-(IBAction)OnCopy:(id)sender
{
    NSString *string = [m_editview string];
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    [pasteBoard setString:string forType:NSStringPboardType];    
}

-(IBAction)editUndo:(id)sender
{
    [self doMakeRedo];
    myImageObject* pObject=[m_undolist objectAtIndex:[m_undolist count]-1];
    NSURL* tempurl=[NSURL fileURLWithPath:[pObject getPath]];
    
    [m_undolist removeLastObject];
    [m_imageView setImageWithURL:tempurl];
    
    CGImageRef cgimage=[m_imageView image];
    
    NSBitmapImageRep *bitmap_rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSImage* viewimage = [[[NSImage alloc] init] autorelease];
    [viewimage addRepresentation:bitmap_rep];
    
    NSString* imagesizestr=[NSString stringWithFormat:@"%.f x %.f",
                            [viewimage size].width,[viewimage size].height];
    [m_imagesize setStringValue:imagesizestr];


}

-(IBAction)editRedo:(id)sender
{
    [self doMakeUndo];
    myImageObject* pObject=[m_redolist objectAtIndex:[m_redolist count]-1];
    NSURL* tempurl=[NSURL fileURLWithPath:[pObject getPath]];
    
    [m_redolist removeLastObject];
    [m_imageView setImageWithURL:tempurl];
    
    CGImageRef cgimage=[m_imageView image];
    
    NSBitmapImageRep *bitmap_rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSImage* viewimage = [[[NSImage alloc] init] autorelease];
    [viewimage addRepresentation:bitmap_rep];
    
    NSString* imagesizestr=[NSString stringWithFormat:@"%.f x %.f",
                            [viewimage size].width,[viewimage size].height];
    [m_imagesize setStringValue:imagesizestr];
    

}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu 
{
	//NSLog(@"numberOfItemsInMenu");
	return [menu numberOfItems];
}
- (void)menuNeedsUpdate:(NSMenu*)menu
{

}
- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel;
{
	NSLog(@"menu updateItem %@", item);
	return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    BOOL enable = YES;
    
    SEL action = [item action];
    if(action == @selector(newFromClipboard:)) {
        NSPasteboard *pboard = [ NSPasteboard generalPasteboard ];
        NSString* type = [pboard availableTypeFromArray:[NSImage imagePasteboardTypes]];
        
        // Frome Clipboard
        BOOL canPasteImage=type!=nil;
        return canPasteImage;
    }
    
    if(action == @selector(editUndo:)) {
        return [m_undolist count]>0; // or NO;
    }
    if(action == @selector(editRedo:)) {
        return [m_redolist count]>0; // or NO;
    }
   
    NSInteger tag = [item tag];
    if( tag==1001 ){ // scroll
        [item setState:[m_handtool intValue]];
    }
    if( tag==1002 ){ // crop
        [item setState:[m_areatool intValue]];
    }

    
    if( tag==1001 || tag==1002 || tag==1003 || tag==1004 || tag==1005 || tag==1006 ){
        enable = m_imageloaded;       
    }
    if( m_tracingnow ){
        enable=NO;
    }
	return enable;
}
-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
    BOOL enable = YES;
    if ([[toolbarItem itemIdentifier] isEqual:@"IMGSCROLL"]) {
        // We will return YES (enable the save item)
        // only when the document is dirty and needs saving
		enable = m_imageloaded;    
    } 
	else if ([[toolbarItem itemIdentifier] isEqual:@"AREAIMAGE"]) {
        // always enable print for this window
        enable = m_imageloaded;
    }
	else if ([[toolbarItem itemIdentifier] isEqual:@"IMGCROP"]) {
        // always enable print for this window
        enable = m_imageloaded;
    }
	else if ([[toolbarItem itemIdentifier] isEqual:@"ZOOMIN"]) {
        // always enable print for this window
        enable = m_imageloaded;
    }
	else if ([[toolbarItem itemIdentifier] isEqual:@"ZOOMOUT"]) {
        // always enable print for this window
        enable = m_imageloaded;
   }
	return enable;//([m_ikimageview image]!=nil);
}

-(BOOL)isTracingNow
{
    return m_tracingnow;
}


- (NSBitmapImageRep *)cropToRect:(NSBitmapImageRep*)imageRep bounds:(NSRect)rect
{
    /* This method retuns a NSBitmapImage containing the
     rectangle defined by the input bounds */
    
    CGImageRef cgImg = CGImageCreateWithImageInRect([imageRep CGImage],
                                                    NSRectToCGRect(rect));
    NSBitmapImageRep *result = [[NSBitmapImageRep alloc]
                                initWithCGImage:cgImg];
    CGImageRelease(cgImg);
    return [result autorelease];
}

-(NSMutableArray*)createCharImages:(NSString*)imagefilename 
                             rects:(NSMutableArray*)rectarray 
                          chartexts:(NSMutableArray*)chartextarray
{
	NSMutableArray* charImageArray=[[[NSMutableArray alloc]init] autorelease];

    long seqno=0;
    NSImage* image=[[NSImage alloc]initWithContentsOfFile:imagefilename];
    NSRect imgrect=NSMakeRect(0,0,image.size.width,image.size.height);
    NSBitmapImageRep* bitmap = (NSBitmapImageRep*)[image bestRepresentationForRect:imgrect context:nil hints:nil];
 
 	for( NSValue* value in rectarray ){
		NSRect therect=[value rectValue];

        //NSLog(@"createCharImages seq=%ld rect=%f %f %f %f",
        //     seqno, therect.origin.x,therect.origin.y,therect.size.width,therect.size.height);
        
        NSImage *trimedImage = [[NSImage alloc] initWithSize:therect.size];
        [trimedImage addRepresentation:[self cropToRect:bitmap bounds:therect]];
        
        NSData* tifdata=[trimedImage TIFFRepresentation];
        NSString* seqname=[NSString stringWithFormat:@"seq-%03d.tif",seqno];
        NSString* savefilename=[self tmpWorkNameWithSuffix:seqname];
        [tifdata writeToFile:savefilename atomically:YES];
        [trimedImage release];
        
        myImageObject* p = [[myImageObject alloc] init];
        [p setPath:savefilename];
        [p setChartext:[chartextarray objectAtIndex:seqno]];
        [charImageArray addObject:p];
        [p release];

        seqno++;
	}
    [image release];
    return charImageArray;
}

-(NSMutableArray*)drawTextbox:(NSString*)strdata
{
	const float picleftmargin=m_fontSize;
	const float picsizex=500;
    float picsizey=m_fontSize*[strdata length];
    if(picsizey<500){ picsizey=500; }
//	const long boxshrinkmargin=0;
	const float rowpitchfactor=1.4;
	const float colpitchfactor=10;
	
	NSSize imagesize=NSMakeSize(picsizex,picsizey);
	NSImage* theimage=[[NSImage alloc]initWithSize:imagesize];
	[theimage lockFocus];
	
	NSRect rect = NSMakeRect(0,0,picsizex,picsizey);
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
    NSMutableDictionary *stringAttributes = [NSMutableDictionary dictionary];
	
    // Set a font and specify a "fill" color
    [stringAttributes setObject: [NSFont fontWithName:m_fontName size:m_fontSize] forKey: NSFontAttributeName];
	[stringAttributes setObject: [NSColor blackColor] forKey: NSForegroundColorAttributeName];
    
	NSString* drawnstr=@"";
    NSString* savefilename=[self tmpWorkNameWithSuffix:@"imgascpattern.tif"];
    
    
    CGFontRef fontref = CGFontCreateWithFontName((CFStringRef)m_fontName);
    int accent=CGFontGetAscent(fontref);
    int descent=CGFontGetDescent(fontref);
    int perem=CGFontGetUnitsPerEm(fontref);
    CGFloat pixelaccent=(float)accent*m_fontSize/(float)perem;
    CGFloat pixeldescent=(float)descent*m_fontSize/(float)perem;
    CGFloat pixelHeight=pixelaccent-pixeldescent;
    CGFontRelease(fontref);
    NSLog(@"font size=%ld height=%f",m_fontSize,pixelHeight);
    
    NSRange range1st; range1st.location=0; range1st.length=1;
    NSString* the1stchar=[strdata substringWithRange:range1st];
    NSSize drawsize1st=[the1stchar sizeWithAttributes:stringAttributes];
    CGFloat fontClipHeight=drawsize1st.height-pixelHeight;
    
	NSMutableArray* rectarray=[[[NSMutableArray alloc]init] autorelease];
	NSMutableArray* chartextarray=[[[NSMutableArray alloc]init] autorelease];
	
	NSLog(@"Fontname %@",m_fontName );
	NSPoint drawpos=NSMakePoint(picleftmargin,picsizey-(m_fontSize*2));
	long loop=0;
	for( loop=0; loop<[strdata length]; loop++ ){
		NSRange range; range.location=loop; range.length=1;
		NSString* thechar=[strdata substringWithRange:range];
		NSSize drawsize=[thechar sizeWithAttributes:stringAttributes];
		
		char* cChar=(char*)[thechar UTF8String];
		//NSLog(@"char=%X", *cChar);
		if( *cChar==0x0a ){
			drawpos.x=picsizex;
		}
		else {
			if( drawpos.x+drawsize.width>(picsizex-picleftmargin) ){
				drawpos.x=picleftmargin;
				drawpos.y-=drawsize.height*rowpitchfactor;
			}
			if( drawpos.y<10 ){
				// clip 
				break;
			}
			NSRect rect = NSMakeRect(drawpos.x, drawpos.y, drawsize.width, drawsize.height);
           
			[[NSColor blackColor] set];
			[thechar drawAtPoint:NSMakePoint(drawpos.x, drawpos.y) withAttributes:stringAttributes];
			if( [drawnstr length]==0 ){
				drawnstr=thechar;
			}
			else {
				drawnstr=[drawnstr stringByAppendingFormat:@"%@",thechar];
			}
			
 			// draw charactor box
			//NSFrameRect(rect);
            // offset for flip image base
            rect.origin.y=picsizey-rect.origin.y-drawsize.height;
            rect.origin.y+=fontClipHeight;
            rect.size.height-=fontClipHeight;
			[rectarray addObject:[NSValue valueWithRect:rect]];
            
            [chartextarray addObject:thechar];
           
 			CGFloat nextcharpitch=drawsize.width+colpitchfactor;
			if( nextcharpitch<m_fontSize ){
				nextcharpitch=m_fontSize;
			}
			drawpos.x+=nextcharpitch;
			if( drawpos.x>(picsizex-picleftmargin) ){
				drawpos.x=picleftmargin;
				drawpos.y-=drawsize.height*rowpitchfactor;
			}
		}
	//	[m_indicator setDoubleValue:(double)loop];
	}
	
	[theimage unlockFocus];
    
	
    CGFloat imgwigth=[theimage size].width;
    CGFloat imgheight=[theimage size].height;
    NSRect imgrect=NSMakeRect(0,0,imgwigth,imgheight);
    NSBitmapImageRep* abitmap = (NSBitmapImageRep*)[theimage bestRepresentationForRect:imgrect context:nil hints:nil];
    long pw = [abitmap pixelsWide];
    long ph = [abitmap pixelsHigh];
    
	NSBitmapImageRep * bitmap =  [[NSBitmapImageRep alloc]
								  initWithBitmapDataPlanes:NULL pixelsWide:pw
								  pixelsHigh:ph bitsPerSample:8 samplesPerPixel:1
								  hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace
								  bytesPerRow:0 bitsPerPixel:0];
	[bitmap setSize: [theimage size]];
	NSImage * image =[ [NSImage alloc] initWithSize:[theimage size ] ];
	NSGraphicsContext *nsContext = [NSGraphicsContext
									graphicsContextWithBitmapImageRep:bitmap];
	
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: nsContext];
	
	// Do I need a lockFocus here?
	[theimage drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect
				 operation:NSCompositeCopy fraction:1.0];
	
	// Restore the previous graphics context and state.
	[NSGraphicsContext restoreGraphicsState];
	
	[image addRepresentation: bitmap];
	[bitmap release];	
    
	NSData* tifdata=[image TIFFRepresentation];
	[tifdata writeToFile:savefilename atomically:YES];
    
    NSMutableArray* charimageArray=[self createCharImages:savefilename rects:rectarray chartexts:chartextarray];
    
 
	[image release];
	[theimage release];
	return charimageArray;
}

-(NSMutableArray*)createIplCharimageArray:(NSMutableArray*)charimageArray
{
    NSMutableArray* iplcharimageArray=[[[NSMutableArray alloc]init] autorelease];
    long counts=[charimageArray count];
    for( long loop=0; loop<counts; loop++ ){
        myImageObject* pobj=[charimageArray objectAtIndex:loop];
        NSImage* charimage=[[NSImage alloc]initWithContentsOfFile:[pobj getPath]];

        IplImage* iplimage=[self NSImageToIplImage:charimage];
        cvNot(iplimage,iplimage);
        //cvThreshold(iplimage, iplimage, 128., 255, CV_THRESH_BINARY);

        [charimage release];
        
        myIplImageObject* pIplimage=[[myIplImageObject alloc]init];
        [pIplimage setIplimage:iplimage];
        [pIplimage setChartext:[pobj getChartext]];
        [iplcharimageArray addObject:pIplimage];
        [pIplimage release];
    }
    return iplcharimageArray;
}

long getFirstPixline(IplImage* pImage)
{
    for( long row=0; row<pImage->height; row++ ){
        for(long col=0; col<pImage->width; col++ ){
            unsigned char pixvalue = ((unsigned char*)(pImage->imageData + pImage->widthStep*row))[col];   
            if( pixvalue>0 ){
                return row;
            }
        }
    }
    return -1;
}

-(NSString*)matchingproc:(NSImage*)bandimage imageArray:(NSMutableArray*)iplcharimageArray
{
    NSString* asctext=[NSString stringWithFormat:@""];
    // recognize row band image
    IplImage* iplrowimage=[self NSImageToIplImage:bandimage];
    cvNot(iplrowimage,iplrowimage);
    // check blank row
    CvScalar allspacecharScr=cvSum(iplrowimage);
    if( allspacecharScr.val[0]==0 ){
        return asctext;
    }
    long colmaxpos=iplrowimage->width;
    long colpos=0;
    while(true){
        if( colpos>=colmaxpos ){
            // end of row
            break;
        }
        // get row bits and matching each charimages
        long charcount=[iplcharimageArray count];
        // each char loop and find most match char index
        double matchmaxScore=0;
        long matchedindex=-1;
        for( long charloop=0; charloop<charcount; charloop++ ){
            myIplImageObject* pObj=[iplcharimageArray objectAtIndex:charloop];
            //NSLog(@"Matched charloop=%ld '%@'",charloop,[pObj getChartext] );
            IplImage* pCharIplimage=[pObj getIplimage];
            
            if( colpos+pCharIplimage->width+2>iplrowimage->width ){
                // over row pos
                colpos=colmaxpos;
                break;
            }
            
            CvRect roiRectCrop=cvRect(0,0,pCharIplimage->width,iplrowimage->height);
            CvRect roiRect=cvRect((int)colpos,0,pCharIplimage->width,iplrowimage->height);
            CvRect roiRectWide=cvRect((int)colpos,0,pCharIplimage->width+4,iplrowimage->height+4);
            //NSLog(@"roiRect %d %d %d %d",
            //      roiRect.width,roiRect.height,roiRectWide.width,roiRectWide.height);
            cvSetImageROI(iplrowimage, roiRect);
            IplImage* cropImage=cvCreateImage(
                cvSize(roiRectWide.width,roiRectWide.height), iplrowimage->depth, iplrowimage->nChannels);
            
            cvSetZero(cropImage);
            cvSetImageROI(cropImage, roiRectCrop);
            cvCopy(iplrowimage, cropImage);
            cvResetImageROI(cropImage);
            
/*
            NSImage *cropNSImage = [self IplImageToNSImage:cropImage];
            NSData* tifdata=[cropNSImage TIFFRepresentation];
            NSString* seqname=[NSString stringWithFormat:@"crop-%03d.tif",rowpos];
            NSString* savefilename=[self tmpWorkNameWithSuffix:seqname];
            [tifdata writeToFile:savefilename atomically:YES];
*/            
            BOOL detectWhiteChar=NO;
            CvScalar spacecharScr=cvSum(pCharIplimage);
            CvScalar resultscr=cvSum(cropImage);
            if( spacecharScr.val[0]==0 && resultscr.val[0]==0 ){
                // is white space
                //NSLog(@"detectWhiteChar=YES");
                matchedindex=charloop;
                matchmaxScore=pCharIplimage->width*pCharIplimage->height*255/4;
                detectWhiteChar=YES;
            }
            else {
                
                
                CvSize dstsize=cvSize (cropImage->width-pCharIplimage->width+1,
                                       cropImage->height-pCharIplimage->height+1);
                IplImage* resultimg = cvCreateImage (dstsize, IPL_DEPTH_32F, 1);
                cvMatchTemplate(cropImage, pCharIplimage, resultimg, CV_TM_CCOEFF_NORMED);
                double min_val=0, max_val=0;
                CvPoint min_loc, max_loc;
                cvMinMaxLoc (resultimg, &min_val, &max_val, &min_loc, &max_loc, NULL);
                if( max_val>0.35 && min_val!=max_val && matchmaxScore<max_val){
                    //NSLog(@"matching score =%f", max_val);
                    matchedindex=charloop;
                    matchmaxScore=max_val;
                }
                cvReleaseImage(&resultimg);
                
                
                /*
                // patern match method AND pixel count
                IplImage* andimg=cvCloneImage(cropImage);
                {
                    cvSetImageROI(andimg, roiRectCrop);
                    cvSetImageROI(cropImage, roiRectCrop);
                    cvSetImageROI(pCharIplimage, roiRectCrop);
                    cvAnd(cropImage, pCharIplimage, andimg);
                    CvScalar resultsum=cvSum(andimg);
                    double cost=resultsum.val[0];
                    double costThresh=1;
                    if( cost>costThresh && matchmaxScore<cost){
                        matchedindex=charloop;
                        matchmaxScore=cost;
                    }
                    cvResetImageROI(pCharIplimage);
                    cvResetImageROI(cropImage);
                    cvResetImageROI(andimg);
               
                }
                cvReleaseImage(&andimg);
                */
            }
            cvReleaseImage(&cropImage);
            cvResetImageROI(iplrowimage);
            if( detectWhiteChar ){
                break;
            }
        } // for
        // result matched char
        if( matchedindex!=-1 ){
            myIplImageObject* pObj=[iplcharimageArray objectAtIndex:matchedindex];
            //NSLog(@"Matched char='%@' colpos=%ld",[pObj getChartext], colpos );
            // next row position
            IplImage* pCharIplimage=[pObj getIplimage];
            colpos+=pCharIplimage->width;
            asctext=[asctext stringByAppendingString:[pObj getChartext]];
        }
        else {
            // not match any char
            myIplImageObject* pObj=[iplcharimageArray objectAtIndex:0];
            //NSLog(@"Matched char='%@' colpos=%ld",[pObj getChartext], colpos );
            // next row position
            IplImage* pCharIplimage=[pObj getIplimage];
            colpos+=pCharIplimage->width;
            asctext=[asctext stringByAppendingString:[pObj getChartext]];
        }
        
    }
    //cvReleaseImage(&iplrowimage);
    {
		// trim right space code
        NSString* fullspacechar=NSLocalizedString(@"fullspacechar", nil);
        unichar fullspacecharCode=[fullspacechar characterAtIndex:0];
		while([asctext length]>1){
			NSUInteger nowindex=[asctext length]-1;
			unichar thechar=[asctext characterAtIndex:nowindex];
			if( thechar==0x20 ){
				nowindex--;
				asctext=[asctext substringToIndex:nowindex];
			}
			else if( thechar==fullspacecharCode ){
				nowindex--;
				asctext=[asctext substringToIndex:nowindex];
			}
			else {
				break;
			}
		}
	}
    return asctext;
}

-(void)updateTextView:(NSString*)text
{
    [m_editview setString:text];
}

-(NSString*)domatching:(NSMutableArray*)imagearray imagesource:(NSImage*)srcimage
{
    if( [imagearray count]==0 ){
        return nil;
    }
    
    // create iplImage chartext array
    NSMutableArray* iplcharimageArray=[self createIplCharimageArray:imagearray];

    NSString* asctext=[NSString stringWithFormat:@""];
    
    myImageObject* pobj=[imagearray objectAtIndex:0];
    NSImage* charimage=[[NSImage alloc]initWithContentsOfFile:[pobj getPath]];
    NSSize charimagesize=[charimage size];
    [charimage release];
    
    NSSize srcimagesize=[srcimage size];
    long rowcount=srcimagesize.height/charimagesize.height;
    NSLog(@"row count=%ld",rowcount);
    m_totalrows=rowcount;

    
    NSRect srcrect=NSMakeRect(0,0,srcimagesize.width, srcimagesize.height);
    NSBitmapImageRep* bitmap = (NSBitmapImageRep*)[srcimage bestRepresentationForRect:srcrect context:nil hints:nil];
    NSRect rowbandrect=NSMakeRect(0,0,srcimagesize.width, charimagesize.height);
    // calculate row cycle by image height
    for( long loop=0; loop<rowcount; loop++ ){
        m_currow=loop; 
        // convert each row to ascii
        // get row band image
        NSImage *trimedImage = [[NSImage alloc] initWithSize:rowbandrect.size];
        [trimedImage addRepresentation:[self cropToRect:bitmap bounds:rowbandrect]];
        /*
        NSData* tifdata=[trimedImage TIFFRepresentation];
        NSString* seqname=[NSString stringWithFormat:@"band-%03d.tif",loop];
        NSString* savefilename=[self tmpWorkNameWithSuffix:seqname];
        [tifdata writeToFile:savefilename atomically:YES];
        */
        NSString* rowtext=[self matchingproc:trimedImage imageArray:iplcharimageArray];
        asctext=[asctext stringByAppendingString:rowtext];
        asctext=[asctext stringByAppendingString:@"\n"];
        [trimedImage release];
 
        [self performSelectorOnMainThread:@selector(updateTextView:) withObject:asctext waitUntilDone:YES];	

        
        rowbandrect=NSOffsetRect(rowbandrect, 0, charimagesize.height);
		if( m_cancelProc ){
			break;
		}
    }
    // release iplimage array
//    long iplcounts=[iplcharimageArray count];
//    for( long loop=0; loop<iplcounts; loop++ ){
//        myIplImageObject* pobj=[iplcharimageArray objectAtIndex:loop];
//        [pobj release];
//    }
    
    //NSLog(@"%@",asctext);
    return asctext;
}

-(void)updatebar
{
	CGFloat stage = m_currow / m_totalrows;
	//NSLog(@"updatebar stage=%f", stage);
	if( stage>=0 ){
		[m_progress setDoubleValue:stage];
		[m_progress setNeedsDisplay:YES];
	}
}

-(void)updateProgress:(id)sender
{
	//NSLog(@"updateProgress begin");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	while(TRUE){
		[self performSelectorOnMainThread:@selector(updatebar) withObject:nil waitUntilDone:YES];	
        
		usleep(500);
		if( m_cancelProc ){
			break;
		}
	}	
	
	[pool release];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:self];
	//NSLog(@"returnCode %d",returnCode);
}

- (void)startProgressUI
{
	
    [m_editview setString:@""];
    [m_editview setFont:[NSFont fontWithName:m_fontName size:m_fontSize]];
	
	[m_progress setDoubleValue:0.0];
	[m_progress setNeedsDisplay:YES];
	
	
	[NSApp beginSheet:m_progressWindow
	   modalForWindow:m_dialog	//[[NSApplication sharedApplication] mainWindow]
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
    
	[NSThread detachNewThreadSelector:@selector(updateProgress:) toTarget:self withObject:nil];
    
	
	
}

- (void)endProgressUI:(NSString*)resulttext
{
    // display as text
    [m_editview setString:resulttext]; 
    [m_editview setHorizontallyResizable:YES];
    [m_editview setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [[m_editview textContainer] setContainerSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
    [[m_editview textContainer] setWidthTracksTextView:NO]; 
    
    [m_btncopy setEnabled:YES];
	
	[NSApp endSheet:m_progressWindow];
	
}

-(void)traceImg:(NSString*)patchar
{
    m_currow=0; m_totalrows=1.;
    m_cancelProc=NO;
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[self performSelectorOnMainThread:@selector(startProgressUI) withObject:nil waitUntilDone:YES];	
    
    // cleanup work file
    // cleanup tempfolder
    NSString* systemcomstr =  [NSString stringWithFormat: @"rm -rf %@/com.mkanda.imgASCMAC/work", NSTemporaryDirectory()];
    system([systemcomstr UTF8String]);
    
    NSMutableArray* charImageArray=[self drawTextbox:patchar];
    // do matching
    CGImageRef cgimage=[m_imageView image];
    NSBitmapImageRep *bitmap_rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSImage* viewimage = [[[NSImage alloc] init] autorelease];
    [viewimage addRepresentation:bitmap_rep];
    
    NSString* asciitext=[self domatching:charImageArray imagesource:viewimage];
    
    [bitmap_rep release];

    // Finally, signal that we are done so that the UI becomes active again.
	[self performSelectorOnMainThread:@selector(endProgressUI:) withObject:asciitext waitUntilDone:YES];	
	
	// Clean out our auto release pool.
	[pool drain];
     
}

-(IBAction)patTraceImg:(id)sender
{
    
    NSString* tracetext=@"";
    if( m_tracemode==0 ){
        // pattern mode
        tracetext=NSLocalizedString(@"halfspacechar",nil);
        if( m_useZenkakuSpace ){
            tracetext=NSLocalizedString(@"fullspacechar",nil);
        }
        tracetext=[tracetext stringByAppendingString:NSLocalizedString(@"patterntracecharacters",nil)];
    }
    else if( m_tracemode==1 ){
        // edge mode 
        tracetext=NSLocalizedString(@"halfspacechar",nil);
        if( m_useZenkakuSpace ){
            tracetext=NSLocalizedString(@"fullspacechar",nil);
        }
        tracetext=[tracetext stringByAppendingString:NSLocalizedString(@"edgetracecharacters",nil)];
    }
    else if( m_tracemode==2 ){
        // custom char mode
        tracetext=NSLocalizedString(@"halfspacechar",nil);
        if( m_useZenkakuSpace ){
            tracetext=NSLocalizedString(@"fullspacechar",nil);
        }
        tracetext=[tracetext stringByAppendingString:m_customCharset];
    }
    
    [NSThread detachNewThreadSelector:@selector(traceImg:) toTarget:self withObject:tracetext];
    //[self traceImg:tracetext];
}

- (IBAction)OnZoomin:(id)sender
{
    [m_imageView setAutoresizes:NO];
    CGFloat zoomfactor=[m_imageView zoomFactor];
    zoomfactor=zoomfactor*2;
    [m_imageView setZoomFactor:zoomfactor];
    // zoom at center of image
//    NSSize imagesize=[m_imageView imageSize];
//    [m_imageView setImageZoomFactor:zoomfactor centerPoint:NSMakePoint(10,10)];
}

- (IBAction)OnZoomout:(id)sender
{
    [m_imageView setAutoresizes:NO];
    CGFloat zoomfactor=[m_imageView zoomFactor];
    zoomfactor=zoomfactor/2;
    [m_imageView setZoomFactor:zoomfactor];
 //  NSSize imagesize=[m_imageView imageSize];
 // [m_imageView setImageZoomFactor:zoomfactor centerPoint:NSMakePoint(imagesize.width/2, imagesize.height/2)];
}


- (IBAction)OnHandTool:(id)sender
{
    [m_handtool setIntValue:1];
    [m_areatool setIntValue:0];
	[m_imageView setCurrentToolMode:IKToolModeMove]; // IKToolModeCrop IKToolModeMove
    [m_croptool setEnabled:NO];
}

- (IBAction)OnAreaTool:(id)sender
{
    [m_handtool setIntValue:0];
    [m_areatool setIntValue:1];
	[m_imageView setCurrentToolMode:IKToolModeCrop]; // IKToolModeCrop IKToolModeRotate
    [m_croptool setEnabled:YES];
}

- (IBAction)OnCropTool:(id)sender
{
    [self doMakeUndo];
	[m_imageView crop:sender]; // IKToolModeCrop IKToolModeRotate
    
    CGImageRef cgimage=[m_imageView image];
    
    NSBitmapImageRep *bitmap_rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSImage* viewimage = [[[NSImage alloc] init] autorelease];
    [viewimage addRepresentation:bitmap_rep];
    
    NSString* imagesizestr=[NSString stringWithFormat:@"%.f x %.f",
                            [viewimage size].width,[viewimage size].height];
    [m_imagesize setStringValue:imagesizestr];
   
    [bitmap_rep release];
   
}

- (void)changeFont:(id)sender
{
	NSFont* font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	NSFont* convertedFont = [sender convertFont:font];
	
    m_fontName=[convertedFont fontName];
    m_fontSize=[convertedFont pointSize];

    NSString* titlestr=[NSString stringWithFormat:@"%@ %d", m_fontName, m_fontSize];
    [m_fonttool setTitle:titlestr];
}

- (void)changedFont:(id)sender
{
	NSFont* font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	NSFont* convertedFont = [sender convertFont:font];
	
    m_fontName=[convertedFont fontName];
    m_fontSize=[convertedFont pointSize];

    NSString* titlestr=[NSString stringWithFormat:@"%@ %d", m_fontName, m_fontSize];
    [m_fonttool setTitle:titlestr];
    //NSLog(@"changedFont %@  :%d", m_fontName,(int)m_fontSize);
}

-(IBAction)OnSelectFont:(id)sender
{
	NSFontPanel*	fontPanel;
	fontPanel = [NSFontPanel sharedFontPanel];
	if (![fontPanel isVisible]) {
		[fontPanel orderFront:self];
	}
    else {
		[fontPanel orderOut:self];        
    }
	[[NSFontManager sharedFontManager] 
        setSelectedFont:[NSFont fontWithName:m_fontName size:m_fontSize] isMultiple:NO];
    [[NSFontManager sharedFontManager] setDelegate:self];
    [[NSFontManager sharedFontManager] setAction:@selector(changedFont:)];
}

-(IBAction)OnCancelBtn:(id)sender
{
    m_cancelProc=YES;
}

@end
