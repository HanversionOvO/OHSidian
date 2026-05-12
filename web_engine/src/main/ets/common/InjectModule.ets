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

import common from '@ohos.app.ability.common';
import { Container, interfaces, ContainerModule } from 'inversify';
import { MODULE_TYPE } from "./ModuleType";
import { Dependency, DependencyProvider } from '../interface/Dependency';

export default class InjectModule {
  private static container = new Container({ defaultScope: "Singleton" });
  private static dependency: Dependency;
  private static isInject: boolean = false;

  static inject(provider: DependencyProvider) {
    if (InjectModule.isInject) {
      return;
    }

    try {
      InjectModule.dependency = provider.createDependency();
      InjectModule.container.bind<common.Context>(MODULE_TYPE.Context).toDynamicValue(
        () => {
          return InjectModule.dependency.getContext();
        });
      InjectModule.container.load(InjectModule.dependency.getCommonModule(),
                                  InjectModule.dependency.getAdapterModule());
      InjectModule.isInject = true;
    } catch(err) {
      throw new Error('inject Module failed: ' + JSON.stringify(err));
    }
  }

  static get<T>(serviceIdentifier: interfaces.ServiceIdentifier<T>): T {
    return InjectModule.container.get<T>(serviceIdentifier);
  }

  static getOrCreate<T>(serviceIdentifier: interfaces.ServiceIdentifier<T>): T {
    try {
      const module = InjectModule.container.get<T>(serviceIdentifier);
      if (module) {
        return module;
      }
    } catch (err) {
      const loadMode = new ContainerModule((bind:interfaces.Bind) => {
        bind(serviceIdentifier).toSelf()
      });
      InjectModule.container.load(loadMode);
      return InjectModule.container.get<T>(serviceIdentifier);
    } finally {
      return InjectModule.container.get<T>(serviceIdentifier);
    }
  }

  static destroy() {
    InjectModule.container.unbindAll();
  }
}
