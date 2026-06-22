export const ROUTE_INDEX: string = 'Index';
export const ROUTE_CHAT: string = 'ChatPage';

export const APP_CURRENT_ROUTE: string = 'chat_current_route';
export const APP_CURRENT_CONTACT_ID: string = 'chat_current_contact_id';
export const APP_CONTINUATION_TOKEN: string = 'chat_continuation_token';
export const APP_CONTINUATION_ROUTE: string = 'chat_continuation_route';
export const APP_CONTINUATION_CONTACT_ID: string = 'chat_continuation_contact_id';
export const APP_CONTINUATION_CONTACTS_JSON: string = 'chat_continuation_contacts_json';
export const APP_CONTINUATION_UPDATED_AT: string = 'chat_continuation_updated_at';

export const WANT_CONTINUATION_FLAG: string = 'chatContinuation';
export const WANT_CONTINUATION_ROUTE: string = 'chatContinuationRoute';
export const WANT_CONTINUATION_CONTACT_ID: string = 'chatContinuationContactId';
export const WANT_CONTINUATION_CONTACTS_JSON: string = 'chatContinuationContactsJson';
export const WANT_CONTINUATION_UPDATED_AT: string = 'chatContinuationUpdatedAt';

export const WANT_INLINE_DATA_LIMIT: number = 90 * 1024;

export function readStringParam(params: Record<string, Object> | undefined, key: string, fallback: string = ''): string {
  if (!params || params[key] === undefined || params[key] === null) {
    return fallback;
  }
  let value = params[key];
  if (typeof value === 'string') {
    return value;
  }
  return fallback;
}

export function readNumberParam(params: Record<string, Object> | undefined, key: string, fallback: number = -1): number {
  if (!params || params[key] === undefined || params[key] === null) {
    return fallback;
  }
  let value = params[key];
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    let parsed = Number(value);
    return isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}
