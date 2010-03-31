/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import "RuleEditor.h"

#import "Unit.h"

#import "Controller.h"
#import "BotController.h"
#import "SpellController.h"
#import "InventoryController.h"
#import "ActionMenusController.h"
#import "ConditionCell.h"
#import "BetterTableView.h"
#import "BetterSegmentedControl.h"
#import "HealthConditionController.h"
#import "StatusConditionController.h"
#import "AuraConditionController.h"
#import "DistanceConditionController.h"
#import "InventoryConditionController.h"
#import "ComboPointConditionController.h"
#import "AuraStackConditionController.h"
#import "TotemConditionController.h"
#import "TempEnchantConditionController.h"
#import "TargetTypeConditionController.h"
#import "TargetClassConditionController.h"
#import "CombatCountConditionController.h"
#import "ProximityCountConditionController.h"
#import "SpellCooldownConditionController.h"
#import "LastSpellCastConditionController.h"
#import "RuneConditionController.h"

#import "Macro.h"
#import "Action.h"

#import "BetterSegmentedControl.h"


@interface RuleEditor (Internal)
@end

@implementation RuleEditor
- (id) init
{
    self = [super init];
    if (self != nil) {
        _conditionList = [[NSMutableArray array] retain];
        
        _spellsMenu = nil;
        _itemsMenu = nil;
        _macrosMenu = nil;
		_interactMenu = nil;
    }
    return self;
}

- (void)awakeFromNib {
    // set our column to use a Rule Cell
    NSTableColumn *column = [spellRuleTableView tableColumnWithIdentifier: @"Conditions"];
	[column setDataCell: [[[ConditionCell alloc] init] autorelease]];
	[column setEditable: NO];
}

@synthesize validSelection;

- (void)validateBindings {
    self.validSelection = [spellRuleTableView numberOfSelectedRows] ? YES : NO;
}

- (NSWindow*)window {
    return ruleEditorWindow;
}


- (Rule*)rule {
    NSMutableArray *conditions = [NSMutableArray array];
    
    for(ConditionController* condController in _conditionList) {
        Condition *condition = nil;
        if((condition = [condController condition]))
            [conditions addObject: [condController condition]];
    }
    
    Rule *newRule = nil;
    if([conditions count]) {
		
		NSNumber *value = [NSNumber numberWithUnsignedInt: [[resultActionDropdown selectedItem] tag]];
		
        newRule = [[Rule alloc] init];
        
        [newRule setName: [ruleNameText stringValue]];
        [newRule setConditions: conditions];
        [newRule setIsMatchAll: [conditionMatchingSegment isSelectedForSegment: 0]];
        [newRule setAction: [Action actionWithType: [conditionResultTypeSegment selectedTag] 
                                             value: value]];
		[newRule setTarget: [conditionTargetType selectedTag]];
        //[newRule setResultType: [conditionResultTypeSegment selectedTag]];
        //[newRule setActionID: [[resultActionDropdown selectedItem] tag]];
        
        // PGLog(@"Created Rule: %@", newRule);
    }
    
    return [newRule autorelease];
}

