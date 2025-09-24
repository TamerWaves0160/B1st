// functions/src/vertex-ai.ts
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import {getFirestore} from 'firebase-admin/firestore';
import {EmbeddingsService} from './embeddings-service';
import {LLMService} from './llm-service';

const db = getFirestore();

interface Intervention {
  id: string;
  name: string;
  category: 'attention' | 'escape' | 'sensory' | 'tangible' | 'social' | 'general';
  behaviorFunction: string[];
  description: string;
  implementation: string[];
  dataCollection: string[];
  evidenceLevel: 'high' | 'moderate' | 'emerging';
  ageGroups: string[];
  settings: string[];
  materials?: string[];
  frequency?: string;
  duration?: string;
}

// Enhanced intervention generation using Firestore intervention database
export const generateInterventions = onCall(
    {region: 'us-central1', timeoutSeconds: 60, cors: true},
    async (request) => {
      const uid = request.auth?.uid;
      if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

      const behaviorDescription = request.data?.behaviorDescription as string;
      const ageGroup = request.data?.ageGroup as string;
      const setting = request.data?.setting as string;

      if (!behaviorDescription?.trim()) {
        throw new HttpsError('invalid-argument', 'Behavior description required.');
      }

      logger.info('generateInterventions called', {
        uid,
        behaviorDescription: behaviorDescription.substring(0, 100),
        ageGroup,
        setting,
      });

      try {
        // Try embeddings-based approach first
        const embeddingsService = new EmbeddingsService();

        // Check if we have interventions with embeddings
        const interventionsSnapshot = await db.collection('interventions').get();
        const allInterventions: Intervention[] = [];

        interventionsSnapshot.forEach((doc) => {
          allInterventions.push({id: doc.id, ...doc.data()} as Intervention);
        });

        const interventionsWithEmbeddings = allInterventions.filter((i: any) => i.embedding);

        let analysis: {
          recommendedInterventions: Intervention[];
          behaviorAnalysis: string;
          rationale: string;
          method: string;
        };

        if (interventionsWithEmbeddings.length > 0) {
          // Use embeddings-based semantic matching
          const behaviorEmbedding = await embeddingsService.generateEmbedding(behaviorDescription);

          const similarInterventions = EmbeddingsService.findSimilarInterventions(
              behaviorDescription,
              behaviorEmbedding,
            interventionsWithEmbeddings as any[],
            5, // Top 5
          );

          analysis = {
            recommendedInterventions: similarInterventions.map((item: any) =>
              interventionsWithEmbeddings.find((i) => i.id === item.id),
            ).filter(Boolean) as any[],
            behaviorAnalysis: `Semantic analysis identified ${similarInterventions.length} interventions with similarity scores ranging from ${
              Math.round((similarInterventions[similarInterventions.length - 1]?.similarity || 0) * 100)
            }% to ${Math.round((similarInterventions[0]?.similarity || 0) * 100)}%.`,
            rationale: `Interventions selected using AI-powered semantic similarity matching from our evidence-based database. ${
              ageGroup ? `Filtered for ${ageGroup} age group. ` : ''
            }${
              setting ? `Appropriate for ${setting} setting. ` : ''
            }Higher similarity scores indicate better contextual matches.`,
            method: 'embeddings-semantic-analysis',
          };

          // Filter by age group and setting if provided
          if (ageGroup || setting) {
            analysis.recommendedInterventions = analysis.recommendedInterventions.filter((intervention) => {
              const ageMatch = !ageGroup || intervention.ageGroups.includes(ageGroup);
              const settingMatch = !setting || intervention.settings.includes(setting);
              return ageMatch && settingMatch;
            });
          }
        } else {
          // No embeddings available - this should not happen in production
          throw new HttpsError('failed-precondition', 'No interventions with embeddings found. Run generateInterventionEmbeddings first.');
        }

        const formattedInterventions = formatInterventionRecommendations(analysis);

        return {
          success: true,
          interventions: formattedInterventions,
          confidence: analysis.method === 'embeddings-semantic-analysis' ?
            'Generated using AI-powered semantic analysis with evidence-based intervention database' :
            'Generated using pattern analysis with evidence-based intervention database',
          method: analysis.method,
          behaviorAnalysis: analysis.behaviorAnalysis,
          rationale: analysis.rationale,
          recommendationCount: analysis.recommendedInterventions.length,
          embeddingsAvailable: interventionsWithEmbeddings.length > 0,
        };
      } catch (error) {
        logger.error('Error generating interventions:', error);
        throw new HttpsError('internal', 'Failed to generate interventions');
      }
    },
);

function formatInterventionRecommendations(analysis: {
  recommendedInterventions: any[];
  behaviorAnalysis: string;
  rationale: string;
}): string {
  const sections: string[] = [];

  // Add behavior analysis
  sections.push(`**BEHAVIOR ANALYSIS:**\n${analysis.behaviorAnalysis}\n`);

  // Format each intervention
  analysis.recommendedInterventions.forEach((intervention, index) => {
    sections.push(`**${index + 1}. ${intervention.name.toUpperCase()}**`);
    sections.push(`*Evidence Level: ${intervention.evidenceLevel.toUpperCase()}*`);
    sections.push(`\n${intervention.description}\n`);

    if (intervention.implementation && intervention.implementation.length > 0) {
      sections.push('**Implementation Steps:**');
      intervention.implementation.forEach((step: string) => {
        sections.push(`• ${step}`);
      });
      sections.push('');
    }

    if (intervention.dataCollection && intervention.dataCollection.length > 0) {
      sections.push('\n**Data Collection:**');
      intervention.dataCollection.forEach((data: string) => {
        sections.push(`• ${data}`);
      });
    }

    if (intervention.materials && intervention.materials.length > 0) {
      sections.push(`\n**Materials Needed:** ${intervention.materials.join(', ')}`);
    }

    if (intervention.frequency) {
      sections.push(`**Frequency:** ${intervention.frequency}`);
    }

    if (intervention.duration) {
      sections.push(`**Duration:** ${intervention.duration}`);
    }

    sections.push('\n---\n');
  });

  // Add rationale
  sections.push(`**SELECTION RATIONALE:**\n${analysis.rationale}`);

  return sections.join('\n');
}

