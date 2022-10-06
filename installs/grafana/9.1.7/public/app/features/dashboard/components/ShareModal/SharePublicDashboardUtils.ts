import { getBackendSrv } from '@grafana/runtime';
import { notifyApp } from 'app/core/actions';
import { getConfig } from 'app/core/config';
import { createSuccessNotification } from 'app/core/copy/appNotification';
import { VariableModel } from 'app/features/variables/types';
import { dispatch } from 'app/store/store';
import { DashboardDataDTO, DashboardMeta } from 'app/types/dashboard';

export interface PublicDashboard {
  accessToken?: string;
  isEnabled: boolean;
  uid: string;
  dashboardUid: string;
  timeSettings?: object;
}

export interface DashboardResponse {
  dashboard: DashboardDataDTO;
  meta: DashboardMeta;
}

export const getPublicDashboardConfig = async (
  dashboardUid: string,
  setPublicDashboard: React.Dispatch<React.SetStateAction<PublicDashboard>>
) => {
  const url = `/api/dashboards/uid/${dashboardUid}/public-config`;
  const pdResp: PublicDashboard = await getBackendSrv().get(url);
  setPublicDashboard(pdResp);
};

export const savePublicDashboardConfig = async (
  dashboardUid: string,
  publicDashboardConfig: PublicDashboard,
  setPublicDashboard: React.Dispatch<React.SetStateAction<PublicDashboard>>
) => {
  const url = `/api/dashboards/uid/${dashboardUid}/public-config`;
  const pdResp: PublicDashboard = await getBackendSrv().post(url, publicDashboardConfig);

  // Never allow a user to send the orgId
  // @ts-ignore
  delete pdResp.orgId;

  dispatch(notifyApp(createSuccessNotification('Dashboard sharing configuration saved')));
  setPublicDashboard(pdResp);
};

// Instance methods
export const dashboardHasTemplateVariables = (variables: VariableModel[]): boolean => {
  return variables.length > 0;
};

export const publicDashboardPersisted = (publicDashboard: PublicDashboard): boolean => {
  return publicDashboard.uid !== '' && publicDashboard.uid !== undefined;
};

/**
 * Generate the public dashboard url. Uses the appUrl from the Grafana boot config, so urls will also be correct
 * when Grafana is hosted on a subpath.
 *
 * All app urls from the Grafana boot config end with a slash.
 *
 * @param publicDashboard
 */
export const generatePublicDashboardUrl = (publicDashboard: PublicDashboard): string => {
  return `${getConfig().appUrl}public-dashboards/${publicDashboard.accessToken}`;
};
