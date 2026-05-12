/*
 * Copyright (c) 2023-2025 Haitai FangYuan Co., Ltd.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of
 *    conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list
 *    of conditions and the following disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used
 *    to endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import { injectable } from 'inversify';
import Base from '@ohos.base';
import CommonEventManager from '@ohos.commonEventManager';

import { BaseAdapter } from '../common/BaseAdapter';
import { BatteryInfo } from '../interface/CommonInterface'
import batteryInfo from '@ohos.batteryInfo'
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

const INVALID_VALUE: number = -1;
const TAG: string = 'BatteryAdapter';
const SUBSCRIBE_INFO: CommonEventManager.CommonEventSubscribeInfo = {
  events: [
    CommonEventManager.Support.COMMON_EVENT_BATTERY_CHANGED,
    CommonEventManager.Support.COMMON_EVENT_POWER_CONNECTED,
    CommonEventManager.Support.COMMON_EVENT_POWER_DISCONNECTED
  ]
};

@injectable()
export class BatteryAdapter extends BaseAdapter {
  private subscriber: CommonEventManager.CommonEventSubscriber | undefined = undefined;
  private batteryStatus: BatteryInfo = {
    batterySOC: -1,
    chargingStatus: -1,
    isBatteryPresent: false,
    estimatedRemainingChargeTime: INVALID_VALUE,
    nowCurrent: INVALID_VALUE,
    remainingEnergy: INVALID_VALUE
  };

  private subscribeCallBack(err: Base.BusinessError, data: CommonEventManager.CommonEventData, callback: (batteryStatus: BatteryInfo) => void) {
    if (err) {
      LogUtil.error(TAG, 'subscribe failed, code is %{public}d, error: ' + JSON.stringify(err));
      return;
    }
    const params = data.parameters;
    if (params === undefined || params["chargeState"] === undefined ||
      params["present"] === undefined || params["soc"] === undefined) {
      LogUtil.warn(TAG, 'subscribe event params is invalid.');
      return;
    }
    if (this.batteryStatus.batterySOC !== (params["soc"] as number) ||
      this.batteryStatus.chargingStatus !== (params["chargeState"] as number) ||
      this.batteryStatus.isBatteryPresent !== (params["present"] as boolean)) {
      this.batteryStatus.batterySOC = params["soc"] as number;
      this.batteryStatus.chargingStatus = params["chargeState"] as number;
      this.batteryStatus.isBatteryPresent = params["present"] as boolean;
      callback(this.batteryStatus);
    }
  }

  private createSubscriberCallBack(err: Base.BusinessError,
                                   sub: CommonEventManager.CommonEventSubscriber,
                                   callback: (batteryStatus: BatteryInfo) => void) {
    if (err) {
      LogUtil.error(TAG, 'createSubscriber failed, error: ' + JSON.stringify(err));
      return;
    }
    if (!sub) {
      LogUtil.error(TAG, 'The envent subscriber does not exist');
      return;
    }
    this.subscriber = sub;
    CommonEventManager.subscribe(this.subscriber,
      (err: Base.BusinessError, data: CommonEventManager.CommonEventData) => this.subscribeCallBack(err, data, callback));
  }

  @LogMethod
  GetBatteryInfo(callback: (batteryStatus: BatteryInfo) => void): boolean {
    try {
      this.batteryStatus.batterySOC = batteryInfo.batterySOC;
      this.batteryStatus.chargingStatus = batteryInfo.chargingStatus as number;
      this.batteryStatus.isBatteryPresent = batteryInfo.isBatteryPresent;
      if (callback) {
        callback(this.batteryStatus);
      }
    } catch (err) {
      LogUtil.error(TAG, 'Failed to obtain battery status, error:' + JSON.stringify(err));
      return false;
    }
    return true;
  }

  @LogMethod
  registerBatteryUpdateCallback(callback: (batteryStatus: BatteryInfo) => void): boolean {
    try {
      if (!callback) {
        LogUtil.warn(TAG, 'subscribe call back is not exist');
        return false;
      }
      CommonEventManager.createSubscriber(SUBSCRIBE_INFO,
        (err: Base.BusinessError, sub: CommonEventManager.CommonEventSubscriber) => this.createSubscriberCallBack(err, sub, callback));
    } catch (err) {
      LogUtil.error(TAG, 'createSubscriber failed, code is %{public}d, error: ' + JSON.stringify(err));
      return false;
    }
    return true;
  }

  @LogMethod
  unregisterBatteryUpdateCallback(): void {
    try {
      if (!this.subscriber) {
        LogUtil.warn(TAG, 'The envent subscriber does not exist');
        return;
      }
      CommonEventManager.unsubscribe(this.subscriber, (err:Base.BusinessError) => {
        if (err) {
          LogUtil.error(TAG, 'unsubscribe failed, error: ' + JSON.stringify(err));
        }
      });
    } catch (err) {
      LogUtil.error(TAG, 'unsubscribe failed, error: ' + JSON.stringify(err));
    }
  }
};
