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
import Inject from '../common/InjectModule';
import lazy { PermissionManagerAdapter } from '../adapter/PermissionManagerAdapter';

function implPermissionManagerAdapter(): PermissionManagerAdapter {
  return Inject.getOrCreate(PermissionManagerAdapter);
}

function requestPermissions(permissionType: string, callback: (permissionGranted: number) => void) {
  implPermissionManagerAdapter().requestPermissions(permissionType, callback);
}

function checkPermissions(permissionType: string, callback: (permissionGranted: boolean) => void) {
  implPermissionManagerAdapter().checkPermissions(permissionType, callback);
}

function fileAccessPersist(uris: string[]) {
  implPermissionManagerAdapter().fileAccessPersist(uris);
}

function activateFileAccessPersist(uris: string[], callback: (code: number) => void) {
  implPermissionManagerAdapter().activateFileAccessPersist(uris, callback);
}

async function openPermissionConfirm(type: string, callback: (index: number) => void) {
  await implPermissionManagerAdapter().openPermissionConfirm(type, callback);
}

export class PermissionManagerAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction('PermissionManagerAdapter.RequestPermissionCode', requestPermissions);
    JsBindingUtils.bindFunction('PermissionManagerAdapter.CheckPermissions', checkPermissions);
    JsBindingUtils.bindFunction('PermissionManagerAdapter.FileAccessPersist', fileAccessPersist);
    JsBindingUtils.bindFunction('PermissionManagerAdapter.ActivateFileAccessPersist', activateFileAccessPersist);
    JsBindingUtils.bindFunction('PermissionManagerAdapter.OpenPermissionConfirm', openPermissionConfirm);
  }
}
