import { xml } from '@kit.ArkTS';

export class ConfigXmlParserBase {

  parse(context: Context): Uint8Array {
    let value = context.resourceManager.getRawFileContentSync('config.xml');
    if (value != null) {
      this.parseXml(value.buffer as ArrayBuffer);
    }
    return value;
  }

  protected parseXml(xmlContent: ArrayBuffer | DataView): void {
    const parser = new xml.XmlPullParser(xmlContent);

    let record = new Map<string, string>();
    const options: xml.ParseOptions = {
      tokenValueCallbackFunction: (eventType, value) => {
        const tagName = value.getName();
        if (eventType == xml.EventType.START_TAG) {
          this.handleStartTag(tagName, record);
        } else if (eventType == xml.EventType.END_TAG) {
          this.handleEndTag(tagName, record);
        }
        return true;
      },
      attributeValueCallbackFunction: (key, value) => {
        record.set(key, value);
        return true;
      }
    };

    parser.parse(options);
    this.onPostParse();
  }

  protected handleStartTag(tagName: string, record:Map<string, string>): void {

  }

  protected handleEndTag(tagName: string, record:Map<string, string>): void {

  }

  protected onPostParse(): void {

  }
}