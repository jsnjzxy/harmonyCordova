import { PluginResult, Status, PluginResultMessage } from './PluginResult';
import { CordovaWebViewProxy } from './CordovaWebViewProxy';

class CallbackContext {
  private callbackId: string;
  private proxy: CordovaWebViewProxy;
  private finished: boolean = false;
  private changingThreads: number = 0;

  constructor(callbackId: string, proxy: CordovaWebViewProxy) {
    this.callbackId = callbackId;
    this.proxy = proxy;
  }

  isFinished(): boolean {
    return this.finished;
  }

  isChangingThreads(): boolean {
    return this.changingThreads > 0;
  }

  getCallbackId(): string {
    return this.callbackId;
  }

  sendPluginResult(pluginResult: PluginResult): void {
    if (this.finished) {
      console.warn(`Attempted to send a second callback for ID: ${this.callbackId}\nResult was: ${pluginResult.getMessage()}`);
      return;
    } else {
      this.finished = !pluginResult.getKeepCallback();
    }

    this.proxy.sendPluginResult(pluginResult, this.callbackId);
  }

  success(message?: PluginResultMessage): void {
    this.sendPluginResult(new PluginResult(Status.OK, message));
  }

  error(message?: PluginResultMessage): void {
    this.sendPluginResult(new PluginResult(Status.ERROR, message));
  }
}

export { CallbackContext, PluginResult };