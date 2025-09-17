// functions/src/index.ts
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import {initializeApp} from 'firebase-admin/app';
initializeApp();

// ---------- utils ----------
function isObject(x: unknown): x is Record<string, unknown> {
  return !!x && typeof x === 'object' && !Array.isArray(x);
}
function asNum(x: unknown): number {
  if (typeof x === 'number') return x;
  if (typeof x === 'string') {
    const t = Number(x);
    return Number.isFinite(t) ? t : 0;
  }
  return 0;
}
function numMap(x: unknown): Record<string, number> {
  const out: Record<string, number> = {};
  if (!isObject(x)) return out;
  for (const [k, v] of Object.entries(x)) out[k] = asNum(v);
  return out;
}
function recsFrom(x: unknown): Rec[] {
  if (!Array.isArray(x)) return [];
  return x
      .map((r) => (isObject(r) ? r : {}))
      .map((r) => ({
        title: typeof r.title === 'string' ? r.title : '',
        rationale: typeof r.rationale === 'string' ? r.rationale : '',
      }));
}

// ---------- types ----------
interface Dataset {
  studentName: string;
  studentId: string;
  from: string; // ISO
  to: string; // ISO
  totalEvents: number;
  totalDurationSeconds?: number;
  bySeverity?: Record<string, number>;
  byType?: Record<string, number>;
}
interface InsightFn { name: string; share: number; }
interface Insights {
  hypothesis?: string;
  rankedFunctions?: InsightFn[];
  severityShare?: Record<string, number>;
  antecedentCounts?: Record<string, number>;
  consequenceCounts?: Record<string, number>;
}
interface Rec { title: string; rationale: string; }
interface Plan {
  antecedent?: Rec[];
  teaching?: Rec[];
  consequence?: Rec[];
  reinforcement?: Rec[];
}

function isDataset(x: unknown): x is Dataset {
  if (!isObject(x)) return false;
  return (
    typeof x.studentName === 'string' &&
    typeof x.studentId === 'string' &&
    typeof x.from === 'string' &&
    typeof x.to === 'string' &&
    typeof x.totalEvents === 'number'
  );
}

// ---------- deterministic content helpers ----------
function recFromType(behavior: string): Rec[] {
  const b = behavior.toLowerCase();
  if (b.includes('aggression')) {
    return [
      {title: 'Increase supervision during transitions', rationale: 'Reduce opportunities for escalation.'},
      {title: 'Pre-correct and offer choices', rationale: 'Choices can reduce power struggles.'},
    ];
  }
  if (b.includes('noncompliance')) {
    return [
      {title: 'High-probability request sequence', rationale: 'Momentum improves compliance.'},
      {title: 'Clear, one-step directions', rationale: 'Reduces confusion and refusals.'},
    ];
  }
  if (b.includes('elopement')) {
    return [
      {title: 'Visual boundaries & seating plan', rationale: 'Environmental cues reduce leaving area.'},
      {title: 'Teach break card use', rationale: 'Replacement for leaving without permission.'},
    ];
  }
  if (b.includes('disruption')) {
    return [
      {title: 'Preferential seating', rationale: 'Minimizes peer attention and distraction.'},
      {title: 'Non-contingent attention', rationale: 'Satiates attention-seeking before disruption.'},
    ];
  }
  return [
    {title: 'Advance organizer', rationale: 'Clarifies expectations and reduces uncertainty.'},
    {title: 'Non-contingent reinforcement (time-based)', rationale: 'Reduces motivation for problem behavior.'},
  ];
}

