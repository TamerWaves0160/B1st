// functions/src/generate-embeddings.ts
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';
import {EmbeddingsService} from './embeddings-service';

const db = getFirestore();

export const generateInterventionEmbeddings = onCall(
    {region: 'us-central1', timeoutSeconds: 300, cors: true},
    async (request) => {
      const uid = request.auth?.uid || 'system';
      // Require authentication for production use
      if (!request.auth?.uid) {
        throw new HttpsError('unauthenticated', 'Admin authentication required.');
      }
      logger.info('generateInterventionEmbeddings called', {uid});

      try {
        const embeddingsService = new EmbeddingsService();

        // Fetch all interventions from Firestore
        const interventionsSnapshot = await db.collection('interventions').get();
        const interventions = interventionsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

        // Prepare texts for batch embedding generation
        const interventionTexts = interventions.map((intervention) =>
          EmbeddingsService.createInterventionText(intervention),
        );

        // Generate embeddings in batch for efficiency
        const embeddings = await embeddingsService.generateEmbeddingsBatch(interventionTexts);

        // Update each intervention document with its embedding
        const batch = db.batch();
        let updateCount = 0;

        for (let i = 0; i < interventions.length; i++) {
          const intervention = interventions[i];
          const embedding = embeddings[i];

          const docRef = db.collection('interventions').doc(intervention.id);
          batch.update(docRef, {
            embedding: FieldValue.vector(embedding),
            embeddingText: interventionTexts[i],
            embeddingGeneratedAt: new Date(),
            updatedAt: new Date(),
          });

          updateCount++;
        }

        // Commit all updates
        await batch.commit();

        logger.info('Successfully generated and stored embeddings', {
          interventionsProcessed: updateCount,
          embeddingDimensions: embeddings[0]?.length,
        });

        return {
          success: true,
          message: 'Intervention embeddings generated successfully',
          interventionsProcessed: updateCount,
          embeddingDimensions: embeddings[0]?.length,
          sampleEmbedding: embeddings[0]?.slice(0, 5), // First 5 values for verification
        };
      } catch (error) {
        logger.error('Error generating intervention embeddings:', error);
        throw new HttpsError('internal', `Failed to generate embeddings: ${error}`);
      }
    },
);

export const testEmbeddingSimilarity = onCall(
    {region: 'us-central1', timeoutSeconds: 60, cors: true},
    async (request) => {
      const uid = request.auth?.uid;
      if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

      const testText = request.data?.text as string || 'Student gets out of seat frequently during lessons';

      logger.info('testEmbeddingSimilarity called', {uid, testText});

      try {
        const embeddingsService = new EmbeddingsService();

        // Generate embedding for test text
        const testEmbedding = await embeddingsService.generateEmbedding(testText);

        // Fetch all interventions with embeddings
        const interventionsSnapshot = await db.collection('interventions').get();
        const interventions = interventionsSnapshot.docs
            .map((doc) => ({
              id: doc.id,
              ...doc.data(),
            }))
            .filter((intervention: any) => intervention.embedding) as Array<{
            id: string;
            name: string;
            embedding: number[];
            [key: string]: any;
          }>; // Only those with embeddings

        if (interventions.length === 0) {
          throw new HttpsError('failed-precondition', 'No interventions with embeddings found. Run generateInterventionEmbeddings first.');
        }

        // Find similar interventions
        const similarInterventions = EmbeddingsService.findSimilarInterventions(
            testText,
            testEmbedding,
            interventions,
            5, // Top 5
        );

        // Format results for display
        const results = similarInterventions.map(({id, name, similarity}: any) => {
          const intervention = interventions.find((i) => i.id === id);
          return {
            id,
            name,
            category: intervention?.category,
            similarity: Math.round(similarity * 100) / 100, // Round to 2 decimal places
            description: intervention?.description?.substring(0, 100) + '...',
          };
        });

        return {
          success: true,
          testText,
          testEmbeddingDimensions: testEmbedding.length,
          results,
          totalInterventions: interventions.length,
        };
      } catch (error) {
        logger.error('Error testing embedding similarity:', error);
        throw new HttpsError('internal', `Failed to test similarity: ${error}`);
      }
    },
);
