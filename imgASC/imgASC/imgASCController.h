//
//  imgASCController.h
//  imgASC
//
//  Created by Masanori Kanda on 11/05/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "cv.h"
//#import "highgui.h"

/*
@interface ScrollViewWorkaround : NSScrollView {
    
}
@end
*/

@interface DraggableImageView : IKImageView 
{
	id	parentController;
}

- (void)setParentController:(id)parent;
@end


@interface imgASCController : NSObject<NSMenuDelegate,NSToolbarDelegate,NSOpenSavePanelDelegate> 
{
    IBOutlet	NSWindow*			m_dialog;
    IBOutlet    DraggableImageView* m_imageView;
    
    IBOutlet    NSButton*           m_handtool;
    IBOutlet    NSButton*           m_areatool;
    IBOutlet    NSButton*           m_croptool;
    IBOutlet    NSButton*           m_fonttool;
    IBOutlet    NSButton*           m_zoomintool;
    IBOutlet    NSButton*           m_zoomouttool;
	IBOutlet	NSButton*           m_tracemodetool;
    
	IBOutlet	NSToolbar*			m_toolbar;
 	IBOutlet	NSMenu*				m_menuFile;
	IBOutlet	NSMenu*				m_menuEdit;
	IBOutlet	NSTextView*         m_editview;
    IBOutlet    NSTextField*        m_imagesize;
    
    IBOutlet    NSButton*           m_btnresizeUp;
    IBOutlet    NSButton*           m_btnresizedown;
    IBOutlet    NSButton*           m_btninvert;
    IBOutlet    NSButton*           m_btnedge;
    IBOutlet    NSButton*           m_btnblackwhite;
    IBOutlet    NSButton*           m_btntrace;
    IBOutlet    NSButton*           m_btncopy;

    
    IBOutlet    NSProgressIndicator* m_progress;
	IBOutlet    NSWindow*           m_progressWindow;
	IBOutlet    NSWindow*           m_customCharWindow;
    IBOutlet    NSTextField*        m_edit_PatterOrEdgeChar;
    IBOutlet    NSTextField*        m_edit_customchar;
    IBOutlet    NSSegmentedControl* m_segment_tracemode;
    IBOutlet    NSButton*           m_check_useZenkakuspace;
  
    BOOL                m_imageloaded;
    BOOL                m_tracingnow;
    BOOL                m_cancelProc;
    float               m_currow;
    float               m_totalrows;
    BOOL                m_useZenkakuSpace;
    
    NSImage*            m_img;
    
    NSMutableArray*     m_undolist;
    NSMutableArray*     m_redolist;
    
	NSInteger           m_tracemode; 
	NSInteger           m_fontSize; 
	NSString*           m_fontName;
    NSString*           m_customCharset;
 
   // NSMutableArray*     m_charimagelist;

} 

-(IBAction)OnOKEditCustomChar:(id)sender;
-(IBAction)OnCancelEditCustomChar:(id)sender;
-(IBAction)OnChangeTraceModeSegmentCtrl:(id)sender;

-(IBAction)OnChangeTraceMode:(id)sender;

// progress control
-(IBAction)OnCancelBtn:(id)sender;


-(IBAction)OnCopy:(id)sender;

-(IBAction)openImg:(id)sender;
-(IBAction)newFromClipboard:(id)sender;

-(IBAction)OnZoomin:(id)sender;
-(IBAction)OnZoomout:(id)sender;
-(IBAction)OnHandTool:(id)sender;
-(IBAction)OnAreaTool:(id)sender;
-(IBAction)OnCropTool:(id)sender;
-(IBAction)OnSelectFont:(id)sender;


-(IBAction)imgBlackWhite:(id)sender;
-(IBAction)imgEdge:(id)sender;
-(IBAction)imgDilation:(id)sender;
-(IBAction)imgErosion:(id)sender;
-(IBAction)imgThinning:(id)sender;

// imaging proc
-(IBAction)patTraceImg:(id)sender;
-(IBAction)imgResizeUp:(id)sender;
-(IBAction)imgResizeDown:(id)sender;
-(IBAction)imgReverse:(id)sender;

// edit menu handle
-(IBAction)editUndo:(id)sender;
-(IBAction)editRedo:(id)sender;

-(BOOL)isTracingNow; 
-(void)openDragImage:(NSURL*)url;
 
@end
