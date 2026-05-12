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
import lazy { CertManagerAdapter } from '../adapter/CertManagerAdapter';

function implCertManagerAdapter(): CertManagerAdapter {
  return Inject.getOrCreate(CertManagerAdapter);
}

function installPersonalCert(certData: ArrayBuffer, certPass: string, alias: string, callback: (ready: number) => void) {
  implCertManagerAdapter().installPersonalCert(certData, certPass, alias, callback);
}

function getAllPrivateCertificates(callback: Function): void {
  implCertManagerAdapter().getAllPrivateCertificates(callback);
}

function removeCertByUri(uri: string, callback: Function) {
  implCertManagerAdapter().removeCertByUri(uri, callback);
}

function signByCertUri(uri: string, inputData: ArrayBuffer, callback: Function): void {
  implCertManagerAdapter().signByCertUri(uri, inputData, callback);
}

function getCertCrl(pathDirPrefix:string, getUserIdFlag: boolean, callback: Function) {
  implCertManagerAdapter().getCertCrl(pathDirPrefix, getUserIdFlag, callback);
}

function returnUserId(callback: Function): void {
  implCertManagerAdapter().returnUserId(callback);
}

function showCertificateManagerDialog(): void {
  implCertManagerAdapter().showCertificateManagerDialog();
}

export class CertManagerAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction("CertManagerAdapter.InstallPersonalCert", installPersonalCert);
    JsBindingUtils.bindFunction("CertManagerAdapter.GetAllPrivateCertificates", getAllPrivateCertificates);
    JsBindingUtils.bindFunction("CertManagerAdapter.RemoveCertByUri", removeCertByUri);
    JsBindingUtils.bindFunction("CertManagerAdapter.SignByCertUri", signByCertUri);
    JsBindingUtils.bindFunction("CertManagerAdapter.GetCertCrl", getCertCrl);
    JsBindingUtils.bindFunction("CertManagerAdapter.ReturnUserId", returnUserId);
    JsBindingUtils.bindFunction("CertManagerAdapter.ShowCertificateManagerDialog", showCertificateManagerDialog);
  }
}
