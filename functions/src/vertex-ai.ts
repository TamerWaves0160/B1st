import {VertexAI} from '@google-cloud/vertexai';
import {HttpsError} from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';

export class VertexAIService {
  private vertexAI: VertexAI;
  private textEmbeddingModel: any;
  private generativeModel: any;

  constructor() {
    this.vertexAI = new VertexAI({
      project: process.env.GCLOUD_PROJECT || '',
      location: 'us-central1',
    });

    this.textEmbeddingModel = this.vertexAI.getGenerativeModel({
      model: 'textembedding-gecko@003',
    });

    this.generativeModel = this.vertexAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
    });
  }

  async generateEmbedding(text: string): Promise<number[]> {
    try {
      const resp = await this.textEmbeddingModel.generateContent({
        contents: [{role: 'user', parts: [{text}]}],
      });

      if (
        !resp.response.candidates ||
        resp.response.candidates.length === 0 ||
        !resp.response.candidates[0].content.parts ||
        resp.response.candidates[0].content.parts.length === 0
      ) {
        throw new Error('Invalid embedding response from Vertex AI');
      }

      const embedding = resp.response.candidates[0].content.parts[0].embedding;
      if (!embedding || !embedding.values) {
        throw new Error('No embedding values found in the response');
      }

      return embedding.values;
    } catch (error: any) {
      logger.error('Error generating embedding:', {
        text: text.substring(0, 100),
        error: error.message,
        stack: error.stack,
      });
      throw new HttpsError('internal', 'Failed to generate text embedding.');
    }
  }

  async generateText(prompt: string): Promise<string> {
    try {
      const resp = await this.generativeModel.generateContent({
        contents: [{role: 'user', parts: [{text: prompt}]}],
      });

      if (
        !resp.response.candidates ||
        resp.response.candidates.length === 0 ||
        !resp.response.candidates[0].content.parts ||
        resp.response.candidates[0].content.parts.length === 0
      ) {
        throw new Error('Invalid response from generative model');
      }

      return resp.response.candidates[0].content.parts[0].text || '';
    } catch (error: any) {
      logger.error('Error generating text:', {
        prompt: prompt.substring(0, 100),
        error: error.message,
        stack: error.stack,
      });
      throw new HttpsError('internal', 'Failed to generate text from prompt.');
    }
  }
}