- (void)initiateEditorForRule: (Rule*)rule {
    [_spellsMenu release];  _spellsMenu = nil;
    [_itemsMenu release];   _itemsMenu = nil;
    [_macrosMenu release];  _macrosMenu = nil;
	[_interactMenu release]; _interactMenu = nil;
    [_conditionList removeAllObjects];

    // get our result menus
    _spellsMenu		= [[[ActionMenusController sharedMenus] menuType: MenuType_Spell actionID: [rule actionID]] retain];        // [[spellController playerSpellsMenu] retain];
    _itemsMenu		= [[[ActionMenusController sharedMenus] menuType: MenuType_Inventory actionID: [rule actionID]] retain];    // [[inventoryController prettyInventoryItemsMenu] retain];
    _macrosMenu		= [[[ActionMenusController sharedMenus] menuType: MenuType_Macro actionID: [rule actionID]] retain];        // [[self createMacroMenu] retain];
	_interactMenu	= [[[ActionMenusController sharedMenus] menuType: MenuType_Interact actionID: [rule actionID]] retain];    // [[inventoryController prettyInventoryItemsMenu] retain];

	[conditionResultTypeSegment selectSegmentWithTag: [rule resultType]];
    [self setResultType: conditionResultTypeSegment];   // this also sets the menu

	if ( rule != nil )
		[conditionTargetType selectSegmentWithTag: [rule target]];
	else
		[conditionTargetType unselectAllSegments];

    
    if(rule) {
        for(Condition *condition in [rule conditions]) {
            [_conditionList addObject: [ConditionController conditionControllerWithCondition: condition]];
        }
        
        if( [rule isMatchAll] )
            [conditionMatchingSegment selectSegmentWithTag: 0];
        else
            [conditionMatchingSegment selectSegmentWithTag: 1];
        
        // if we dont have a real spell list (or our spell doesn't exist in the list), create a temporary one with just one spell
        if(![resultActionDropdown selectItemWithTag: [rule actionID]]) {
            
            
            NSMenu *noActionMenu = [[[NSMenu alloc] initWithTitle: @"No Menu"] autorelease];
            NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: @"Error building menu." action: nil keyEquivalent: @""] autorelease];
            
            [menuItem setTag: [rule actionID]];
            [noActionMenu addItem: menuItem];
            
            [resultActionDropdown setMenu: noActionMenu];
            [resultActionDropdown selectItemWithTag: [rule actionID]];
        }
    }
    
    if( [rule name] )
        [ruleNameText setStringValue: [rule name]];
    else 
        [ruleNameText setStringValue: [NSString string]];
    
    [spellRuleTableView reloadData];
    [self validateBindings];
}

- (IBAction)addCondition:(id)sender {
    //PGLog(@"adding condition");
    
    int type = [[spellRuleTypeDropdown selectedItem] tag];
    ConditionController *newRule = nil;
    
    if(type == 1)   newRule = [[[HealthConditionController alloc] init] autorelease];
    if(type == 2)   newRule = [[[StatusConditionController alloc] init] autorelease];
    if(type == 3)   newRule = [[[AuraConditionController alloc] init] autorelease];
    if(type == 4)   newRule = [[[DistanceConditionController alloc] init] autorelease];
    if(type == 5)   newRule = [[[InventoryConditionController alloc] init] autorelease];
    if(type == 6)   newRule = [[[ComboPointConditionController alloc] init] autorelease];
    if(type == 7)   newRule = [[[AuraStackConditionController alloc] init] autorelease];
    if(type == 8)   newRule = [[[TotemConditionController alloc] init] autorelease];
    if(type == 9)   newRule = [[[TempEnchantConditionController alloc] init] autorelease];
    if(type == 10)   newRule = [[[TargetTypeConditionController alloc] init] autorelease];
    if(type == 11)   newRule = [[[TargetClassConditionController alloc] init] autorelease];
    if(type == 12)   newRule = [[[CombatCountConditionController alloc] init] autorelease];
    if(type == 13)   newRule = [[[ProximityCountConditionController alloc] init] autorelease];
	if(type == 14)   newRule = [[[SpellCooldownConditionController alloc] init] autorelease];
	if(type == 15)   newRule = [[[LastSpellCastConditionController alloc] init] autorelease];
	if(type == 16)   newRule = [[[RuneConditionController alloc] init] autorelease];
    
    if(newRule) {
        [_conditionList addObject: newRule];
        [spellRuleTableView reloadData];
        [spellRuleTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [_conditionList count] - 1] byExtendingSelection: NO];
        
        [sender selectItemWithTag: 0];
    }
    [self validateBindings];
}

- (IBAction)testRule:(id)sender {
    [botController testRule: [self rule]];
}

