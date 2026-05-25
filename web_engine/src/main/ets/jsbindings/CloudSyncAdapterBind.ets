/*
 * Copyright (c) 2023-2025 Haitai FangYuan Co., Ltd.
 */

import JsBindingUtils from '../utils/JsBindingUtils';
import Inject from "../common/InjectModule";
import lazy { CloudSyncAdapter } from '../adapter/CloudSyncAdapter';

function impl(): CloudSyncAdapter {
  return Inject.getOrCreate(CloudSyncAdapter);
}

function initCloudSync(context: Context, onCompleted: (ret: boolean) => void): void {
  impl().initCloudSync(context, onCompleted);
}

function setUserId(userId: string): void {
  impl().setUserId(userId);
}

function uploadFile(localPath: string, vaultName: string, filePath: string,
  onCompleted: (ret: boolean) => void): void {
  impl().uploadFile(localPath, vaultName, filePath, onCompleted);
}

function downloadFile(vaultName: string, filePath: string, localPath: string,
  onCompleted: (ret: boolean) => void): void {
  impl().downloadFile(vaultName, filePath, localPath, onCompleted);
}

function listCloudFiles(vaultName: string, onCompleted: (files: string[]) => void): void {
  impl().listCloudFiles(vaultName, onCompleted);
}

function deleteCloudFile(vaultName: string, filePath: string,
  onCompleted: (ret: boolean) => void): void {
  impl().deleteCloudFile(vaultName, filePath, onCompleted);
}

function getSyncStatus(onCompleted: (status: string) => void): void {
  impl().getSyncStatus(onCompleted);
}

function triggerLogin(context: Context, onCompleted: (result: string) => void): void {
  impl().triggerLogin(context, onCompleted);
}

export class CloudSyncAdapterBind {
  static bind(): void {
    JsBindingUtils.bindFunction("CloudSync.InitSync", initCloudSync);
    JsBindingUtils.bindFunction("CloudSync.SetUserId", setUserId);
    JsBindingUtils.bindFunction("CloudSync.UploadFile", uploadFile);
    JsBindingUtils.bindFunction("CloudSync.DownloadFile", downloadFile);
    JsBindingUtils.bindFunction("CloudSync.ListFiles", listCloudFiles);
    JsBindingUtils.bindFunction("CloudSync.DeleteFile", deleteCloudFile);
    JsBindingUtils.bindFunction("CloudSync.GetStatus", getSyncStatus);
    JsBindingUtils.bindFunction("CloudSync.TriggerLogin", triggerLogin);
  }
}
