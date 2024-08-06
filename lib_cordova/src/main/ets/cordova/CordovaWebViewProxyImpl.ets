import { CordovaWebViewProxy } from './CordovaWebViewProxy';
import webview from '@ohos.web.webview';
import { CordovaBridge } from './CordovaBridge';
import { PluginManager } from './PluginManager';
import { CordovaPreferences } from './CordovaPreferences';
import { NativeToJsMessageQueue, NoOpBridgeMode, LoadUrlBridgeMode, OnlineEventsBridgeMode,
  EvalBridgeMode } from './NativeToJsMessageQueue';
import { PluginEntry } from './PluginEntry';
import { CordovaDialogsHelper } from './CordovaDialogsHelper';
import { ConfigXmlParser } from './ConfigXmlParser';
import { SystemExposedJsApi } from './engine/SystemExposedJsApi';
import { JavaScriptProxy } from './Entity';
import { CoreHarmony } from './CoreHarmony';
import { AbilityLifecycleCallback } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PluginResult } from './PluginResult';

let lifecycleId: number;

export class CordovaWebViewProxyImpl implements CordovaWebViewProxy {
  controller: webview.WebviewController;
  isInitialized: boolean = false;
  hasPausedEver: boolean = false;
  bridge: CordovaBridge;
  pluginManager: PluginManager;
  preferences: CordovaPreferences = new CordovaPreferences;
  nativeToJsMessageQueue: NativeToJsMessageQueue = new NativeToJsMessageQueue;
  private dialogsHelper: CordovaDialogsHelper = new CordovaDialogsHelper();
  parser: ConfigXmlParser = new ConfigXmlParser;
  exposedJsApi: SystemExposedJsApi;

  constructor(controller: webview.WebviewController, pluginEntries?: Array<PluginEntry>) {
    this.onLifeCycle();
    this.parser.parse(getContext(this));
    this.preferences = this.parser.getPreferences();

    this.controller = controller;

    if (!pluginEntries) {
      pluginEntries = [];
    }
    pluginEntries.push(...this.parser.getPluginEntries());
    this.pluginManager = new PluginManager(this, pluginEntries);
    this.pluginManager.addServiceEntry(new PluginEntry(CoreHarmony.PLUGIN_NAME, true, new CoreHarmony()));
    this.pluginManager.init();

    this.nativeToJsMessageQueue.addBridgeMode(new NoOpBridgeMode());
    this.nativeToJsMessageQueue.addBridgeMode(new LoadUrlBridgeMode(this));
    this.nativeToJsMessageQueue.addBridgeMode(new OnlineEventsBridgeMode(this));
    this.nativeToJsMessageQueue.addBridgeMode(new EvalBridgeMode(this));
    this.bridge = new CordovaBridge(this.pluginManager, this.nativeToJsMessageQueue);
    this.exposedJsApi = new SystemExposedJsApi(this.bridge);
  }

  onControllerAttached() {
    this.isInitialized = true;
  }

  destroy() {
    this.offLifeCycle();
  }

  sendPluginResult(cr: PluginResult, callbackId: string) {
    this.nativeToJsMessageQueue.addPluginResult(cr, callbackId);
  }

  loadUrl(url: string): void {
    this.controller.loadUrl(url);
  }

  runJavaScript(script: string): Promise<string> {
    return this.controller.runJavaScript(script);
  }

  refresh() {
    this.controller.refresh();
  }

  get javaScriptProxy(): JavaScriptProxy {
    return {
      name: '_cordovaNative',
      controller: this.controller,
      object: this.exposedJsApi,
      methodList: this.exposedJsApi.methodList,
    };
  }

  onJsAlert(event?: OnAlertEvent) {
    this.dialogsHelper.showAlert(event);
  }

  onJsConfirm(event?: OnConfirmEvent) {
    this.dialogsHelper.showConfirm(event);
  }

  onJsPrompt(event?: OnPromptEvent) {
    if (event) {
      let handleRet = this.bridge.onJsPrompt(event.url, event.message, event.value);
      if (handleRet != null) {
        event?.result.handlePromptConfirm(handleRet);
      } else {
        this.dialogsHelper.showPrompt(event);
      }
    }
  }

  onLifeCycle() {
    let callback: AbilityLifecycleCallback;
    this.handleResume()
    let AbilityLifecycleCallback: AbilityLifecycleCallback = {
      onAbilityCreate(ability) {
        console.log(`AbilityLifecycleCallback onAbilityCreate ability: ${ability}`);
      },
      onWindowStageCreate(ability, windowStage) {
        console.log(`AbilityLifecycleCallback onWindowStageCreate ability: ${ability}`);
        console.log(`AbilityLifecycleCallback onWindowStageCreate windowStage: ${windowStage}`);
      },
      onWindowStageActive(ability, windowStage) {
        console.log(`AbilityLifecycleCallback onWindowStageActive ability: ${ability}`);
        console.log(`AbilityLifecycleCallback onWindowStageActive windowStage: ${windowStage}`);
      },
      onWindowStageInactive(ability, windowStage) {
        console.log(`AbilityLifecycleCallback onWindowStageInactive ability: ${ability}`);
        console.log(`AbilityLifecycleCallback onWindowStageInactive windowStage: ${windowStage}`);
      },
      onWindowStageDestroy(ability, windowStage) {
        console.log(`AbilityLifecycleCallback onWindowStageDestroy ability: ${ability}`);
        console.log(`AbilityLifecycleCallback onWindowStageDestroy windowStage: ${windowStage}`);
      },
      onAbilityDestroy(ability) {
        console.log(`AbilityLifecycleCallback onAbilityDestroy ability: ${ability}`);
      },
      onAbilityForeground: (ability) => {
        this.handleResume();
        console.log(`AbilityLifecycleCallback onAbilityForeground ability: ${ability}`);
      },
      onAbilityBackground: (ability) => {
        this.handlePause();
        console.log(`AbilityLifecycleCallback onAbilityBackground ability: ${ability}`);
      },
      onAbilityContinue(ability) {
        console.log(`AbilityLifecycleCallback onAbilityContinue ability: ${ability}`);
      }
    }

    const applicationContext = getContext(this).getApplicationContext();
    try {
      lifecycleId = applicationContext.on('abilityLifecycle', AbilityLifecycleCallback);
    } catch (paramError) {
      console.error(`error: ${(paramError as BusinessError).code}, ${(paramError as BusinessError).message}`);
    }
  }

  offLifeCycle() {
    const applicationContext = getContext(this).getApplicationContext();
    try {
      applicationContext.off('abilityLifecycle', lifecycleId);
    } catch (paramError) {
      console.error(`error: ${(paramError as BusinessError).code}, ${(paramError as BusinessError).message}`);
    }
  }

  handlePause() {
    if (!this.isInitialized) {
      return;
    }
    this.hasPausedEver = true;
    this.pluginManager.onPause();
  }

  handleResume() {
    if (!this.isInitialized) {
      return;
    }
    this.pluginManager.onResume();
    if (this.hasPausedEver) {

    }
  }

  getWebViewController(): webview.WebviewController {
    return this.controller;
  }

  static createController(): CordovaWebViewProxyImpl {
    return new CordovaWebViewProxyImpl(new webview.WebviewController());
  }
}