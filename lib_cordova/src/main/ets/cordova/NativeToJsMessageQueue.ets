import { CordovaInterface } from './CordovaInterface';
import { CordovaWebViewProxy } from './CordovaWebViewProxy';
import { PluginResult, Status, MessageType } from './PluginResult';

export class NativeToJsMessageQueue {
  private static readonly FORCE_ENCODE_USING_EVAL = true;
  private static readonly COMBINED_RESPONSE_CUTOFF = 16 * 1024 * 1024;
  static DISABLE_EXEC_CHAINING = false;
  private paused: boolean = false;
  private queue: JsMessage[] = [];
  private bridgeModes: BridgeMode[] = [];
  private activeBridgeMode: BridgeMode | null = null;

  addBridgeMode(bridgeMode: BridgeMode): void {
    this.bridgeModes.push(bridgeMode);
  }

  isBridgeEnabled(): boolean {
    return this.activeBridgeMode !== null;
  }

  isEmpty(): boolean {
    return this.queue.length === 0;
  }

  setBridgeMode(value: number): void {
    if (value < -1 || value >= this.bridgeModes.length) {
      console.log("Invalid NativeToJsBridgeMode: " + value);
    } else {
      const newMode = value < 0 ? null : this.bridgeModes[value];
      if (newMode !== this.activeBridgeMode) {
        console.log("Set native->JS mode to " + (newMode ? newMode.constructor.name : "null"));
        this.activeBridgeMode = newMode;
        this.activeBridgeMode?.reset();
        if (!this.paused && !this.isEmpty()) {
          this.activeBridgeMode?.onNativeToJsMessageAvailable(this);
        }
      }
    }
  }

  reset(): void {
    this.queue = [];
    this.setBridgeMode(-1);
  }

  private calculatePackedMessageLength(message: JsMessage): number {
    const messageLen = message.calculateEncodedLength();
    const messageLenStr = String(messageLen);
    return messageLenStr.length + messageLen + 1;
  }

  private packMessage(message: JsMessage, sb: string[]): void {
    const len = message.calculateEncodedLength();
    sb.push(`${len} `);
    message.encodeAsMessage(sb);
  }

  popAndEncode(fromOnlineEvent: boolean): string | null {
    if (!this.activeBridgeMode) {
      return null;
    }
    this.activeBridgeMode.notifyOfFlush(this, fromOnlineEvent);
    if (this.queue.length === 0) {
      return null;
    }

    let totalPayloadLen = 0;
    let numMessagesToSend = 0;
    for (const message of this.queue) {
      const messageSize = this.calculatePackedMessageLength(message);
      if (numMessagesToSend > 0 && NativeToJsMessageQueue.COMBINED_RESPONSE_CUTOFF > 0 &&
        totalPayloadLen + messageSize > NativeToJsMessageQueue.COMBINED_RESPONSE_CUTOFF) {
        break;
      }
      totalPayloadLen += messageSize;
      numMessagesToSend++;
    }

    const sb: string[] = [];
    for (let i = 0; i < numMessagesToSend; ++i) {
      const message = this.queue.shift();
      if (message) {
        this.packMessage(message, sb);
      }
    }

    if (this.queue.length > 0) {
      sb.push('*');
    }
    return sb.join('');
  }

  popAndEncodeAsJs(): string | null {
    const length = this.queue.length;
    if (length === 0) {
      return null;
    }

    let totalPayloadLen = 0;
    let numMessagesToSend = 0;
    for (const message of this.queue) {
      const messageSize = message.calculateEncodedLength() + 50; // Overestimate
      if (numMessagesToSend > 0 && NativeToJsMessageQueue.COMBINED_RESPONSE_CUTOFF > 0 &&
        totalPayloadLen + messageSize > NativeToJsMessageQueue.COMBINED_RESPONSE_CUTOFF) {
        break;
      }
      totalPayloadLen += messageSize;
      numMessagesToSend++;
    }

    const willSendAllMessages = numMessagesToSend === this.queue.length;
    const sb: string[] = [];
    for (let i = 0; i < numMessagesToSend; ++i) {
      const message = this.queue.shift();
      if (message) {
        if (willSendAllMessages && (i + 1 === numMessagesToSend)) {
          message.encodeAsJsMessage(sb);
        } else {
          sb.push("try{");
          message.encodeAsJsMessage(sb);
          sb.push("}finally{");
        }
      }
    }

    if (!willSendAllMessages) {
      sb.push("window.setTimeout(function(){cordova.require('cordova/plugin/android/polling').pollOnce();},0);");
    }

    for (let i = willSendAllMessages ? 1 : 0; i < numMessagesToSend; ++i) {
      sb.push('}');
    }
    return sb.join('');
  }

