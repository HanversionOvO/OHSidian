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

import { inject, injectable } from 'inversify';
import connection from '@ohos.net.connection';
import { BusinessError } from '@ohos.base';
import Want from '@ohos.app.ability.Want';

import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';
import LaunchHelper from '../utils/LaunchHelper';
import { ContextAdapter } from './ContextAdapter';
import CommonEventManager from '@ohos.commonEventManager';

const TAG: string = 'net';

@injectable()
export class NetConnectionAdapter extends BaseAdapter {
  private netCon: connection.NetConnection | undefined = undefined;
  private registered: boolean = false;

  private subscribeInfo: CommonEventManager.CommonEventSubscribeInfo = {
    events: [CommonEventManager.Support.COMMON_EVENT_CONNECTIVITY_CHANGE]
  };
  private subscriber: CommonEventManager.CommonEventSubscriber | undefined = undefined;  
  private ctxAdapter: ContextAdapter;

  constructor(@inject(ContextAdapter) ctxAdapter: ContextAdapter) {
    super();
    this.ctxAdapter = ctxAdapter;
  }

  private getNetConnect(): connection.NetConnection {
    if (!this.netCon) {
      this.netCon = connection.createNetConnection();
    }
    if (!this.registered) {
      this.netCon.register((error: BusinessError) => {
        if (error) {
          LogUtil.error(TAG, `register error: ${JSON.stringify(error)}.`);
        }
      });
      this.registered = true;
    }
    return this.netCon;
  }

  @LogMethod
  netAvailable(callback: Function): void {
    this.getNetConnect().on('netAvailable', () => {
      callback();
    });
  }

  @LogMethod
  netCapabilitiesChange(callback: Function): void {
    this.getNetConnect().on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
      const bearerTypes: number[] = data.netCap.bearerTypes;
      const type = bearerTypes.length > 0 ? bearerTypes[0] : 0;
      callback(type, 0);
    });
  }

  @LogMethod
  netConnectionPropertiesChange(callback: Function): void {
    try {
      this.getNetConnect().on('netConnectionPropertiesChange', () => {
        callback();
      });
    } catch (err) {
      LogUtil.error(TAG, `netConnectionPropertiesChange error: ${JSON.stringify(err)}.`);
    }
    try {
      CommonEventManager.createSubscriber(this.subscribeInfo,
        (err: BusinessError, sub: CommonEventManager.CommonEventSubscriber) => {
          if (err) {
            LogUtil.error(TAG, `createSubscriber error: ${JSON.stringify(err)}.`);
            return;
          }
          this.subscriber = sub;
          CommonEventManager.subscribe(this.subscriber, () => {
            callback();
          });
        });
    } catch (err) {
      LogUtil.error(TAG, `createSubscriber error: ${JSON.stringify(err)}.`);
    }
  }

  @LogMethod
  netUnavailable(callback: Function): void {
    this.getNetConnect().on('netUnavailable', () => {
      callback();
    });
  }

  @LogMethod
  netLost(callback: Function): void {
    this.getNetConnect().on('netLost', () => {
      callback();
    });
  }

  @LogMethod
  unregisterAll(): void {
    this.getNetConnect().unregister((error: BusinessError) => {
      if (error) {
        LogUtil.error(TAG, `unregister error: ${JSON.stringify(error)}.`);
      }
    });
  }

  @LogMethod
  showSystemSettings(uri_value: string,
    subUri?: string): void {
    let want: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: uri_value
    }
    if (subUri !== undefined) {
      want.parameters = {
        'subUri': subUri
      }
    }
    LaunchHelper.Launch(this.ctxAdapter.getActiveContext(), want);
  }
}
