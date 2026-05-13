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
import fileUri from '@ohos.file.fileuri';
import { fileManagerService } from '@kit.FileManagerServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

const TAG: string = 'TrashAdapter';
const DOCS_URI_PREFIX: string = 'file://docs';
const PUBLIC_STORAGE_PREFIX: string = '/storage/Users/currentUser';

@injectable()
export class TrashAdapter extends BaseAdapter {

  @LogMethod
  async trashItem(pathOrUri: string, callback?: (success: boolean) => void): Promise<boolean> {
    let success = false;
    try {
      let uris = this.getCandidateUris(pathOrUri);
      for (let uri of uris) {
        try {
          LogUtil.info(TAG, `trashItem: ${pathOrUri} -> uri: ${uri}`);
          let trashUri: string = await fileManagerService.deleteToTrash(uri);
          LogUtil.info(TAG, `deleteToTrash success, trashUri: ${trashUri}`);
          success = true;
          break;
        } catch (err) {
          let error = err as BusinessError;
          LogUtil.error(TAG, `deleteToTrash failed for uri ${uri}, errCode: ${error.code}, errMsg: ${error.message}`);
        }
      }
    } catch (err) {
      LogUtil.error(TAG, `trashItem exception: ${JSON.stringify(err)}`);
    } finally {
      if (callback) {
        callback(success);
      }
    }
    return success;
  }

  private getCandidateUris(pathOrUri: string): string[] {
    let uris = new Array<string>();
    this.addCandidateUri(uris, pathOrUri);
    if (!pathOrUri.startsWith('file://')) {
      if (pathOrUri.startsWith(PUBLIC_STORAGE_PREFIX)) {
        this.addCandidateUri(uris, DOCS_URI_PREFIX + pathOrUri);
      }
      try {
        this.addCandidateUri(uris, fileUri.getUriFromPath(pathOrUri));
      } catch (err) {
        LogUtil.error(TAG, `getUriFromPath failed for ${pathOrUri}: ${JSON.stringify(err)}`);
      }
    }
    return uris;
  }

  private addCandidateUri(uris: string[], uri: string): void {
    if (uri.length > 0 && !uris.includes(uri)) {
      uris.push(uri);
    }
  }
}
