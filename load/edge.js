import http from 'k6/http';
import { check } from 'k6';
import { Counter, Trend } from 'k6/metrics';
import execution from 'k6/execution';

const count = Number(__ENV.REQUESTS || 10);
const duration = `${Number(__ENV.DURATION_SECONDS || 300)}s`;
const responses = new Counter('responses_by_instance');
const timings = new Trend('response_time_by_instance', true);

export const options = {
  insecureSkipTLSVerify: __ENV.INSECURE_TLS === 'true',
  discardResponseBodies: true,
  scenarios: {
    requests: {
      executor: 'constant-arrival-rate',
      rate: count,
      timeUnit: duration,
      duration,
      preAllocatedVUs: 20,
      maxVUs: 100,
      gracefulStop: '30s',
    },
  },
  thresholds: {
    http_req_failed: ['rate==0'],
    checks: ['rate==1'],
    dropped_iterations: ['count==0'],
    http_reqs: [`count==${count}`],
  },
};

export default function () {
  // Arrival-rate scheduling can start an extra iteration exactly at the boundary.
  if (execution.scenario.iterationInTest >= count) return;
  const response = http.get(`${__ENV.BASE_URL}${__ENV.TARGET_PATH}`, {
    redirects: 0,
    tags: { endpoint: __ENV.ENDPOINT, deployment: __ENV.DEPLOYMENT },
  });
  const tags = {
    instance: response.headers['X-App-Instance'] || response.headers['X-Static-Origin'] || 'unknown',
    status: String(response.status),
    endpoint: __ENV.ENDPOINT,
    deployment: __ENV.DEPLOYMENT,
  };
  responses.add(1, tags);
  timings.add(response.timings.duration, tags);
  check(response, { 'HTTP 200': (r) => r.status === 200 });
  if (__ENV.ENDPOINT === 'search' && __ENV.EXPECT_SEARCH === 'opensearch') {
    check(response, { 'OpenSearch handled search': (r) => r.headers['X-Search-Backend'] === 'opensearch' });
  }
}

export function handleSummary(data) {
  return { [__ENV.SUMMARY_PATH || '/results/summary.json']: JSON.stringify(data, null, 2) };
}