  addJavaScript(statement: string): void {
    this.enqueueMessage(new JsMessage(statement));
  }

  addPluginResult(result: PluginResult, callbackId: string | null): void {
    if (!callbackId) {
      console.error("Got plugin result with no callbackId");
      return;
    }

    const noResult: boolean = result.getStatus() === Status.NO_RESULT;
    const keepCallback = result.getKeepCallback();
    if (noResult && keepCallback) {
      return;
    }

    let message = new JsMessage(result, callbackId);
    if (NativeToJsMessageQueue.FORCE_ENCODE_USING_EVAL) {
      const sb: string[] = [];
      message.encodeAsJsMessage(sb);
      message = new JsMessage(sb.join(''));
    }

    this.enqueueMessage(message);
  }

  private enqueueMessage(message: JsMessage): void {
    if (!this.activeBridgeMode) {
      console.log("Dropping Native->JS message due to disabled bridge");
      return;
    }

    this.queue.push(message);
    if (!this.paused) {
      this.activeBridgeMode.onNativeToJsMessageAvailable(this);
    }
  }

  setPaused(value: boolean): void {
    this.paused = value;
    if (!value) {
      if (!this.isEmpty() && this.activeBridgeMode) {
        this.activeBridgeMode.onNativeToJsMessageAvailable(this);
      }
    }
  }
}

abstract class BridgeMode {
  abstract onNativeToJsMessageAvailable(queue: NativeToJsMessageQueue): void;
  notifyOfFlush(queue: NativeToJsMessageQueue, fromOnlineEvent: boolean): void {};
  reset(): void {}
}

export class NoOpBridgeMode extends BridgeMode {
  onNativeToJsMessageAvailable(queue: NativeToJsMessageQueue): void {}
}

export class LoadUrlBridgeMode extends BridgeMode {
  private delegate: CordovaWebViewProxy;

  constructor(delegate: CordovaWebViewProxy) {
    super();
    this.delegate = delegate;
  }

  onNativeToJsMessageAvailable(queue: NativeToJsMessageQueue): void {
    let js = queue.popAndEncodeAsJs();
    if (js != null) {
      this.delegate.loadUrl(js);
    }
  }
}

export class OnlineEventsBridgeMode extends BridgeMode {
  private delegate: CordovaWebViewProxy;
  private online: boolean = false;
  private ignoreNextFlush: boolean = false;

  constructor(delegate: CordovaWebViewProxy) {
    super();
    this.delegate = delegate;
  }

  reset(): void {
    this.online = false;
    this.ignoreNextFlush = true;
    this.delegate.controller.setNetworkAvailable(true);
  }

  onNativeToJsMessageAvailable(queue: NativeToJsMessageQueue): void {
    if (!queue.isEmpty()) {
      this.ignoreNextFlush = false;
      this.delegate.controller.setNetworkAvailable(this.online);
    }
  }

  notifyOfFlush(queue: NativeToJsMessageQueue, fromOnlineEvent: boolean): void {
    if (fromOnlineEvent && !this.ignoreNextFlush) {
      this.online = !this.online;
    }
  }
}


export class EvalBridgeMode extends BridgeMode {
  private delegate: CordovaWebViewProxy;

  constructor(delegate: CordovaWebViewProxy) {
    super();
    this.delegate = delegate;
  }

  onNativeToJsMessageAvailable(queue: NativeToJsMessageQueue): void {
    let js = queue.popAndEncodeAsJs();
    if (js != null) {
      this.delegate.runJavaScript(js);
    }
  }
}

class JsMessage {
  private jsPayloadOrCallbackId: string;
  private pluginResult: PluginResult | null;

  constructor(js: string);
  constructor(pluginResult: PluginResult, callbackId: string);
  constructor(arg1: string | PluginResult, arg2?: string) {
    if (typeof arg1 === 'string') {
      this.jsPayloadOrCallbackId = arg1;
      this.pluginResult = null;
    } else if (typeof arg2 === 'string') {
      this.jsPayloadOrCallbackId = arg2;
      this.pluginResult = arg1;
    } else {
      throw new Error("Invalid constructor arguments for JsMessage");
    }
  }

  calculateEncodedLength(): number {
    if (!this.pluginResult) {
      return this.jsPayloadOrCallbackId.length + 1;
    }
    const statusLen = String(this.pluginResult.getStatus()).length;
    let ret = 2 + statusLen + 1 + this.jsPayloadOrCallbackId.length + 1;
    return ret + JsMessage.calculateEncodedLengthHelper(this.pluginResult);
  }