- (IBAction)testCondition:(id)sender {
    int row = [spellRuleTableView selectedRow];
    if(row == -1) {
        NSBeep();
        return;
    }
    
    Condition *condition = [(ConditionController*)[_conditionList objectAtIndex: row] condition];
    if(condition) {
        Rule *rule = [self rule];
        if(rule) {
            [rule setConditions: [NSArray arrayWithObject: condition]];
            [botController testRule: rule];
        }
    }
}

- (IBAction)saveRule:(id)sender {
	
    [[sender window] makeFirstResponder: [[sender window] contentView]];
	
	// check to see if a target is selected! It's now required!
	BOOL targetSelected = NO;
	int i;
	for ( i = 0; i < [conditionTargetType segmentCount]; i++ ){
		if ( [conditionTargetType isSelectedForSegment:i] ){
			targetSelected = YES;
			break;
		}
	}
    
    if( [[ruleNameText stringValue] length] && targetSelected ) {
		[labelNoTarget setHidden:YES];
        [NSApp endSheet: [self window] returnCode: RuleEditorSaveRule];
        [[self window] orderOut: nil];
    } else {
		
		NSBeep();

		NSRunAlertPanel(@"Select a target", @"You must choose a valid target, or your character will never attack or heal.", @"Okay", NULL, NULL);
		
		if ( !targetSelected ){
			[labelNoTarget setHidden:NO];
		}
    }
}

- (IBAction)cancelRule:(id)sender {
    [NSApp endSheet: [self window] returnCode: RuleEditorCancelRule];
    [[self window] orderOut: nil];
}

- (IBAction)setResultType:(id)sender {
    int oldTag = [[resultActionDropdown selectedItem] tag];
    
    if([sender selectedTag] == ActionType_Spell) {
        [resultActionDropdown setMenu: _spellsMenu];
    }
    if([sender selectedTag] == ActionType_Item) {
        [resultActionDropdown setMenu: _itemsMenu];
    }
    if([sender selectedTag] == ActionType_Macro) {
        [resultActionDropdown setMenu: _macrosMenu];        
    }
    if([sender selectedTag] == ActionType_None) {
        NSMenu *noActionMenu = [[[NSMenu alloc] initWithTitle: @"No Action"] autorelease];
        NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: @"Perform no action." action: nil keyEquivalent: @""] autorelease];

        [menuItem setTag: 0];
        [noActionMenu addItem: menuItem];
        
        [resultActionDropdown setMenu: noActionMenu];
        [resultActionDropdown selectItemWithTag: 0];
    }
    if( [[resultActionDropdown menu] itemWithTag: oldTag] ) {
        [resultActionDropdown selectItemWithTag: oldTag];
    }
}

#pragma mark -
#pragma mark TableView Delegate/DataSource

- (void) tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
	if( [[tableColumn identifier] isEqualToString: @"Conditions"] ) {
		NSView *view = [[_conditionList objectAtIndex: row] view];
		[(ConditionCell*)cell addSubview: view];
	}
}

// Methods from NSTableDataSource protocol
- (int) numberOfRowsInTableView:(NSTableView *) tableView
{
    return [_conditionList count];
}

- (id) tableView:(NSTableView *) tableView objectValueForTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
	return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self validateBindings];
}

- (void)tableView: (NSTableView*)tableView deleteKeyPressedOnRowIndexes: (NSIndexSet*)rowIndexes {
    if([rowIndexes count] == 0)   return;
    
    int row = [rowIndexes lastIndex];
    while(row != NSNotFound) {
        [_conditionList removeObjectAtIndex: row];
        row = [rowIndexes indexLessThanIndex: row];
    }
    [spellRuleTableView reloadData];
}

- (BOOL)tableView:(NSTableView *)tableView shouldTypeSelectForEvent:(NSEvent *)event withCurrentSearchString:(NSString *)searchString {
    return NO;
}



@end
