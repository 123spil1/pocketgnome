//
//  MPTaskPartyWait.h
//  Pocket Gnome
//
//  Created by codingMonkey on 4/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class MPActivityWait;
@class MPTimer;


/*!
 * @class      MPTaskPartyWait
 * @abstract   Wait for party members to arrive before moving too far away.
 * @discussion 
 * The PartyWait task is used when botting groups/parties.  This task will 
 * scan all party members and stop when a party member is farther than 
 * $MaxDistance away.  
 *
 * When all members of a pary ar within $MaxDistance away, then this task 
 * will no longer want to do anything.
 * 
 * <code>
 *	 PartyWait
 *	 {
 *		$Prio  = 3;
 *		$MaxDistance = 20; // When party members gets this far away, stop and wait
 *	 }
 * </code>
 *		
 */

@interface MPTaskPartyWait : MPTask {
	float maxDistance;
	
	NSArray *listParty;
	MPActivityWait *activityWait;
	MPTimer *timerRefreshListParty;
}
@property (retain) NSArray *listParty;
@property (retain) MPActivityWait *activityWait;
@property (retain) MPTimer *timerRefreshListParty;



/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;
@end