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

import { BaseAdapter } from '../common/BaseAdapter';
import { BusinessError } from '@ohos.base';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { injectable } from 'inversify';
import LogMethod from '../common/LogDecorator';
import LogUtil from '../utils/LogUtil';
import userAuth from '@ohos.userIAM.userAuth';
import { JSON } from '@kit.ArkTS';

const TAG: string = 'DeviceUserAuthAdapter';
function doRandBySync() {
  let len = 24; // Generate a 24-byte random number.
  try {
    let rand = cryptoFramework.createRandom();
    let randData = rand.generateRandomSync(len);
    if (randData) {
      return randData.data;
    } else {
      LogUtil.error(TAG, `get rand result fail!`);
      return null;
    }
  } catch (error) {
    let e: BusinessError = error as BusinessError;
    LogUtil.error(TAG, `do rand failed, ${e.code}, ${e.message}`);
    return null;
  }
}

// userAuth widget
const widgetParam: userAuth.WidgetParam = {
  title: '',
};

@injectable()
export class DeviceUserAuthAdapter extends BaseAdapter {

  private isFingerPrintAvailable(): boolean {
    try {
      userAuth.getAvailableStatus(
        userAuth.UserAuthType.FINGERPRINT,
        userAuth.AuthTrustLevel.ATL3
      );
      return true;
    } catch (fingerprintErr) {
      LogUtil.error(TAG, `Fingerprint auth not supported. Code: ${fingerprintErr?.code}, message: ${fingerprintErr?.message}`);
      return false;
    }
  }

  private isFaceAvailable(): boolean {
    try {
      userAuth.getAvailableStatus(
        userAuth.UserAuthType.FACE,
        userAuth.AuthTrustLevel.ATL3
      );
      return true;
    } catch (faceErr) {
      LogUtil.error(TAG, `Face auth not supported. Code: ${faceErr?.code}, message: ${faceErr?.message}`);
      return false;
    }
  }

  @LogMethod
  checkBiometricAvailable(callback: (result: boolean, authType: number) => void): void {
    if (this.isFingerPrintAvailable()) {
      callback(true, userAuth.UserAuthType.FINGERPRINT);
    } else if (this.isFaceAvailable()) {
      callback(true, userAuth.UserAuthType.FACE);
    } else {
      callback(false, -1);
    }
  }

  startUserAuth(prompt_string: string, callback: Function, enableBiom: boolean, biomType: number){
    widgetParam.title = prompt_string;
    try {
      const authParam: userAuth.AuthParam = {
        challenge: doRandBySync() as Uint8Array,
        authType: [userAuth.UserAuthType.PIN],
        authTrustLevel: userAuth.AuthTrustLevel.ATL3,
      };
      if (enableBiom) {
        if(biomType === userAuth.UserAuthType.FACE) {
          authParam.authType.push(userAuth.UserAuthType.FACE);
        } else {
          authParam.authType.push(userAuth.UserAuthType.FINGERPRINT);
        }
      }
      let userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      userAuthInstance.on('result', {
        onResult(result) {
          userAuthInstance.off('result');
          if (result.result !== userAuth.UserAuthResultCode.SUCCESS) {
            // the user has not enrolled the authenticator, regard user auth successful
            const state: boolean = result.result == userAuth.UserAuthResultCode.NOT_ENROLLED;
            LogUtil.error(TAG, `userAuthInstance callback result failed: ${JSON.stringify(result)}`);
            callback(state);
            return;
          }
          callback(true);
        }
      });
      userAuthInstance.start();
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `auth catch error. Code is ${err?.code}, message is ${err?.message}`);
      callback(false)
    }
  }
}