  static calculateEncodedLengthHelper(pluginResult: PluginResult): number {
    switch (pluginResult.getMessageType()) {
      case MessageType.BOOLEAN:
      case MessageType.NULL:
        return 1;
      case MessageType.NUMBER:
        return 1 + pluginResult.getMessage().length;
      case MessageType.STRING:
        return 1 + pluginResult.getStrMessage().length;
      case MessageType.BINARYSTRING:
        return 1 + pluginResult.getMessage().length;
      case MessageType.ARRAYBUFFER:
        return 1 + pluginResult.getMessage().length;
      case MessageType.MULTIPART:
        let ret = 1;
        for (let i = 0; i < pluginResult.getMultipartMessagesSize(); i++) {
          const length = JsMessage.calculateEncodedLengthHelper(pluginResult.getMultipartMessage(i));
          const argLength = String(length).length;
          ret += argLength + 1 + length;
        }
        return ret;
      case MessageType.JSON:
      default:
        return pluginResult.getMessage().length;
    }
  }

  encodeAsMessage(sb: string[]): void {
    if (!this.pluginResult) {
      sb.push('J');
      sb.push(this.jsPayloadOrCallbackId);
      return;
    }
    const status = this.pluginResult.getStatus();
    const noResult = status === Status.NO_RESULT;
    const resultOk = status === Status.OK;
    const keepCallback = this.pluginResult.getKeepCallback();

    sb.push((noResult || resultOk) ? 'S' : 'F');
    sb.push(keepCallback ? '1' : '0');
    sb.push(String(status));
    sb.push(' ');
    sb.push(this.jsPayloadOrCallbackId);
    sb.push(' ');

    JsMessage.encodeAsMessageHelper(sb, this.pluginResult);
  }

  static encodeAsMessageHelper(sb: Array<string | undefined | null>, pluginResult: PluginResult): void {
    switch (pluginResult.getMessageType()) {
      case MessageType.BOOLEAN:
        sb.push(pluginResult.getMessage()?.charAt(0));
        break;
      case MessageType.NULL:
        sb.push('N');
        break;
      case MessageType.NUMBER:
        sb.push('n');
        sb.push(pluginResult.getMessage());
        break;
      case MessageType.STRING:
        sb.push('s');
        sb.push(pluginResult.getStrMessage());
        break;
      case MessageType.BINARYSTRING:
        sb.push('S');
        sb.push(pluginResult.getMessage());
        break;
      case MessageType.ARRAYBUFFER:
        sb.push('A');
        sb.push(pluginResult.getMessage());
        break;
      case MessageType.MULTIPART:
        sb.push('M');
        for (let i = 0; i < pluginResult.getMultipartMessagesSize(); i++) {
          const multipartMessage = pluginResult.getMultipartMessage(i);
          sb.push(String(JsMessage.calculateEncodedLengthHelper(multipartMessage)));
          sb.push(' ');
          JsMessage.encodeAsMessageHelper(sb, multipartMessage);
        }
        break;
      case MessageType.JSON:
      default:
        sb.push(pluginResult.getMessage());
    }
  }

  buildJsMessage(sb: Array<string | undefined | null>): void {
    switch (this.pluginResult?.getMessageType()) {
      case MessageType.MULTIPART:
        const size = this.pluginResult.getMultipartMessagesSize();
        for (let i = 0; i < size; i++) {
          const subResult = this.pluginResult.getMultipartMessage(i);
          const subMessage = new JsMessage(subResult, this.jsPayloadOrCallbackId);
          subMessage.buildJsMessage(sb);
          if (i < (size - 1)) {
            sb.push(",");
          }
        }
        break;
      case MessageType.BINARYSTRING:
        sb.push("atob('");
        sb.push(this.pluginResult.getMessage());
        sb.push("')");
        break;
      case MessageType.ARRAYBUFFER:
        sb.push("cordova.require('cordova/base64').toArrayBuffer('");
        sb.push(this.pluginResult.getMessage());
        sb.push("')");
        break;
      case MessageType.NULL:
        sb.push("null");
        break;
      default:
        sb.push(this.pluginResult?.getMessage());
    }
  }

  encodeAsJsMessage(sb: string[]): void {
    if (!this.pluginResult) {
      sb.push(this.jsPayloadOrCallbackId);
    } else {
      const status = this.pluginResult.getStatus();
      const success = (status === Status.OK) || (status === Status.NO_RESULT);
      sb.push("cordova.callbackFromNative('");
      sb.push(this.jsPayloadOrCallbackId);
      sb.push("',");
      sb.push(success ? "true" : "false");
      sb.push(",");
      sb.push(String(status));
      sb.push(",[");
      this.buildJsMessage(sb);
      sb.push("],");
      sb.push(this.pluginResult.getKeepCallback() ? "true" : "false");
      sb.push(");");
    }
  }
}