import { AllowListPlugin } from './AllowListPlugin';

import { ConfigXmlParserBase } from './ConfigXmlParserBase';

export class ConfigXmlParserCustom extends ConfigXmlParserBase {
private delegate: AllowListPlugin;

constructor(delegate: AllowListPlugin) {
  super();
  this.delegate = delegate;
}

  handleStartTag(tagName: string, record: Map<string, string>): void {
    record.clear();
  }

  handleEndTag(tagName: string, record: Map<string, string>): void {
    if (tagName === 'content') {
      const paramSrc = record.get('src') ?? '';
      this.delegate.getAllowedNavigations().addAllowListEntry(paramSrc, false);
      this.delegate.getAllowedNavigations().addAllowListEntry("resource://*/*", false);
    } else if (tagName === 'allow-navigation') {
      const paramOrigin = record.get('href') ?? '';
      if ('*' === paramOrigin) {
        this.delegate.getAllowedNavigations().addAllowListEntry("http://*/*", false);
        this.delegate.getAllowedNavigations().addAllowListEntry("https://*/*", false);
        this.delegate.getAllowedNavigations().addAllowListEntry("data:*", false);
      } else {
        this.delegate.getAllowedNavigations().addAllowListEntry(paramOrigin, false);
      }
    } else if (tagName === 'allow-intent') {
      const paramOrigin = record.get('href') ?? '';
      this.delegate.getAllowedIntents().addAllowListEntry(paramOrigin, false);
    } else if (tagName === 'access') {
      const paramOrigin = record.get('origin');
      if (paramOrigin != null) {
        if (paramOrigin === '*') {
          this.delegate.getAllowedRequests().addAllowListEntry("http://*/*", false);
          this.delegate.getAllowedRequests().addAllowListEntry("https://*/*", false);
        } else {
          const paramSubdomains = record.get('subdomains');
          this.delegate.getAllowedRequests().addAllowListEntry(paramOrigin, (paramSubdomains != null) && paramSubdomains.toLowerCase() === 'true')
        }
      }
    }
  }
}