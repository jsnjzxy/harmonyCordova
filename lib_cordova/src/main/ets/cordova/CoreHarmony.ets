import { CordovaPlugin } from './CordovaPlugin';
import { PluginResult, Status } from './PluginResult';
import { CallbackContext } from './CallbackContext';
import { CordovaArgs } from './CordovaArgs';
import { common } from '@kit.AbilityKit';

export class CoreHarmony extends CordovaPlugin {
  static PLUGIN_NAME: string = 'CoreHarmony';
  static TAG: string = 'CordovaApp';
  private messageChannel: CallbackContext | null = null;
  private pendingResume: PluginResult | null = null;
  private pendingPause: PluginResult | null = null;

  fireJavascriptEvent(action: string) {
    this.sendEventMessage(action);
  }

  execute(action: string, args: CordovaArgs, callbackContext: CallbackContext): boolean {
    let status = Status.OK;
    let result = '';

    try {
      if (action === 'clearCache') {

      } else if (action === 'show') {

      } else if (action === 'loadUrl') {

      } else if (action === 'cancelLoadUrl') {

      } else if (action === 'clearHistory') {
        this.controller.clearHistory();
      } else if (action === 'messageChannel') {
        this.messageChannel = callbackContext;
        if (this.pendingPause !== null) {
          this.sendEventMessage(this.pendingPause);
          this.pendingPause = null;
        }
        if (this.pendingResume !== null) {
          this.sendEventMessage(this.pendingResume);
          this.pendingResume = null;
        }
        return true;
      } else if (action === 'exitApp') {
        (getContext(this) as common.UIAbilityContext)?.terminateSelf();
      }

      callbackContext.sendPluginResult(new PluginResult(status, result));
      return true;
    } catch {
      callbackContext.sendPluginResult(new PluginResult(Status.JSON_EXCEPTION));
      return false;
    }
  }

  private sendEventMessage(message: PluginResult | string) {
    if (message instanceof PluginResult) {
      const payload = message;
      payload.setKeepCallback(true);
      if (this.messageChannel !== null) {
        this.messageChannel.sendPluginResult(payload);
      }
    } else {
      const action = message;
      let result = new PluginResult(Status.OK, {
        'action': action
      } as Record<string, string>);
      if (this.messageChannel == null) {
        if (action === 'pause') {
          this.pendingPause = result;
        } else if (action === 'resume') {
          this.pendingPause = null;
        }
      } else {
        this.sendEventMessage(result);
      }
    }
  }

  public sendResumeEvent(resumeEvent: PluginResult) {
    if (this.messageChannel !== null) {
      this.sendEventMessage(resumeEvent);
    } else {
      this.pendingResume = resumeEvent;
    }
  }
}