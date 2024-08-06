import { PluginManager } from './PluginManager';
import { NativeToJsMessageQueue } from './NativeToJsMessageQueue';

class SecureRandom {
  nextInt(max: number): number {
    return Math.floor(Math.random() * max);
  }
}

export class CordovaBridge {
  private static readonly LOG_TAG: string = "CordovaBridge";
  private pluginManager: PluginManager;
  private jsMessageQueue: NativeToJsMessageQueue;
  private expectedBridgeSecret: number = -1;

  constructor(pluginManager: PluginManager, jsMessageQueue: NativeToJsMessageQueue) {
    this.pluginManager = pluginManager;
    this.jsMessageQueue = jsMessageQueue;
  }

  jsExec(bridgeSecret: number, service: string, action: string, callbackId: string,
    args: string | null): string | null {
    if (!this.verifySecret("exec()", bridgeSecret)) {
      return null;
    }
    if (args === null) {
      return "@Null arguments.";
    }

    this.jsMessageQueue.setPaused(true);
    try {
      this.pluginManager.exec(service, action, callbackId, args);
      let ret: string | null = null;
      if (!NativeToJsMessageQueue.DISABLE_EXEC_CHAINING) {
        ret = this.jsMessageQueue.popAndEncode(false);
      }
      return ret;
    } catch (e) {
      console.error(e);
      return "";
    } finally {
      this.jsMessageQueue.setPaused(false);
    }
  }

  jsSetNativeToJsBridgeMode(bridgeSecret: number, value: number): void {
    if (!this.verifySecret("setNativeToJsBridgeMode()", bridgeSecret)) {
      return;
    }
    this.jsMessageQueue.setBridgeMode(value);
  }

  jsRetrieveJsMessages(bridgeSecret: number, fromOnlineEvent: boolean): string | null {
    if (!this.verifySecret("retrieveJsMessages()", bridgeSecret)) {
      return null;
    }
    return this.jsMessageQueue.popAndEncode(fromOnlineEvent);
  }

  private verifySecret(action: string, bridgeSecret: number): boolean {
    if (!this.jsMessageQueue.isBridgeEnabled()) {
      console.log(`${action} call made before bridge was enabled.`);
      return false;
    }
    if (this.expectedBridgeSecret < 0 || bridgeSecret !== this.expectedBridgeSecret) {
      console.error("Bridge access attempt with wrong secret token, possibly from malicious code. Disabling exec() bridge!");
      this.clearBridgeSecret();
      throw new Error("Illegal Access");
    }
    return true;
  }

  private clearBridgeSecret(): void {
    this.expectedBridgeSecret = -1;
  }

  isSecretEstablished(): boolean {
    return this.expectedBridgeSecret !== -1;
  }

  generateBridgeSecret(): number {
    let randGen = new SecureRandom();
    this.expectedBridgeSecret = randGen.nextInt(Number.MAX_SAFE_INTEGER);
    return this.expectedBridgeSecret;
  }

  reset(): void {
    this.jsMessageQueue.reset();
    this.clearBridgeSecret();
  }

  onJsPrompt(origin: string, message: string, defaultValue: string | null): string | null {
    if (defaultValue !== null && defaultValue.startsWith("gap:")) {
      try {
        const array = JSON.parse(defaultValue.substring(4)) as Array<number | string | null>;
        const bridgeSecret = array[0] as number;
        const service = array[1] as string;
        const action = array[2] as string;
        const callbackId = array[3] as string;
        const result = this.jsExec(bridgeSecret, service, action, callbackId, message);
        return result === null ? "" : result;
      } catch (e) {
        console.error(e);
      }
    } else if (defaultValue !== null && defaultValue.startsWith("gap_bridge_mode:")) {
      try {
        const bridgeSecret = parseInt(defaultValue.substring(16));
        const mode = parseInt(message);
        this.jsSetNativeToJsBridgeMode(bridgeSecret, mode);
      } catch (e) {
        console.error(e);
      }
    } else if (defaultValue !== null && defaultValue.startsWith("gap_poll:")) {
      try {
        const bridgeSecret = parseInt(defaultValue.substring(9));
        const fromOnlineEvent = message === "1";
        const result = this.jsRetrieveJsMessages(bridgeSecret, fromOnlineEvent);
        return result === null ? "" : result;
      } catch (e) {
        console.error(e);
      }
    } else if (defaultValue !== null && defaultValue.startsWith("gap_init:")) {
      if (this.pluginManager.shouldAllowBridgeAccess(origin)) {
        const bridgeMode = parseInt(defaultValue.substring(9));
        this.jsMessageQueue.setBridgeMode(bridgeMode);
        const secret = this.generateBridgeSecret();
        return secret.toString();
      } else {
        console.error(`${CordovaBridge.LOG_TAG}: "gap_init" called from restricted origin: ${origin}`);
      }
    }
    return null;
  }
}