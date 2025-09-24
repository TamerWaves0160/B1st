// functions/src/check-embeddings.ts
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import {getFirestore} from 'firebase-admin/firestore';

const db = getFirestore();

/**
 * Check the status of embeddings in Firestore
 */
export const checkEmbeddingsStatus = onCall(
    {region: 'us-central1', cors: true},
    async (request) => {
      const uid = request.auth?.uid;
      if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
      logger.info('checkEmbeddingsStatus called', {uid});

      try {
        // Get all interventions
        const interventionsSnapshot = await db.collection('interventions').get();
        const interventions = interventionsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as any[];

        // Count interventions with embeddings
        const withEmbeddings = interventions.filter((intervention) =>
          intervention.embedding && Array.isArray(intervention.embedding),
        );

        // Get sample embedding info
        const sampleIntervention = withEmbeddings[0];
        const embeddingDimensions = sampleIntervention?.embedding?.length || 0;

        logger.info('Embeddings status checked', {
          total: interventions.length,
          withEmbeddings: withEmbeddings.length,
          dimensions: embeddingDimensions,
        });

        return {
          success: true,
          totalInterventions: interventions.length,
          withEmbeddings: withEmbeddings.length,
          embeddingDimensions,
          sampleIntervention: sampleIntervention ? {
            id: sampleIntervention.id,
            name: sampleIntervention.name,
            category: sampleIntervention.category,
          } : null,
          sampleEmbedding: sampleIntervention?.embedding?.slice(0, 10) || null, // First 10 values
          interventionsList: interventions.map((i) => ({
            id: i.id,
            name: i.name,
            hasEmbedding: !!(i.embedding && Array.isArray(i.embedding)),
            embeddingLength: i.embedding ? i.embedding.length : 0,
          })),
        };
      } catch (error) {
        logger.error('Error checking embeddings status:', error);
        throw new HttpsError('internal', 'Failed to check embeddings status');
      }
    },
);
