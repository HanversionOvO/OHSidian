/*
 * Copyright (c) 2023-2025 Haitai FangYuan Co., Ltd.
 */

import { injectable } from 'inversify';
import { cloudStorage } from '@kit.CloudFoundationKit';
import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

interface ILoginInfo {
  status: boolean;
  authCode: string;
  unionId: string;
  openId: string;
  idToken: string;
  anonymousPhone: string;
}

interface ILogin {
  loginCallbackFunc: (loginInfo: ILoginInfo) => void;
}

const TAG: string = 'CloudSync';
const BUCKET_NAME: string = 'ohsidian-vault-sync-75ued';

/**
 * Cloud storage adapter using Huawei Cloud Foundation Kit.
 * Files are stored under: {userId}/vaults/{vaultName}/{relativePath}
 */
@injectable()
export class CloudSyncAdapter extends BaseAdapter {
  private bucket: cloudStorage.StorageBucket | null = null;
  private isInitialized: boolean = false;
  private userId: string = '';

  @LogMethod
  initCloudSync(context: Context, onCompleted: (ret: boolean) => void): void {
    if (this.isInitialized) {
      onCompleted(true);
      return;
    }

    try {
      this.bucket = cloudStorage.bucket(BUCKET_NAME);
      this.isInitialized = true;
      LogUtil.info(TAG, 'Cloud sync initialized with bucket: ' + BUCKET_NAME);
      onCompleted(true);
    } catch (err) {
      LogUtil.error(TAG, 'initCloudSync failed: ' + JSON.stringify(err));
      onCompleted(false);
    }
  }

  @LogMethod
  setUserId(userId: string): void {
    this.userId = userId;
    LogUtil.info(TAG, 'UserId set: ' + userId);
  }

  private buildCloudPath(vaultName: string, filePath: string): string {
    let cloudPath: string = this.userId + '/vaults/' + vaultName + '/' + filePath;
    // Clean up double slashes
    while (cloudPath.includes('//')) {
      cloudPath = cloudPath.replace('//', '/');
    }
    return cloudPath;
  }

  @LogMethod
  async uploadFile(localPath: string, vaultName: string, filePath: string,
    onCompleted: (ret: boolean) => void): Promise<void> {
    if (!this.bucket || !this.userId) {
      LogUtil.error(TAG, 'uploadFile: bucket or userId not ready');
      onCompleted(false);
      return;
    }

    const cloudPath: string = this.buildCloudPath(vaultName, filePath);

    try {
      const task: object = await this.bucket.uploadFile(getContext() as common.Context, {
        localPath: localPath,
        cloudPath: cloudPath
      });

      const taskObj: Record<string, Function> = task as Record<string, Function>;
      taskObj['on']('completed', (): void => {
        LogUtil.info(TAG, 'Upload completed: ' + cloudPath);
        onCompleted(true);
      });
      taskObj['on']('failed', (err: BusinessError): void => {
        LogUtil.error(TAG, 'Upload failed: ' + cloudPath + ', ' + JSON.stringify(err));
        onCompleted(false);
      });
      taskObj['start']((err: BusinessError): void => {
        if (err) {
          LogUtil.error(TAG, 'Upload start failed: ' + JSON.stringify(err));
          onCompleted(false);
        }
      });
    } catch (err) {
      LogUtil.error(TAG, 'uploadFile failed: ' + JSON.stringify(err));
      onCompleted(false);
    }
  }

  @LogMethod
  async downloadFile(vaultName: string, filePath: string, localPath: string,
    onCompleted: (ret: boolean) => void): Promise<void> {
    if (!this.bucket || !this.userId) {
      onCompleted(false);
      return;
    }

    const cloudPath: string = this.buildCloudPath(vaultName, filePath);

    try {
      const task: object = await this.bucket.downloadFile(getContext() as common.Context, {
        cloudPath: cloudPath,
        localPath: localPath
      });

      const taskObj: Record<string, Function> = task as Record<string, Function>;
      taskObj['on']('completed', (): void => {
        LogUtil.info(TAG, 'Download completed: ' + cloudPath);
        onCompleted(true);
      });
      taskObj['on']('failed', (err: BusinessError): void => {
        LogUtil.error(TAG, 'Download failed: ' + cloudPath + ', ' + JSON.stringify(err));
        onCompleted(false);
      });
      taskObj['start']((err: BusinessError): void => {
        if (err) {
          LogUtil.error(TAG, 'Download start failed: ' + JSON.stringify(err));
          onCompleted(false);
        }
      });
    } catch (err) {
      LogUtil.error(TAG, 'downloadFile failed: ' + JSON.stringify(err));
      onCompleted(false);
    }
  }

