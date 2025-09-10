// functions/src/interventions.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

function quickTags(q: string): string[] {
  const s = q.toLowerCase();
  const picks = [
    "aggression","noncompliance","elopement","disruption","calling out",
    "transition","whole-group","unstructured","escape","attention","tangible","sensory"
  ];
  return picks.filter(t => s.includes(t));
}

export const recommendInterventions = onCall(
  { region: "us-central1", timeoutSeconds: 30, cors: true },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const query = (req.data?.query ?? "").toString().trim();
    const funcPref = (req.data?.function ?? "").toString().trim().toLowerCase();
    const topK = Math.max(1, Math.min(10, Number(req.data?.topK) || 5));

    if (!query) throw new HttpsError("invalid-argument", "Missing { query }.");

    logger.info("recommendInterventions invoked", { uid, query, funcPref, topK });

    const db = getFirestore();

    // Broad fetch; we score locally (simple & fast). You already seeded `interventions`.
    const snap = await db.collection("interventions").limit(80).get();

    const tags = quickTags(query);
    const qTokens = query.toLowerCase().split(/\W+/).filter(Boolean);

    const items = snap.docs
      .map((d) => {
        const it = d.data() as any;
        const itTags: string[] = (it.tags ?? []);
        let score = 0;
        if (funcPref && (it.function ?? "").toString().toLowerCase() === funcPref) score += 3;
        for (const t of tags) if (itTags.map((x) => x.toLowerCase()).includes(t)) score += 2;
        const title = (it.title ?? "").toString().toLowerCase();
        if (qTokens.some((tok) => title.includes(tok))) score += 1;
        return { id: d.id, ...it, _score: score };
      })
      .sort((a, b) => b._score - a._score)
      .slice(0, topK);

    return { items, meta: { topK, engine: "kb-basic-v1", tags, funcPref } };
  }
);
