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
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

const TAG: string = "ScreenlockMonitorAdapter";
const SCREEN_LOCKED: string = "usual.event.SCREEN_LOCKED";
const SCREEN_UNLOCKED: string = "usual.event.SCREEN_UNLOCKED";

@injectable()
export class ScreenlockMonitorAdapter extends BaseAdapter {
  private subscriber: CommonEventManager.CommonEventSubscriber | undefined = undefined;
  private subscribeInfo: CommonEventManager.CommonEventSubscribeInfo = {
    events: [
      CommonEventManager.Support.COMMON_EVENT_SCREEN_LOCKED,
      CommonEventManager.Support.COMMON_EVENT_SCREEN_UNLOCKED
    ]
  };

  private subscribeScreenlock(callback: Function, subscriber: CommonEventManager.CommonEventSubscriber) {
    CommonEventManager.subscribe(subscriber,
      (err: Base.BusinessError, data:CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtil.error(TAG, 'subscribe failed, error: ' + JSON.stringify(err));
          return;
        }
        if(data.event === SCREEN_LOCKED) {
          callback('locked');
        } else if (data.event === SCREEN_UNLOCKED) {
          callback('unlocked');
        }
      });
  }

  @LogMethod
  startListeningForScreenlock(callback: Function): void {
    try {
      CommonEventManager.createSubscriber(this.subscribeInfo,
        (err: Base.BusinessError, commonEventSubscriber: CommonEventManager.CommonEventSubscriber) => {
          if (err) {
            LogUtil.error(TAG, 'createSubscriber failed, error: ' + JSON.stringify(err));
            return;
          }
          this.subscriber = commonEventSubscriber;
          this.subscribeScreenlock(callback, this.subscriber)
        });
    } catch (err) {
      LogUtil.error(TAG, 'createSubscriber failed, error: ' + JSON.stringify(err));
    }
  }

  @LogMethod
  stopListeningForScreenlock(): void {
    try {
      CommonEventManager.unsubscribe(this.subscriber, (err:Base.BusinessError) => {
        LogUtil.info(TAG, 'unsubscribe err: ' + JSON.stringify(err));
      });
    } catch (err) {
      LogUtil.error(TAG, 'unsubscribe failed, error: ' + JSON.stringify(err));
    }
  }
};
