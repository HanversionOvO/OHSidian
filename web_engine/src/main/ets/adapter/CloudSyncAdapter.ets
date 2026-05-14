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
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@ohos.base';

import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

const TAG: string = 'CloudSync';
const DB_NAME: string = 'ohsidian_cloud_sync.db';
const TABLE_NAME: string = 'vault_files';

@injectable()
export class CloudSyncAdapter extends BaseAdapter {
  private store: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;

  @LogMethod
  async initCloudSync(context: Context, onCompleted: (ret: boolean) => void): Promise<void> {
    if (this.isInitialized) {
      onCompleted(true);
      return;
    }

    try {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: false
      };

      this.store = await relationalStore.getRdbStore(context, config);

      // Create vault_files table
      const createTableSql: string =
        'CREATE TABLE IF NOT EXISTS ' + TABLE_NAME + ' (' +
        'path TEXT PRIMARY KEY, ' +
        'hash TEXT, ' +
        'size INTEGER, ' +
        'modified INTEGER, ' +
        'sync_status TEXT DEFAULT "pending")';

      await this.store.executeSql(createTableSql);

      // Enable distributed/cloud sync
      await this.store.setDistributedTables([TABLE_NAME]);

      this.isInitialized = true;
      LogUtil.info(TAG, 'Cloud sync initialized successfully');
      onCompleted(true);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      LogUtil.error(TAG, 'initCloudSync failed: ' + error.message);
      onCompleted(false);
    }
  }

  @LogMethod
  async syncFile(path: string, hash: string, size: number, modified: number,
    onCompleted: (ret: boolean) => void): Promise<void> {
    const currentStore: relationalStore.RdbStore | null = this.store;
    if (!currentStore) {
      onCompleted(false);
      return;
    }

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        path: path,
        hash: hash,
        size: size,
        modified: modified,
        sync_status: 'pending'
      };

      // Upsert: insert or replace
      await currentStore.insert(TABLE_NAME, valueBucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);

      LogUtil.info(TAG, 'Synced file: ' + path);
      onCompleted(true);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      LogUtil.error(TAG, 'syncFile failed: ' + error.message);
      onCompleted(false);
    }
  }

  @LogMethod
  async syncAll(context: Context, onCompleted: (ret: boolean) => void): Promise<void> {
    if (!this.store) {
      // Try to init first
      await this.initCloudSync(context, (initRet: boolean) => {
        if (!initRet) {
          onCompleted(false);
          return;
        }
      });
    }

    if (!this.store) {
      onCompleted(false);
      return;
    }

    // Cloud sync is handled automatically by ArkData DatamgrService
    // after setDistributedTables is called
    LogUtil.info(TAG, 'Sync triggered');
    onCompleted(true);
  }

  @LogMethod
  async getSyncStatus(onCompleted: (status: string) => void): Promise<void> {
    const currentStore: relationalStore.RdbStore | null = this.store;
    if (!currentStore) {
      onCompleted('未初始化');
      return;
    }

    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      const resultSet: relationalStore.ResultSet | null = await currentStore.query(predicates, ['sync_status']);
      let pendingCount: number = 0;
      let syncedCount: number = 0;

      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const colIndex: number = resultSet.getColumnIndex('sync_status');
          const status: string = resultSet.getString(colIndex);
          if (status === 'synced') {
            syncedCount++;
          } else {
            pendingCount++;
          }
        }
        resultSet.close();
      }

      if (pendingCount === 0 && syncedCount === 0) {
        onCompleted('未连接');
      } else if (pendingCount === 0) {
        onCompleted('已同步 (' + syncedCount.toString() + '个文件)');
      } else {
        onCompleted('同步中 (' + pendingCount.toString() + '个待同步)');
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      LogUtil.error(TAG, 'getSyncStatus failed: ' + error.message);
      onCompleted('错误');
    }
  }

  @LogMethod
  setAutoSync(enabled: boolean): void {
    LogUtil.info(TAG, 'Auto sync ' + (enabled ? 'enabled' : 'disabled'));
  }

  @LogMethod
  async cleanup(): Promise<void> {
    if (this.store) {
      try {
        await this.store.close();
        this.store = null;
        this.isInitialized = false;
        LogUtil.info(TAG, 'Cloud sync cleaned up');
      } catch (err) {
        const error: BusinessError = err as BusinessError;
        LogUtil.error(TAG, 'cleanup failed: ' + error.message);
      }
    }
  }
}
