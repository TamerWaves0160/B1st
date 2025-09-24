// functions/src/embeddings-service.ts
import {GoogleAuth} from 'google-auth-library';
import * as logger from 'firebase-functions/logger';

interface EmbeddingResponse {
  predictions: {
    embeddings: {
      values: number[];
    };
  }[];
}

export class EmbeddingsService {
  private auth: GoogleAuth;
  private projectId: string;
  private location: string;

  constructor() {
    this.auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    this.projectId = 'behaviorfirst-515f1';
    this.location = 'us-central1';
  }

  /**
   * Generate embedding for a single text
   * @param text - The text to generate embedding for
   * @returns Promise<number[]> - The embedding vector
   */
  async generateEmbedding(text: string): Promise<number[]> {
    try {
      const authClient = await this.auth.getClient();
      const url = `https://${this.location}-aiplatform.googleapis.com/v1/projects/${this.projectId}/locations/${this.location}/publishers/google/models/text-embedding-004:predict`;

      const requestBody = {
        instances: [
          {
            content: text,
            task_type: 'SEMANTIC_SIMILARITY',
          },
        ],
      };

      logger.info('Generating embedding for text', {
        textPreview: text.substring(0, 50),
      });

      const response = await authClient.request({
        url,
        method: 'POST',
        data: requestBody,
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const embeddingData = response.data as EmbeddingResponse;

      logger.info('Vertex AI response received', {
        predictions: embeddingData.predictions?.length,
        fullResponse: JSON.stringify(embeddingData, null, 2),
      });

      if (!embeddingData.predictions || embeddingData.predictions.length === 0) {
        throw new Error('No predictions received from Vertex AI');
      }

      const embedding = embeddingData.predictions[0].embeddings.values;

      logger.info('Successfully generated embedding', {
        dimensions: embedding.length,
      });

      return embedding;
    } catch (error) {
      logger.error('Error generating embedding:', error);
      throw new Error(`Failed to generate embedding: ${error}`);
    }
  }

  /**
   * Generate embeddings for multiple texts in a batch
   * @param texts - Array of texts to generate embeddings for
   * @returns Promise<number[][]> - Array of embedding vectors
   */
  async generateEmbeddingsBatch(texts: string[]): Promise<number[][]> {
    try {
      const authClient = await this.auth.getClient();
      const url = `https://${this.location}-aiplatform.googleapis.com/v1/projects/${this.projectId}/locations/${this.location}/publishers/google/models/text-embedding-004:predict`;

      const instances = texts.map((text) => ({
        content: text,
        task_type: 'SEMANTIC_SIMILARITY',
      }));

      const requestBody = {
        instances,
      };

      logger.info('Generating embeddings for batch', {
        batchSize: texts.length,
        textPreviews: texts.map((t) => t.substring(0, 50)),
      });

      const response = await authClient.request({
        url,
        method: 'POST',
        data: requestBody,
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const embeddingData = response.data as EmbeddingResponse;

      logger.info('Vertex AI batch response received', {
        predictions: embeddingData.predictions?.length,
        requestedTexts: texts.length,
        fullResponse: JSON.stringify(embeddingData, null, 2),
      });

      if (!embeddingData.predictions || embeddingData.predictions.length !== texts.length) {
        throw new Error(`Expected ${texts.length} embeddings, got ${embeddingData.predictions?.length || 0}`);
      }

      const embeddings = embeddingData.predictions.map((prediction) => prediction.embeddings.values);

      logger.info('Successfully generated batch embeddings', {
        count: embeddings.length,
        dimensions: embeddings[0]?.length,
      });

      return embeddings;
    } catch (error) {
      logger.error('Error generating batch embeddings:', error);
      throw new Error(`Failed to generate batch embeddings: ${error}`);
    }
  }

  /**
   * Calculate cosine similarity between two embedding vectors
   * @param vecA - First embedding vector
   * @param vecB - Second embedding vector
   * @returns number - Similarity score between -1 and 1 (higher = more similar)
   */
  static cosineSimilarity(vecA: number[], vecB: number[]): number {
    if (vecA.length !== vecB.length) {
      throw new Error('Vectors must have the same length');
    }

    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    normA = Math.sqrt(normA);
    normB = Math.sqrt(normB);

    if (normA === 0 || normB === 0) {
      return 0;
    }

    return dotProduct / (normA * normB);
  }

  /**
   * Find the most similar interventions to a given behavior description
   * @param behaviorDescription - The behavior description to match
   * @param interventionEmbeddings - Array of intervention objects with embeddings
   * @param topK - Number of top similar interventions to return
   * @returns Array of interventions with similarity scores
   */
  static findSimilarInterventions(
      behaviorDescription: string,
      behaviorEmbedding: number[],
      interventionEmbeddings: Array<{id: string; name: string; embedding: number[]}>,
      topK = 3,
  ): Array<{id: string; name: string; similarity: number}> {
    const similarities = interventionEmbeddings.map((intervention) => ({
      id: intervention.id,
      name: intervention.name,
      similarity: this.cosineSimilarity(behaviorEmbedding, intervention.embedding),
    }));

    // Sort by similarity score (highest first) and return top K
    return similarities
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, topK);
  }

  /**
   * Create a comprehensive text representation of an intervention for embedding
   * @param intervention - Intervention object
   * @returns string - Text representation for embedding
   */
  static createInterventionText(intervention: any): string {
    const parts = [
      intervention.name,
      intervention.description,
      intervention.category,
      ...(intervention.behaviorFunction || []),
      ...(intervention.implementation || []).slice(0, 3), // First 3 implementation steps
    ];

    return parts.filter((part) => part && typeof part === 'string').join(' ');
  }
}
