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

import { injectable, inject } from 'inversify';
import Want from '@ohos.app.ability.Want';

import { BaseAdapter } from '../common/BaseAdapter';
import LaunchHelper from '../utils/LaunchHelper';
import LogMethod from '../common/LogDecorator';
import LogUtil from '../utils/LogUtil';
import { ContextAdapter } from './ContextAdapter';

import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'ContextPath';

@injectable()
export class ContextPathAdapter extends BaseAdapter {
  private ctxAdapter: ContextAdapter;

  constructor(@inject(ContextAdapter) ctxAdapter: ContextAdapter) {
    super();
    this.ctxAdapter = ctxAdapter;
  }

  @LogMethod
  getResourceDir(): string {
    return this.ctxAdapter.getActiveContext()?.resourceDir || "";
  }

  @LogMethod
  showSystemSettings(uri_value: string, subUri?: string): void {
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

  @LogMethod
  getPrivacyDownloadDir(callback: (uri_path: string) => void): void {
    let uri: string = '';
    let context = this.ctxAdapter.getActiveContext();
    if (context === undefined) {
      callback("");
      return;
    }
    const documentViewPicker = new picker.DocumentViewPicker(context);
    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
      uri = documentSaveResult[0];
      LogUtil.info (TAG, `Invoke documentViewPicker.save successfully, uri is ${uri}`);
      callback(uri.replace("file://docs", ""));
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, `Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
      callback("");
    })
  }
}
