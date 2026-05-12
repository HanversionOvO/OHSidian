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
import Base from "@ohos.base";
import BatteryInfo from '@ohos.batteryInfo';
import CommonEventManager from '@ohos.commonEventManager';
import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

const TAG: string = 'PowerMonitor';
const ENTER_FORCE_SLEEP: string = "usual.event.ENTER_FORCE_SLEEP";
const EXIT_FORCE_SLEEP: string = "usual.event.EXIT_FORCE_SLEEP";
const POWER_CONNECTED: string = "usual.event.POWER_CONNECTED";
const POWER_DISCONNECTED: string = "usual.event.POWER_DISCONNECTED";
const subscribeInfo: CommonEventManager.CommonEventSubscribeInfo = {
  events: [
    ENTER_FORCE_SLEEP,
    EXIT_FORCE_SLEEP,
    POWER_CONNECTED,
    POWER_DISCONNECTED,
  ],
};

let adapterOwner : PowerMonitorAdapter | undefined = undefined;

function callbackFunc(err: Base.BusinessError, data: CommonEventManager.CommonEventData) {
  if (err) {
    LogUtil.error(TAG, `subscribe failed, cause ${JSON.stringify(err)}`);
    return;
  }
  const evt = data.event;
  switch (evt) {
    case ENTER_FORCE_SLEEP:
      adapterOwner?.getNativeContext().PowerMonitor.OnSuspend();
      break;
    case EXIT_FORCE_SLEEP:
      adapterOwner?.getNativeContext().PowerMonitor.OnResume();
      break;
    case POWER_CONNECTED:
    case POWER_DISCONNECTED:
      adapterOwner?.getNativeContext().PowerMonitor.OnPowerStateChanged();
      break;
    default:
      LogUtil.warn(TAG, `PowerMonitor unknown event: ${evt}`);
      return;
  }
}

@injectable()
export class PowerMonitorAdapter extends BaseAdapter {
  private subscriber: CommonEventManager.CommonEventSubscriber | undefined = undefined;

  constructor() {
    super();
    this.subscribePowerEvent();
    adapterOwner = this;
  }

  private subscribePowerEvent() {
    try {
      this.subscriber = CommonEventManager.createSubscriberSync(subscribeInfo);
      CommonEventManager.subscribe(this.subscriber, callbackFunc)
    } catch (error) {
      let err: Base.BusinessError = error as Base.BusinessError;
      LogUtil.error(TAG, `create SubscriberSync failed, cause ${JSON.stringify(err)}`);
    }
  }

  @LogMethod
  isOnBatteryPower(): boolean {
    return BatteryInfo.pluggedType == BatteryInfo.BatteryPluggedType.NONE;
  }
}
