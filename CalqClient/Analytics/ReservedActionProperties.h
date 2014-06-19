/*
 *  Copyright 2014 Calq.io
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
 *  compliance with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is
 *  distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied. See the License for the specific language governing permissions and limitations under the
 *  License.
 *
 */

#import <Foundation/Foundation.h>

@interface ReservedActionProperties : NSObject

extern NSString *SaleValue;
extern NSString *SaleCurrency;

extern NSString *DeviceAgent;
extern NSString *DeviceOs;
extern NSString *DeviceResolution;
extern NSString *DeviceMobile;

extern NSString *Country;
extern NSString *Region;
extern NSString *City;

extern NSString *Gender;
extern NSString *Age;

extern NSString *UtmCampaign;
extern NSString *UtmSource;
extern NSString *UtmMedium;
extern NSString *UtmContent;
extern NSString *UtmTerm;

@end
