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
import { MODULE_TYPE } from "../common/ModuleType";
import { BaseAdapter } from '../common/BaseAdapter';
import { AbilityManager } from '../common/AbilityManager';
import LogMethod from '../common/LogDecorator';
import LogUtil from '../utils/LogUtil';
import { WebProxy, FakeWebProxy } from '../interface/WebProxy';

const TAG: string = 'ContextAdapter';

@injectable()
export class ContextAdapter extends BaseAdapter {
    private abilityManager: AbilityManager;
    private context: Context;
    private activeWindow: string = '';

    constructor(
        @inject(AbilityManager) abilityManager: AbilityManager,
        @inject(MODULE_TYPE.Context) ctx: Context
    ) {
        super();
        this.abilityManager = abilityManager;
        this.context = ctx;
    }

    public getContext(): Context {
        return this.context;
    }

    @LogMethod
    public setActiveWindow(activeWindow: string) {
        LogUtil.info(TAG, 'set current active window:' + activeWindow);
        this.activeWindow = activeWindow;
    }

    public getActiveContext(): Context | undefined {
        let activeProxy = this.abilityManager.getProxy(this.activeWindow);
        if (!activeProxy) {
            LogUtil.error(TAG, 'no active window context');
        }
        return activeProxy?.getWindowContext();
    }

    public getActiveProxy(): WebProxy {
        let activeProxy = this.abilityManager.getProxy(this.activeWindow);
        if (!activeProxy) {
            LogUtil.error(TAG, 'no active window');
            return new FakeWebProxy()
        }
        return activeProxy;
    }
}
