//
//  ViewController.m
//  Beacons
//
//  Created by Matt Goodall on 04/09/2014.
//  Copyright (c) 2014 Matt Goodall. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "ViewController.h"

static NSString* proximityDecription(CLProximity proximity) {
    switch (proximity) {
        case CLProximityImmediate:
            return @"immediate";
        case CLProximityNear:
            return @"near";
        case CLProximityFar:
            return @"far";
        case CLProximityUnknown:
            return @"unknown";
    }
    return @"???";
}

@interface Beacon : NSObject
@property (nonatomic) int major;
@property (nonatomic) int minor;
@property (nonatomic) double accuracy;
@property (nonatomic) long rssi;
@property (strong, nonatomic) NSString *proximity;
@end

@implementation Beacon
- (id) init:(CLBeacon*)beacon {
    self = [super init];
    self.major = [beacon.major intValue];
    self.minor = [beacon.minor intValue];
    self.accuracy = [beacon.minor doubleValue];
    self.rssi = beacon.rssi;
    self.proximity = proximityDecription(beacon.proximity);
    return self;
}
@end

@interface BeaconCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *majorLabel;
@property (weak, nonatomic) IBOutlet UILabel *minorLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UILabel *accuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel *proximityLabel;
@end

@implementation BeaconCell
@end

@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *uuidTextField;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic) int minor;

@property (strong, nonatomic) NSMutableArray *regions;
@property (strong, nonatomic) NSMutableArray *beacons;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.regions = [[NSMutableArray alloc] init];
    self.beacons = [[NSMutableArray alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titles[] = {@"Region", @"Beacon"};
    return titles[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat heights[] = {44, 122};
    return heights[indexPath.section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.regions.count;
    }
    if (section == 1) {
        return self.beacons.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"region"];
        cell.textLabel.text = self.regions[indexPath.row];
        return cell;
    }
    if (indexPath.section == 1) {
        BeaconCell *cell = [tableView dequeueReusableCellWithIdentifier:@"beacon"];
        Beacon *beacon = self.beacons[indexPath.row];
        cell.majorLabel.text = [NSString stringWithFormat:@"0x%02X", beacon.major];
        cell.minorLabel.text = [NSString stringWithFormat:@"0x%02X", beacon.minor];
        cell.rssiLabel.text = [NSString stringWithFormat:@"%ld", beacon.rssi];
        cell.accuracyLabel.text = [NSString stringWithFormat:@"%lf", beacon.accuracy];
        cell.proximityLabel.text = beacon.proximity;
        return cell;
    }
    return nil;
}

- (IBAction)scan:(id)sender {
    NSLog(@"scan");
    NSString *uuid = [self.uuidTextField text];
    [self startScanning:uuid];
}

- (void) startScanning:(NSString*)uuid {

    self.minor = 0;

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc]
                                    initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid]
                                    identifier:@"Home"];
    beaconRegion.notifyEntryStateOnDisplay = true;

    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];

    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"didEnterRegion: %@", region);
    for (int i=0; i<self.regions.count; i++) {
        NSString *identifier = self.regions[i];
        if ([region.identifier isEqualToString:identifier]) {
            return;
        }
    }
    [self.regions addObject:region.identifier];
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"didExitRegion: %@", region.identifier);
    for (int i=0; i<self.regions.count; i++) {
        NSString *identifier = self.regions[i];
        if ([region.identifier isEqualToString:identifier]) {
            [self.regions removeObjectAtIndex:i];
            [self.tableView reloadData];
            return;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"beacons: %@", beacons);
    [self.beacons removeAllObjects];
    for (int i=0; i<beacons.count; i++) {
        CLBeacon *beacon = beacons[i];
        [self.beacons addObject:[[Beacon alloc] init:beacon]];
    }
    [self.tableView reloadData];
}

@end
