// functions/src/llm-service.ts
import {GoogleAuth} from 'google-auth-library';
import {logger} from 'firebase-functions/v2';

interface InterventionRecommendation {
  id: string;
  name: string;
  category: string;
  description: string;
  implementation: string[];
  rationale: string;
  evidenceLevel: string;
  similarity: number;
}

export class LLMService {
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
   * Generate comprehensive behavior analysis and intervention recommendations
   * @param behaviorDescription - Description of the behavior
   * @param studentContext - Student information and context
   * @param recommendedInterventions - Interventions found through embeddings
   * @returns Promise<string> - Detailed analysis and recommendations
   */
  async generateInterventionAnalysis(
      behaviorDescription: string,
      studentContext: any,
      recommendedInterventions: any[],
  ): Promise<string> {
    try {
      const authClient = await this.auth.getClient();
      const url = `https://${this.location}-aiplatform.googleapis.com/v1/projects/${this.projectId}/locations/${this.location}/publishers/google/models/gemini-2.5-flash:generateContent`;

      const prompt = this.createAnalysisPrompt(
          behaviorDescription,
          studentContext,
          recommendedInterventions,
      );

      const requestBody = {
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: prompt,
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.7,
          topP: 0.8,
          topK: 40,
          maxOutputTokens: 2048,
        },
      };

      logger.info('Generating LLM analysis', {
        behaviorPreview: behaviorDescription.substring(0, 50),
        interventionCount: recommendedInterventions.length,
      });

      const response = await authClient.request({
        url,
        method: 'POST',
        data: requestBody,
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const llmData = response.data as any;

      if (!llmData.candidates || llmData.candidates.length === 0) {
        throw new Error('No response generated from LLM');
      }

      const generatedText = llmData.candidates[0].content.parts[0].text;

      logger.info('Successfully generated LLM analysis', {
        responseLength: generatedText.length,
      });

      return generatedText;
    } catch (error) {
      logger.error('Error generating LLM analysis:', error);
      throw new Error(`Failed to generate LLM analysis: ${error}`);
    }
  }

  /**
   * Create a structured prompt for behavior analysis
   * @param behaviorDescription - The behavior to analyze
   * @param studentContext - Student information
   * @param interventions - Recommended interventions from embeddings
   * @returns string - Formatted prompt
   */
  private createAnalysisPrompt(
      behaviorDescription: string,
      studentContext: any,
      interventions: InterventionRecommendation[],
  ): string {
    const studentInfo = studentContext ? `
Student Information:
- Name: ${studentContext.name || 'Not provided'}
- Age: ${studentContext.age || 'Not provided'}
- Grade: ${studentContext.grade || 'Not provided'}
- Diagnosis: ${studentContext.diagnosis || 'Not provided'}
- Current Strengths: ${studentContext.strengths?.join(', ') || 'Not provided'}
- Current Concerns: ${studentContext.behaviorConcerns?.join(', ') || 'Not provided'}` : '';

    const interventionsList = interventions.map((intervention, index) => `
${index + 1}. **${intervention.name}** (Similarity: ${Math.round(intervention.similarity * 100)}%)
   - Category: ${intervention.category}
   - Evidence Level: ${intervention.evidenceLevel}
   - Description: ${intervention.description}
   - Implementation Steps: ${intervention.implementation.join('; ')}`).join('\n');

    return `You are an expert behavioral analyst and special education consultant. Analyze the following behavior and provide comprehensive recommendations.

BEHAVIOR TO ANALYZE:
"${behaviorDescription}"
${studentInfo}

EVIDENCE-BASED INTERVENTIONS (Selected via AI semantic matching):
${interventionsList}

Please provide a comprehensive analysis in this format:

## BEHAVIOR ANALYSIS
**Function of Behavior:** [Identify the likely function - attention, escape, sensory, tangible]
**Contributing Factors:** [Environmental, academic, social, or medical factors]
**Patterns and Triggers:** [When, where, and why this behavior typically occurs]

## INTERVENTION RECOMMENDATIONS

### Primary Intervention
**Recommended Strategy:** [Select the most appropriate intervention from the list above]
**Why This Intervention:** [Explain the rationale based on behavior function and student needs]
**Implementation Steps:**
1. [Detailed step-by-step implementation]
2. [Include specific examples and modifications]
3. [Address potential challenges]

### Supporting Strategies
[Additional interventions that would complement the primary approach]

### Data Collection Plan
**What to Measure:** [Specific behaviors and outcomes to track]
**How to Measure:** [Methods and tools for data collection]
**Success Criteria:** [What success looks like]

## INDIVIDUALIZATION
**Student-Specific Considerations:** [How to adapt for this particular student]
**Environmental Modifications:** [Changes needed in the setting]
**Timeline:** [Expected implementation timeline and milestones]

## NEXT STEPS
[Specific action items for implementation]

Keep recommendations practical, evidence-based, and focused on positive behavior support principles.`;
  }

  /**
   * Generate a quick behavior function analysis
   * @param behaviorDescription - The behavior to analyze
   * @returns Promise<string> - Brief analysis of behavior function
   */
  async analyzeBehaviorFunction(behaviorDescription: string): Promise<string> {
    try {
      const authClient = await this.auth.getClient();
      const url = `https://${this.location}-aiplatform.googleapis.com/v1/projects/${this.projectId}/locations/${this.location}/publishers/google/models/gemini-2.5-flash:generateContent`;

      const prompt = `As a behavior analyst, quickly identify the most likely function of this behavior:

Behavior: "${behaviorDescription}"

Respond with one of these functions and a brief explanation:
- ATTENTION: Student seeks attention from adults or peers
- ESCAPE: Student wants to avoid or escape from demands/situations  
- SENSORY: Student seeks sensory input or stimulation
- TANGIBLE: Student wants access to preferred items/activities

Format: FUNCTION: [Brief explanation]`;

      const requestBody = {
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: prompt,
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 150,
        },
      };

      const response = await authClient.request({
        url,
        method: 'POST',
        data: requestBody,
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const llmData = response.data as any;
      // Gemini response format: candidates[0].content.parts[0].text
      return llmData.candidates?.[0]?.content?.parts?.[0]?.text || 'Unable to determine behavior function at this time.';
    } catch (error) {
      logger.error('Error analyzing behavior function:', error);
      return 'Unable to determine behavior function at this time.';
    }
  }
}
