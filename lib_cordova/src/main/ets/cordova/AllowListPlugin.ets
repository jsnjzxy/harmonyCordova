import { CordovaPlugin } from './CordovaPlugin';
import { AllowList } from './AllowList';
import { ConfigXmlParserCustom } from './ConfigXmlParserCustom';

export class AllowListPlugin extends CordovaPlugin {
  static PLUGIN_NAME: string = 'CordovaAllowListPlugin';
  static TAG: string = 'CordovaAllowListPlugin';

  private allowedNavigations: AllowList;
  private allowedIntents: AllowList;
  private allowedRequests: AllowList;

  constructor(
    allowedNavigations?: AllowList,
    allowedIntents?: AllowList,
    allowedRequests?: AllowList,
  ) {
    super();
    this.allowedNavigations = allowedNavigations || new AllowList();
    this.allowedIntents = allowedIntents || new AllowList();
    this.allowedRequests = allowedRequests || new AllowList();
    this.allowedRequests.addAllowListEntry("resource:///*", false);
    this.allowedRequests.addAllowListEntry("data:*", false);
  }

  pluginInitialize(): void {
    new ConfigXmlParserCustom(this).parse(getContext(this));
  }

  shouldAllowNavigation(url: string): boolean {
    return this.allowedNavigations.isUrlAllowListed(url);
  }

  shouldAllowRequest(url: string): boolean {
    return this.shouldAllowNavigation(url) || this.allowedRequests.isUrlAllowListed(url);
  }

  shouldOpenExternalUrl(url: string): boolean {
    return this.allowedIntents.isUrlAllowListed(url);
  }

  getAllowedNavigations(): AllowList {
    return this.allowedNavigations;
  }

  setAllowedNavigations(allowedNavigations: AllowList): void {
    this.allowedNavigations = allowedNavigations;
  }

  getAllowedIntents(): AllowList {
    return this.allowedIntents;
  }

  setAllowedIntents(allowedIntents: AllowList): void {
    this.allowedIntents = allowedIntents;
  }

  getAllowedRequests(): AllowList {
    return this.allowedRequests;
  }

  setAllowedRequests(allowedRequests: AllowList): void {
    this.allowedRequests = allowedRequests;
  }
}