function narrativeFrom(
    dataset: Dataset,
    top: { type: string; count: number }[],
    totalDur: number,
) {
  const msPerDay = 86_400_000;
  const days = Math.max(
      1,
      Math.ceil((new Date(dataset.to).getTime() - new Date(dataset.from).getTime()) / msPerDay),
  );
  const topText = top.map((t) => `${t.type} (${t.count})`).join(', ');
  const rate = (dataset.totalEvents / days).toFixed(1);

  const fbaSummary =
    `Over the ${days}-day window (${dataset.from} to ${dataset.to}), ${dataset.totalEvents} events were logged ` +
    `for ${dataset.studentName} (≈${rate}/day; total duration ${totalDur}s). The most frequent behaviors were ${topText}.`;

  const bipPlan =
    `Interventions will target the highest-frequency behaviors using antecedent supports (structure, pre-corrections), ` +
    `explicit teaching of replacements (e.g., hand-raise, break card), and consistent consequence strategies ` +
    `(behavior-specific praise, planned ignoring for minor attention-seeking).`;

  const interventionRationales =
    `Strategies are selected to compete with the presumed function(s) of behavior, increase access to reinforcement ` +
    `for appropriate responses, and reduce establishing operations that occasion problem behavior.`;

  return {fbaSummary, bipPlan, interventionRationales};
}

function mergeRec(incoming: Rec[] | undefined, seeds: Rec[]): Rec[] {
  const out: Rec[] = [];
  const seen = new Set<string>();
  for (const s of seeds) {
    const key = s.title.toLowerCase();
    if (!seen.has(key)) {
      out.push(s); seen.add(key);
    }
  }
  if (Array.isArray(incoming)) {
    for (const r of incoming) {
      const key = (r?.title ?? '').toLowerCase();
      if (!key) continue;
      if (!seen.has(key)) {
        out.push({title: r.title, rationale: r.rationale}); seen.add(key);
      }
    }
  }
  return out;
}

