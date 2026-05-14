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

import JsBindingUtils from '../utils/JsBindingUtils';
import Inject from "../common/InjectModule";
import lazy { CloudSyncAdapter } from '../adapter/CloudSyncAdapter';

function implCloudSyncAdapter(): CloudSyncAdapter {
  return Inject.getOrCreate(CloudSyncAdapter);
}

function initCloudSync(context: Context, onCompleted: (ret: boolean) => void): void {
  implCloudSyncAdapter().initCloudSync(context, onCompleted);
}

function syncFile(path: string, hash: string, size: number, modified: number,
  onCompleted: (ret: boolean) => void): void {
  implCloudSyncAdapter().syncFile(path, hash, size, modified, onCompleted);
}

function syncAll(context: Context, onCompleted: (ret: boolean) => void): void {
  implCloudSyncAdapter().syncAll(context, onCompleted);
}

function getSyncStatus(onCompleted: (status: string) => void): void {
  implCloudSyncAdapter().getSyncStatus(onCompleted);
}

function setAutoSync(enabled: boolean): void {
  implCloudSyncAdapter().setAutoSync(enabled);
}

export class CloudSyncAdapterBind {
  static bind(): void {
    JsBindingUtils.bindFunction("CloudSync.InitSync", initCloudSync);
    JsBindingUtils.bindFunction("CloudSync.SyncFile", syncFile);
    JsBindingUtils.bindFunction("CloudSync.SyncAll", syncAll);
    JsBindingUtils.bindFunction("CloudSync.GetStatus", getSyncStatus);
    JsBindingUtils.bindFunction("CloudSync.SetAutoSync", setAutoSync);
  }
}
