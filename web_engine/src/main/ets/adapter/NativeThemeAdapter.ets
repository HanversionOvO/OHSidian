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
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { BaseAdapter } from '../common/BaseAdapter';
import common from '@ohos.app.ability.common';
import LogMethod from '../common/LogDecorator';
import { ContextAdapter } from './ContextAdapter';

@injectable()
export class NativeThemeAdapter extends BaseAdapter {
  private themeSource: ConfigurationConstant.ColorMode;
  private ctxAdapter: ContextAdapter;
  private hasInit: boolean = false;

  constructor(@inject(ContextAdapter) ctxAdapter: ContextAdapter) {
    super();
    this.ctxAdapter = ctxAdapter;
    this.themeSource = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    this.ctxAdapter.getContext()
      .getApplicationContext()
      .setColorMode(this.themeSource);
  }

  override init() {
    let activeContext = this.ctxAdapter.getActiveContext() as common.UIAbilityContext ||
                        this.ctxAdapter.getActiveContext() as common.UIExtensionContext;
    if (!activeContext) {
      return;
    }
    if (activeContext.config.colorMode !== undefined) {
      this.themeSource = activeContext.config.colorMode;
    }
  }

  @LogMethod
  getSystemNativeTheme(): ConfigurationConstant.ColorMode {
    if (!this.hasInit) {
      this.init();
      this.hasInit = true;
    }
    return this.themeSource;
  }

  setSystemNativeTheme(themeSource: ConfigurationConstant.ColorMode) {
    this.themeSource = themeSource;
    this.nativeContext.SetThemeSource(themeSource);
  }

  setAppColorMode(colorMode: ConfigurationConstant.ColorMode){
    this.ctxAdapter.getContext().getApplicationContext().setColorMode(colorMode);
  }
};
