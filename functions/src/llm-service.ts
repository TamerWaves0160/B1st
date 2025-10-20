// functions/src/llm-service.ts
import {logger} from 'firebase-functions/v2';
import {VertexAIService} from './vertex-ai';

interface Intervention {
  id: string;
  name: string;
  description: string;
  // Add other relevant fields if needed
}

export class LLMService {
  private vertexAIService: VertexAIService;

  constructor() {
    this.vertexAIService = new VertexAIService();
  }

  /**
   * Generates a conversational response based on retrieved interventions (RAG).
   * @param {string} behaviorDescription - The user's description of the behavior.
   * @param {Intervention[]} recommendedInterventions - The list of interventions retrieved from the database.
   * @returns {Promise<string>} A generated, conversational response.
   */
  async generateRAGResponse(
      behaviorDescription: string,
      recommendedInterventions: Intervention[],
  ): Promise<string> {
    try {
      const prompt = this.createRAGPrompt(
          behaviorDescription,
          recommendedInterventions,
      );

      logger.info('Generating RAG response from LLM', {
        behaviorPreview: behaviorDescription.substring(0, 50),
        interventionCount: recommendedInterventions.length,
      });

      const generatedText = await this.vertexAIService.generateText(prompt);

      logger.info('Successfully generated RAG response', {
        responseLength: generatedText.length,
      });

      return generatedText;
    } catch (error) {
      logger.error('Error generating RAG response:', error);
      throw new Error(`Failed to generate RAG response: ${error}`);
    }
  }

  /**
   * Creates the augmented prompt for the RAG model.
   * @param {string} behaviorDescription - The user's query.
   * @param {Intervention[]} recommendedInterventions - The retrieved context.
   * @returns {string} The fully-formed prompt.
   */
  private createRAGPrompt(
      behaviorDescription: string,
      recommendedInterventions: Intervention[],
  ): string {
    const interventionDetails = recommendedInterventions
        .map(
            (intervention) =>
              `### ${intervention.name}\n${intervention.description}`,
        )
        .join('\n\n');

    return `You are an expert behavioral specialist providing advice to a teacher.

The user is dealing with this situation:
"${behaviorDescription}"

Based ONLY on the following recommended interventions, provide a helpful and practical response. 

FORMAT YOUR RESPONSE AS FOLLOWS:
- Write in clear, conversational paragraphs
- Reference intervention strategies naturally within your explanation (e.g., "Consider implementing scheduled check-ins..." rather than quoting the intervention name)
- Focus on practical, actionable advice
- Do NOT use asterisks, bold text, or quote marks around intervention names
- Be encouraging and supportive in tone

Here are the interventions to draw from:
${interventionDetails}
`;
  }
}
