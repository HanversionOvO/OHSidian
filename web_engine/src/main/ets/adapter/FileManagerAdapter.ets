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
import common from '@ohos.app.ability.common';
import fileUri from '@ohos.file.fileuri';
import { OpenLinkOptions, Want, wantConstant } from '@kit.AbilityKit';

import { BaseAdapter } from '../common/BaseAdapter';
import { ContextAdapter } from './ContextAdapter';
import LaunchHelper from '../utils/LaunchHelper';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

const TAG: string = 'FileManagerAdapter';

@injectable()
export class FileManagerAdapter extends BaseAdapter {
  private ctxAdapter: ContextAdapter;

  constructor(@inject(ContextAdapter) ctxAdapter: ContextAdapter) {
    super();
    this.ctxAdapter = ctxAdapter;
  }

  @LogMethod
  openItemInFolder(filePath: string) {
    let uri = fileUri.getUriFromPath(filePath);
    let link = 'filemanager://openDirectory';
    let openLinkOptions: OpenLinkOptions = {
      appLinkingOnly: false,
      parameters: {
        'fileUri': uri
      }
    };
    try {
      (this.ctxAdapter.getActiveContext() as common.UIAbilityContext).openLink(link, openLinkOptions);
    } catch (error) {
      LogUtil.error(TAG, `openItemInFolder openLink try to open uri ${uri} fail, err = ${JSON.stringify(error)}`);
    }
  }

  @LogMethod
  openVerifiedItem(filePath: string) {
    let uri = fileUri.getUriFromPath(filePath);
    const want: Want = {
      // Configure read and write permissions for shared files,
      // such as granting read and write authorization to shared applications
      flags: wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION |
             wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
      action: "ohos.want.action.viewData",
      uri: uri
    }
    LaunchHelper.Launch(this.ctxAdapter.getActiveContext(), want);
  }

  @LogMethod
  openUrlInDefaultBrowser(url: string) {
    let want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    LaunchHelper.Launch(this.ctxAdapter.getActiveContext(), want);
  }
}