  @LogMethod
  async listCloudFiles(vaultName: string,
    onCompleted: (files: string[]) => void): Promise<void> {
    if (!this.bucket || !this.userId) {
      onCompleted([]);
      return;
    }

    const prefix: string = this.userId + '/vaults/' + vaultName + '/';

    try {
      const result: object = await this.bucket.list(prefix);
      const resultObj: Record<string, Object> = result as Record<string, Object>;
      const files: string[] = resultObj['files'] as string[];

      if (files) {
        // Strip prefix to get relative paths
        const relativeFiles: string[] = [];
        for (let i: number = 0; i < files.length; i++) {
          const f: string = files[i];
          if (f.startsWith(prefix)) {
            relativeFiles.push(f.substring(prefix.length));
          } else {
            relativeFiles.push(f);
          }
        }
        LogUtil.info(TAG, 'Listed ' + relativeFiles.length + ' files for vault: ' + vaultName);
        onCompleted(relativeFiles);
      } else {
        onCompleted([]);
      }
    } catch (err) {
      LogUtil.error(TAG, 'listCloudFiles failed: ' + JSON.stringify(err));
      onCompleted([]);
    }
  }

  @LogMethod
  async deleteCloudFile(vaultName: string, filePath: string,
    onCompleted: (ret: boolean) => void): Promise<void> {
    if (!this.bucket || !this.userId) {
      onCompleted(false);
      return;
    }

    const cloudPath: string = this.buildCloudPath(vaultName, filePath);

    try {
      await this.bucket.deleteFile(cloudPath);
      LogUtil.info(TAG, 'Deleted: ' + cloudPath);
      onCompleted(true);
    } catch (err) {
      LogUtil.error(TAG, 'deleteCloudFile failed: ' + JSON.stringify(err));
      onCompleted(false);
    }
  }

  @LogMethod
  async getSyncStatus(onCompleted: (status: string) => void): Promise<void> {
    if (!this.bucket) {
      onCompleted('未初始化');
      return;
    }
    if (!this.userId) {
      onCompleted('未登录华为账号');
      return;
    }

    try {
      const prefix: string = this.userId + '/vaults/';
      const result: object = await this.bucket.list(prefix);
      const resultObj: Record<string, Object> = result as Record<string, Object>;
      const files: string[] = resultObj['files'] as string[];

      if (files && files.length > 0) {
        onCompleted('已连接 (' + files.length.toString() + '个云端文件)');
      } else {
        onCompleted('云端无文件，请先同步');
      }
    } catch (err) {
      LogUtil.error(TAG, 'getSyncStatus failed: ' + JSON.stringify(err));
      onCompleted('未连接');
    }
  }

  @LogMethod
  setAutoSync(enabled: boolean): void {
    LogUtil.info(TAG, 'Auto sync ' + (enabled ? 'enabled' : 'disabled'));
  }

