import type {Mac2Driver} from '../driver.js';

declare module '../driver.js' {
  interface Mac2Driver {
    macosPerformAccessibilityAudit(
      ...args: Parameters<typeof macosPerformAccessibilityAudit>
    ): ReturnType<typeof macosPerformAccessibilityAudit>;
  }
}

export interface AccessibilityAuditItem {
  detailedDescription: string;
  compactDescription: string;
  auditType: string;
  element: string;
  elementDescription: string;
}

/**
 * Performs an accessibility audit for the current application.
 *
 * @param auditTypes - One or more audit type names.
 * If not provided, XCUIAccessibilityAuditTypeAll is used.
 * @returns The list of found issues (or an empty list).
 */
export async function macosPerformAccessibilityAudit(
  this: Mac2Driver,
  auditTypes?: string[],
): Promise<AccessibilityAuditItem[]> {
  return (await this.wda.proxy.command('/wda/performAccessibilityAudit', 'POST', {
    auditTypes,
  })) as AccessibilityAuditItem[];
}