/**
 * Generate comprehensive behavior analysis using both embeddings and LLM
 */
export const generateComprehensiveAnalysis = onCall(
    {region: 'us-central1', timeoutSeconds: 120, cors: true},
    async (request) => {
      // Immediately log the invocation
      logger.info('generateComprehensiveAnalysis invoked.', {
        auth: request.auth,
        data: request.data,
      });

      const uid = request.auth?.uid;
      if (!uid) {
        logger.error('Authentication failed: No UID provided.');
        throw new HttpsError('unauthenticated', 'Sign in required.');
      }

      const {
        behaviorDescription,
        studentInfo,
        ageGroup,
        setting,
        includeDetailedAnalysis = true,
      } = request.data;

      if (!behaviorDescription || typeof behaviorDescription !== 'string') {
        logger.error('Invalid argument: behaviorDescription is missing or not a string.', {
          requestData: request.data,
        });
        throw new HttpsError('invalid-argument', 'behaviorDescription is required');
      }

      try {
        logger.info('Starting comprehensive analysis process...');
        // Step 1: Use embeddings to find relevant interventions
        const embeddingsService = new EmbeddingsService();
        const llmService = new LLMService();

        // Get all interventions with embeddings
        logger.info('Fetching interventions from Firestore...');
        const interventionsSnapshot = await db.collection('interventions').get();
        const allInterventions = interventionsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as any[];
        logger.info(`Found ${allInterventions.length} total interventions.`);

        const interventionsWithEmbeddings = allInterventions.filter((intervention) =>
          intervention.embedding && Array.isArray(intervention.embedding),
        );

        if (interventionsWithEmbeddings.length === 0) {
          logger.error('Precondition Failed: No interventions with embeddings found.');
          throw new HttpsError('failed-precondition', 'No interventions with embeddings found. Run generateInterventionEmbeddings first.');
        }
        logger.info(`Found ${interventionsWithEmbeddings.length} interventions with embeddings.`);

        // Generate behavior embedding
        logger.info('Generating embedding for behavior description...');
        const behaviorEmbedding = await embeddingsService.generateEmbedding(behaviorDescription);

        // Find similar interventions
        logger.info('Finding similar interventions using embeddings...');
        const similarInterventions = EmbeddingsService.findSimilarInterventions(
            behaviorDescription,
            behaviorEmbedding,
            interventionsWithEmbeddings,
            5, // Top 5
        );
        logger.info(`Found ${similarInterventions.length} similar interventions.`);

        // Get full intervention details for LLM
        const recommendedInterventions = similarInterventions.map((match: any) => {
          const intervention = interventionsWithEmbeddings.find((i) => i.id === match.id);
          return {
            ...intervention,
            similarity: match.similarity,
          };
        }).filter(Boolean);

        let llmAnalysis = '';
        let behaviorFunction = '';

        if (includeDetailedAnalysis) {
          logger.info('Generating detailed analysis with LLM...');
          // Step 2: Generate comprehensive analysis using LLM
          llmAnalysis = await llmService.generateInterventionAnalysis(
              behaviorDescription,
              studentInfo,
              recommendedInterventions as any[],
          );

          // Step 3: Get quick behavior function analysis
          logger.info('Analyzing behavior function with LLM...');
          behaviorFunction = await llmService.analyzeBehaviorFunction(behaviorDescription);
          logger.info('LLM analysis complete.');
        }

        // Apply filters for age group and setting
        logger.info('Applying filters to recommended interventions...');
        let filteredInterventions = recommendedInterventions;
        if (ageGroup) {
          filteredInterventions = filteredInterventions.filter((intervention: any) =>
            intervention.ageGroups?.includes(ageGroup),
          );
        }
        if (setting) {
          filteredInterventions = filteredInterventions.filter((intervention: any) =>
            intervention.settings?.includes(setting),
          );
        }
        logger.info(`Filtered interventions count: ${filteredInterventions.length}`);

        const result = {
          success: true,
          behaviorDescription,
          studentInfo,
          behaviorFunction,
          recommendedInterventions: filteredInterventions.slice(0, 3), // Top 3 after filtering
          semanticMatches: similarInterventions,
          comprehensiveAnalysis: llmAnalysis,
          analysisMethod: 'embeddings-plus-llm',
          metadata: {
            totalInterventionsChecked: interventionsWithEmbeddings.length,
            semanticMatches: similarInterventions.length,
            finalRecommendations: filteredInterventions.length,
            filtersApplied: {
              ageGroup: ageGroup || null,
              setting: setting || null,
            },
          },
        };

        logger.info('Comprehensive analysis process completed successfully.', {
          recommendationCount: result.recommendedInterventions.length,
          analysisLength: llmAnalysis.length,
        });

        return result;
      } catch (error: any) {
        logger.error('FATAL Error in comprehensive analysis:', {
          errorMessage: error.message,
          errorStack: error.stack,
          errorDetails: error.details,
        });
        throw new HttpsError('internal', `Analysis failed: ${error.message}`);
      }
    },
);
