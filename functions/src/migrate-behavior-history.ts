// functions/src/migrate-behavior-history.ts
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';

const db = getFirestore();

// Behavior type mapping to categorize behaviors
function categorizeBehavior(behaviorText: string): string {
  const lower = behaviorText.toLowerCase();
  if (lower.includes('out of seat') || lower.includes('walking')) return 'Out of Seat';
  if (lower.includes('call') || lower.includes('interrupt')) return 'Calling Out';
  if (lower.includes('refuse') || lower.includes('head down')) return 'Task Refusal';
  if (lower.includes('cried') || lower.includes('panic') || lower.includes('anxiety')) return 'Emotional Distress';
  if (lower.includes('argue') || lower.includes('profanity')) return 'Verbal Aggression';
  if (lower.includes('crawl') || lower.includes('hug') || lower.includes('touch')) return 'Sensory Seeking';
  if (lower.includes('erase') || lower.includes('perfectionism')) return 'Anxiety-Related';
  if (lower.includes('rip') || lower.includes('sick') || lower.includes('avoid')) return 'Task Avoidance';
  return 'Other';
}

function determineSeverity(behavior: string, duration: number): string {
  const lower = behavior.toLowerCase();
  if (lower.includes('profanity') || lower.includes('panic') || duration > 15) return 'Severe';
  if (lower.includes('refuse') || lower.includes('cried') || duration > 5) return 'Moderate';
  return 'Mild';
}

export const migrateBehaviorHistory = onCall(
    {region: 'us-central1', timeoutSeconds: 540},
    async (request) => {
      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      logger.info('Starting behavior history migration', {uid});

      try {
        // Get all students
        const studentsSnapshot = await db.collection('students').get();

        if (studentsSnapshot.empty) {
          return {
            success: false,
            message: 'No students found',
          };
        }

        let totalEvents = 0;
        let studentsProcessed = 0;

        for (const studentDoc of studentsSnapshot.docs) {
          const studentData = studentDoc.data();
          const studentId = studentDoc.id;
          const studentName = studentData.name || 'Unknown';
          const behaviorHistory = studentData.behaviorHistory || [];

          if (behaviorHistory.length === 0) {
            logger.info(`Skipping ${studentName}: No behavior history`);
            continue;
          }

          logger.info(`Processing ${studentName}: ${behaviorHistory.length} incidents`);

          // Update student document to add ownerUid if missing
          if (!studentData.ownerUid) {
            await db.collection('students').doc(studentId).update({
              ownerUid: uid,
              updatedAt: FieldValue.serverTimestamp(),
            });
          }

          // Create behavior_events from behaviorHistory
          const batch = db.batch();
          let eventCount = 0;

          for (const incident of behaviorHistory) {
            const behaviorType = categorizeBehavior(incident.behavior || '');
            const duration = incident.duration || 5;
            const severity = determineSeverity(incident.behavior || '', duration);
            const intensity = severity === 'Severe' ? 5 : severity === 'Moderate' ? 3 : 1;

            // Parse date
            let incidentDate = new Date();
            if (incident.date) {
              if (typeof incident.date === 'string') {
                incidentDate = new Date(incident.date);
              } else if (incident.date.toDate) {
                incidentDate = incident.date.toDate();
              }
            }

            const eventData = {
              uid: uid,
              studentId: studentId,
              studentName: studentName,
              behaviorType: behaviorType,
              severity: severity,
              intensity: intensity,
              durationSeconds: duration * 60,
              antecedent: incident.antecedent || 'Not specified',
              consequence: incident.consequence || 'Not specified',
              location: incident.setting || 'Classroom',
              createdAt: incidentDate,
              timestamp: incidentDate,
              notes: incident.behavior || '',
            };

            const docRef = db.collection('behavior_events').doc();
            batch.set(docRef, eventData);
            eventCount++;

            // Firebase batches can only handle 500 operations
            if (eventCount % 400 === 0) {
              await batch.commit();
            }
          }

          if (eventCount % 400 !== 0) {
            await batch.commit();
          }

          totalEvents += eventCount;
          studentsProcessed++;
        }

        logger.info('Migration complete', {studentsProcessed, totalEvents});

        return {
          success: true,
          studentsProcessed,
          totalEvents,
          message: `Successfully migrated ${totalEvents} behavior events from ${studentsProcessed} students`,
        };
      } catch (error) {
        logger.error('Migration failed', {error});
        throw new HttpsError('internal', 'Migration failed: ' + error);
      }
    },
);
