// functions/src/reindex-interventions.ts
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';

/**
 * Reindexes all interventions by rewriting them to trigger the vector index.
 * This is needed when a vector index is created after documents already exist.
 */
export const reindexInterventions = onCall(
    {region: 'us-central1', timeoutSeconds: 300, cors: true},
    async (request) => {
      // Require authentication
      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError('unauthenticated', 'Admin authentication required.');
      }

      logger.info('reindexInterventions called', {uid});

      try {
        const db = getFirestore();
        const interventionsRef = db.collection('interventions');

        // Get all interventions
        const snapshot = await interventionsRef.get();

        if (snapshot.empty) {
          logger.warn('No interventions found to reindex');
          return {
            success: false,
            message: 'No interventions found',
            count: 0,
          };
        }

        logger.info(`Found ${snapshot.size} interventions to reindex`);

        // Rewrite each document to trigger vector index
        const batch = db.batch();
        let count = 0;

        for (const doc of snapshot.docs) {
          const data = doc.data();

          // Only reindex if it has an embedding
          if (data.embedding && Array.isArray(data.embedding)) {
            // Rewrite the document with the embedding as a VectorValue
            batch.set(doc.ref, {
              ...data,
              embedding: FieldValue.vector(data.embedding),
              updatedAt: new Date(),
            });
            count++;
            logger.info(`Reindexing ${doc.id} with ${data.embedding.length}-dim embedding`);
          } else {
            logger.warn(`Skipping ${doc.id} - no embedding found`);
          }
        }

        // Commit the batch
        await batch.commit();

        logger.info(`Successfully reindexed ${count} interventions`);

        return {
          success: true,
          message: `Reindexed ${count} interventions with embeddings`,
          count: count,
          note: 'Vector index will update within 10-15 minutes',
        };
      } catch (error) {
        logger.error('Error reindexing interventions:', error);
        throw new HttpsError('internal', 'Failed to reindex interventions');
      }
    });