// ---------- STRICT callable (no fallback/demo) ----------
export const generateFbaBipDraft = onCall(
    {region: 'us-central1', timeoutSeconds: 120, cors: true /* , enforceAppCheck: true*/},
    async (request) => {
      const uid = request.auth?.uid;
      if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

      if (!isObject(request.data)) {
        throw new HttpsError('invalid-argument', 'Expected JSON object with { dataset, insights, plan }.');
      }

      const data = request.data as Record<string, unknown>;
      const meta = isObject(data._meta) ? (data._meta as Record<string, unknown>) : {};

      // NEW: read optional teacher options
      const mode = ((data['mode'] ?? 'BIP') + '').toUpperCase() as 'FBA' | 'BIP';
      const prompt = (data['prompt'] ?? '').toString();
      const teacherLine = prompt ? ` Teacher note: ${prompt}` : '';

      const dRaw = data['dataset'];
      const iRaw = data['insights'];
      const pRaw = data['plan'];

      const valid = {dataset: isDataset(dRaw), insights: isObject(iRaw), plan: isObject(pRaw)};
      if (!valid.dataset || !valid.insights || !valid.plan) {
        logger.warn('generateFbaBipDraft invalid payload', {uid, keys: Object.keys(data), valid, meta});
        throw new HttpsError('invalid-argument', 'Missing or malformed { dataset, insights, plan }.');
      }

      // Coerce numeric maps defensively
      const dataset = dRaw as Dataset;
      const insights = iRaw as Insights;
      const plan = pRaw as Plan;

      const byType = numMap((dataset as any).byType);
      const bySeverity = numMap((dataset as any).bySeverity);
      const severityShare = numMap((insights as any).severityShare);
      const antecedents = numMap((insights as any).antecedentCounts);
      const consequences = numMap((insights as any).consequenceCounts);

      const byTypeTop = Object.entries(byType)
          .map(([type, count]) => ({type, count: asNum(count)}))
          .sort((a, b) => b.count - a.count)
          .slice(0, 5);

      const topFunctions = Array.isArray(insights.rankedFunctions) ?
      insights.rankedFunctions
          .map((f) => ({name: String((f as any).name ?? ''), share: asNum((f as any).share)}))
          .slice(0, 2) :
      [];

      const narrativeBits = narrativeFrom(
          {...dataset, bySeverity, byType},
          byTypeTop,
          asNum(dataset.totalDurationSeconds ?? 0),
      );

      // NEW: bias narrative with mode/prompt
      const fbaSummary = mode === 'FBA' ? narrativeBits.fbaSummary + teacherLine : narrativeBits.fbaSummary;
      const bipPlan = mode === 'BIP' ? narrativeBits.bipPlan + teacherLine : narrativeBits.bipPlan;

      // Seed recommendations by top behavior
      const seedRecs = byTypeTop.length ? recFromType(byTypeTop[0].type) : recFromType('generic');

      const draft = {
        student: {
          id: dataset.studentId,
          name: dataset.studentName,
          window: {from: dataset.from, to: dataset.to},
        },
        summary: {
          totalEvents: dataset.totalEvents,
          totalDurationSeconds: asNum(dataset.totalDurationSeconds ?? 0),
          bySeverity,
          byTypeTop,
        },
        insights: {
          hypothesis: insights.hypothesis ?? '',
          topFunctions,
          severityShare,
          antecedents,
          consequences,
        },
        recommendations: {
          antecedent: mergeRec(recsFrom(plan.antecedent), seedRecs),
          teaching: mergeRec(recsFrom(plan.teaching), [
            {title: 'Teach explicit replacement behavior', rationale: 'Provide a functional alternative.'},
            {title: 'Rehearse with feedback', rationale: 'Build fluency and generalization.'},
          ]),
          consequence: mergeRec(recsFrom(plan.consequence), [
            {title: 'Behavior-specific praise for replacements', rationale: 'Increase appropriate behavior.'},
            {title: 'Planned ignoring for minor attention-seeking', rationale: 'Reduce reinforcement of problem behavior.'},
          ]),
          reinforcement: mergeRec(recsFrom(plan.reinforcement), [
            {title: 'Token economy with clear exchange rates', rationale: 'Sustain motivation across tasks.'},
            {title: 'Differential reinforcement (DRA/DRI)', rationale: 'Shift reinforcement to desired responses.'},
          ]),
        },
        narrative: {
          fbaSummary,
          bipPlan,
          interventionRationales: narrativeBits.interventionRationales,
          disclaimer: 'Draft for educational purposes; review with your team.',
        },
        meta: {
          generatedAt: new Date().toISOString(),
          engine: 'validated-live-2', // NEW
        },
      };

      logger.info('generateFbaBipDraft VALIDATED V2', {
        uid,
        student: dataset.studentName,
        totalEvents: dataset.totalEvents,
        engine: 'validated-live-2',
        meta,
      });

      return {meta: {...meta, serverReceivedAt: new Date().toISOString(), path: 'validated-v2'}, draft};
    },
);

// Email notification for data export requests
export const notifyDataRequest = onCall(
    {cors: true},
    async (request) => {
      const {userEmail, requestType, dataFormat, timeframe} = request.data;

      logger.info('📧 Data export request received:', {
        userEmail,
        requestType,
        dataFormat,
        timeframe,
        timestamp: new Date().toISOString(),
      });

      // TODO: Add email service integration (SendGrid, Mailgun, etc.)
      // For now, just log the notification
      const notificationData = {
        to: 'behaviorfirst@outlook.com',
        subject: '🔔 New Data Export Request - BehaviorFirst',
        body: `
New data export request received:

👤 User: ${userEmail}
📋 Request Type: ${requestType}
📄 Format: ${dataFormat}
📅 Timeframe: ${timeframe}
🕒 Submitted: ${new Date().toLocaleString()}

Please process this request within 24-48 hours.
Check Firebase Console: https://console.firebase.google.com/project/behaviorfirst-515f1/firestore/databases/-default-/data/~2Fdata_requests
        `,
      };

      logger.info('📬 Email notification data:', notificationData);

      return {
        success: true,
        message: 'Notification logged successfully',
        timestamp: new Date().toISOString(),
      };
    },
);

export {recommendInterventions} from './interventions';
