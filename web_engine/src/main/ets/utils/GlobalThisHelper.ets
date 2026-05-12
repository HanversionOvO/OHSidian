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

import LogUtil from '../utils/LogUtil';
import { GlobalContext } from '../utils/GlobalContext';
import Inject from '../common/InjectModule';
import { DependencyProvider } from '../interface/Dependency';

const TAG = 'GlobalThisHelper';
const INIT_ABILITY: string = 'init_ability';

export class GlobalThisHelper {
  private static global: GlobalContext = GlobalContext.getInstance();

  public static createValue<T extends Object>(key: string,
                                              value: T,
                                              forceChange: boolean = false) {
    if ((GlobalThisHelper.global.getObject(key) === undefined) || forceChange) {
      GlobalThisHelper.global.setObject(key, value);
      LogUtil.info(TAG, `GlobalThisHelper Create key of ${key}`);
    }
  }

  public static getValue<T extends Object>(key: string): T | undefined {
    if (GlobalThisHelper.global.getObject(key) === undefined) {
      LogUtil.error(TAG, `The storageKey is not exist, key = ${key}`);
      return undefined;
    }
    return ((GlobalThisHelper.global.getObject(key)) as T);
  }

  public static appInit(provider: DependencyProvider): void {
    Inject.inject(provider);
    GlobalThisHelper.global.setObject(INIT_ABILITY, true);
    LogUtil.info(TAG, `app init done`);
  }

  public static appUnInit(): void {
    Inject.destroy();
    LogUtil.info(TAG, `app UnInit done`);
  }

  public static isLaunched(): boolean {
    if (GlobalThisHelper.global.getObject(INIT_ABILITY) === undefined) {
      return false;
    }
    return GlobalThisHelper.global.getObject(INIT_ABILITY) as boolean;
  }
}
