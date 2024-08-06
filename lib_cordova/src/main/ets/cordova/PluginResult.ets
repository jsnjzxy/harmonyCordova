import { util } from '@kit.ArkTS';

type PluginResultMessage = string | number | boolean | object | ArrayBuffer | null;

class PluginError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'PluginError';
  }
}

enum Status {
  NO_RESULT,
  OK,
  CLASS_NOT_FOUND_EXCEPTION,
  ILLEGAL_ACCESS_EXCEPTION,
  INSTANTIATION_EXCEPTION,
  MALFORMED_URL_EXCEPTION,
  IO_EXCEPTION,
  INVALID_ACTION,
  JSON_EXCEPTION,
  ERROR,
}

const StatusMessages = [
  "No result",
  "OK",
  "Class not found",
  "Illegal access",
  "Instantiation error",
  "Malformed url",
  "IO error",
  "Invalid action",
  "JSON error",
  "Error"
];

enum MessageType {
  STRING = 1,
  JSON = 2,
  NUMBER = 3,
  BOOLEAN = 4,
  NULL = 5,
  ARRAYBUFFER = 6,
  BINARYSTRING = 7,   // Use BINARYSTRING when your string may contain null characters.
  MULTIPART = 8,
}

class PluginResult {
  status: Status;
  private messageType: MessageType = MessageType.NULL;
  private keepCallback: boolean = false;
  private strMessage: string = '';
  private encodedMessage: string = '';
  private multipartMessages?: PluginResult[];

  constructor(status: Status, message?: PluginResultMessage) {
    this.status = status;
    if (typeof message === 'string') {
      this.messageType = MessageType.STRING;
      this.strMessage = message;
      this.encodedMessage = JSON.stringify(message);
    } else if (typeof message === 'boolean') {
      this.messageType = MessageType.BOOLEAN;
      this.encodedMessage = message.toString();
    } else if (typeof message === 'number') {
      this.messageType = MessageType.NUMBER;
      this.encodedMessage = message.toString();
    } else if (message instanceof ArrayBuffer) {
      this.messageType = MessageType.ARRAYBUFFER;
      let base64 = new util.Base64Helper();
      this.encodedMessage = base64.encodeToStringSync(new Uint8Array(message));
    } else if (typeof message === 'object' && message !== null) {
      this.messageType = MessageType.JSON;
      this.encodedMessage = JSON.stringify(message);
    } else if (message === null) {
      this.messageType = MessageType.NULL;
    } else if (Array.isArray(message)) {
      this.messageType = MessageType.MULTIPART;
      this.multipartMessages = message as PluginResult[];
    }
  }

  setKeepCallback(value: boolean): void {
    this.keepCallback = value;
  }

  getStatus(): number {
    return this.status;
  }

  getMessageType(): number {
    return this.messageType;
  }

  getMessage(): string {
    return this.encodedMessage;
  }

  getMultipartMessagesSize(): number {
    return this.multipartMessages ? this.multipartMessages.length : 0;
  }

  getMultipartMessage(index: number): PluginResult {
    if (!this.multipartMessages) {
      throw new PluginError("No multipart messages available.");
    }
    return this.multipartMessages[index];
  }

  getStrMessage(): string {
    return this.strMessage;
  }

  getKeepCallback(): boolean {
    return this.keepCallback;
  }

  getJSONString(): string {
    return `{"status":${this.status},"message":${this.getMessage()},"keepCallback":${this.keepCallback}}`;
  }
}

export { PluginResult, Status, MessageType, StatusMessages, PluginResultMessage };