  /**
   * Trigger Huawei Account Kit one-click login.
   * Opens a dialog window with QuickLoginButtonComponent.
   */
  @LogMethod
  triggerLogin(context: common.Context, onCompleted: (result: string) => void): void {
    const activeContext: common.UIAbilityContext = context as common.UIAbilityContext;
    if (!activeContext) {
      LogUtil.error(TAG, 'triggerLogin: no active context');
      onCompleted('no_context');
      return;
    }

    try {
      const config: window.Configuration = {
        name: 'hcs-login',
        windowType: window.WindowType.TYPE_DIALOG,
        ctx: activeContext
      };

      window.createWindow(config, (err: BusinessError, data: window.Window): void => {
        if (err.code) {
          LogUtil.error(TAG, 'createWindow failed: ' + JSON.stringify(err));
          onCompleted('window_failed');
          return;
        }

        const windowClass: window.Window = data;
        const displayWidth: number = 400;
        const displayHeight: number = 500;

        windowClass.resize(displayWidth, displayHeight, (resizeErr: BusinessError): void => {
          if (resizeErr.code) {
            LogUtil.error(TAG, 'resize failed: ' + JSON.stringify(resizeErr));
          }
        });

        windowClass.showWindow((showErr: BusinessError): void => {
          if (showErr.code) {
            LogUtil.error(TAG, 'showWindow failed: ' + JSON.stringify(showErr));
          }
        });

        const loginCallback: (loginInfo: ILoginInfo) => void = (loginInfo: ILoginInfo): void => {
          if (loginInfo.status && loginInfo.openId) {
            this.userId = loginInfo.openId;
            LogUtil.info(TAG, 'Login success, userId: ' + this.userId);

            // Save userId to file for Electron to read
            const appContext: common.ApplicationContext = activeContext.getApplicationContext();
            const userFilePath: string = appContext.filesDir + '/hcs-user.json';
            try {
              const userData: string = JSON.stringify({
                userId: this.userId,
                unionId: loginInfo.unionId,
                loginTime: Date.now()
              });
              let f: fileIo.File = fileIo.openSync(userFilePath, fileIo.OpenMode.CREATE |
                fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);fileIo.writeSync(f.fd, userData);fileIo.closeSync(f);
            } catch (writeErr) {
              LogUtil.error(TAG, 'Failed to save userId: ' + JSON.stringify(writeErr));
            }

            // Close login window
            windowClass.destroyWindow((destroyErr: BusinessError): void => {
              if (destroyErr.code) {
                LogUtil.error(TAG, 'destroyWindow failed: ' + JSON.stringify(destroyErr));
              }
            });

            onCompleted(this.userId);
          } else {
            LogUtil.info(TAG, 'Login cancelled or failed');
            windowClass.destroyWindow((destroyErr: BusinessError): void => {
              // ignore
            });
            onCompleted('');
          }
        };

        const para: Record<string, ILogin> = {
          'login': {
            'loginCallbackFunc': loginCallback
          }
        };
        const storage: LocalStorage = new LocalStorage(para);

        windowClass.loadContent('pages/Login', storage, (loadErr: BusinessError): void => {
          if (loadErr.code) {
            LogUtil.error(TAG, 'loadContent failed: ' + JSON.stringify(loadErr));
            onCompleted('load_failed');
            return;
          }
          windowClass.setWindowBackgroundColor('#00000000');
        });
      });
    } catch (err) {
      LogUtil.error(TAG, 'triggerLogin failed: ' + JSON.stringify(err));
      onCompleted('error');
    }
  }

  /**
   * Check if Electron requested a login trigger.
   * Called periodically from WebAbility.
   */
  @LogMethod
  checkLoginTrigger(context: Context): void {
    const appContext: common.ApplicationContext = context.getApplicationContext();
    const triggerFile: string = appContext.filesDir + '/.hcs-login-pending';
    const userFile: string = appContext.filesDir + '/hcs-user.json';

    try {
      if (fileIo.accessSync(triggerFile)) {
        // Read the pending file
        const tf: fileIo.File = fileIo.openSync(triggerFile, fileIo.OpenMode.READ_ONLY);
        const stat: fileIo.Stat = fileIo.statSync(triggerFile);
        const buf: ArrayBuffer = new ArrayBuffer(stat.size);
        fileIo.readSync(tf.fd, buf);
        fileIo.closeSync(tf);
        const decoder: util.TextDecoder = new util.TextDecoder();
        const content: string = decoder.decodeWithStream(new Uint8Array(buf), undefined);
        const triggerTime: number = parseInt(content);
        // Only process if within 30 seconds
        if (Date.now() - triggerTime < 30000) {
          // Remove trigger file
          fileIo.unlinkSync(triggerFile);
          // Trigger login
          this.triggerLogin(context, (result: string): void => {
            LogUtil.info(TAG, 'checkLoginTrigger result: ' + (result || 'cancelled'));
          });
        } else {
          // Expired, remove
          fileIo.unlinkSync(triggerFile);
        }
      }
    } catch (err) {
      // File doesn't exist or can't be read - normal
    }
  }

  @LogMethod
  cleanup(): void {
    this.bucket = null;
    this.isInitialized = false;
    this.userId = '';
    LogUtil.info(TAG, 'Cloud sync cleaned up');
  }
}
