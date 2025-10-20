// functions/src/intervention-database.ts
import {getFirestore} from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';

// Comprehensive Evidence-Based Behavioral Intervention Database

export interface Intervention {
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

/**
 * Finds the most similar documents in the 'interventions' collection in Firestore
 * based on a query embedding.
 * @param {number[]} queryEmbedding - The embedding vector of the user's query.
 * @param {number} limit - The maximum number of similar documents to return.
 * @returns {Promise<Intervention[]>} A promise that resolves to an array of the most similar interventions.
 */
export async function findSimilarDocuments(
    queryEmbedding: number[],
    limit: number,
): Promise<Intervention[]> {
  const db = getFirestore();
  const interventionsRef = db.collection('interventions');

  try {
    // First, check how many documents have embeddings
    const allDocs = await interventionsRef.get();
    const docsWithEmbeddings = allDocs.docs.filter((doc) => doc.data().embedding);
    logger.info(`Total interventions: ${allDocs.size}, with embeddings: ${docsWithEmbeddings.length}`);

    // Corrected call to findNearest with 3 arguments
    const vectorQuery = interventionsRef.findNearest('embedding', queryEmbedding, {
      limit: limit,
      distanceMeasure: 'COSINE',
    });

    const querySnapshot = await vectorQuery.get();

    if (querySnapshot.empty) {
      logger.warn('No similar interventions found via vector search.');
      logger.warn('This might indicate the vector index needs more time to sync after embedding generation.');
      logger.warn('Vector indexes can take 10-30 minutes to update after batch writes.');
      return [];
    }

    const similarInterventions = querySnapshot.docs.map((doc) => {
      return {id: doc.id, ...doc.data()} as Intervention;
    });

    logger.info(`Found ${similarInterventions.length} similar interventions.`);
    return similarInterventions;
  } catch (error) {
    logger.error('Error performing vector search:', error);
    throw new Error('Failed to find similar documents in the database.');
  }
}


export const INTERVENTION_DATABASE: Intervention[] = [
  // ATTENTION-SEEKING INTERVENTIONS
  {
    id: 'attention-001',
    name: 'Differential Attention',
    category: 'attention',
    behaviorFunction: ['attention-seeking', 'calling out', 'interrupting'],
    description: 'Provide attention for appropriate behaviors while withholding attention for inappropriate behaviors',
    implementation: [
      'Identify specific appropriate attention-seeking behaviors to reinforce',
      'Provide immediate, enthusiastic attention for appropriate behaviors',
      'Use planned ignoring for inappropriate attention-seeking (when safe)',
      'Redirect to appropriate attention-seeking when possible',
      'Ensure attention is given frequently for appropriate behavior',
    ],
    dataCollection: [
      'Frequency of appropriate vs inappropriate attention-seeking',
      'Duration of appropriate behaviors before attention provided',
      'Staff response consistency tracking',
    ],
    evidenceLevel: 'high',
    ageGroups: ['preschool', 'elementary', 'middle', 'high'],
    settings: ['classroom', 'home', 'community'],
    frequency: 'Continuous throughout day',
    duration: 'Ongoing intervention strategy',
  },
  {
    id: 'attention-002',
    name: 'Scheduled Attention',
    category: 'attention',
    behaviorFunction: ['attention-seeking', 'frequent requests'],
    description: 'Provide attention on a predictable schedule to reduce inappropriate attention-seeking',
    implementation: [
      'Set timer for regular attention intervals (every 5-15 minutes)',
      'Approach student and provide positive attention when timer goes off',
      'Gradually increase intervals between scheduled attention',
      'Pair with visual schedule showing when attention will be available',
      'Teach student to wait for scheduled times',
    ],
    dataCollection: [
      'Frequency of inappropriate attention-seeking between scheduled times',
      'Student ability to wait for scheduled attention',
      'Optimal interval length for individual student',
    ],
    evidenceLevel: 'high',
    ageGroups: ['preschool', 'elementary', 'middle'],
    settings: ['classroom', 'home'],
    materials: ['Timer', 'Visual schedule'],
    frequency: 'Every 5-15 minutes initially',
    duration: '2-4 weeks to establish pattern',
  },

  // ESCAPE/AVOIDANCE INTERVENTIONS
  {
    id: 'escape-001',
    name: 'Task Modification',
    category: 'escape',
    behaviorFunction: ['task avoidance', 'academic escape', 'demand avoidance'],
    description: 'Modify task demands to reduce escape-motivated behaviors while maintaining learning goals',
    implementation: [
      'Analyze current task demands and identify specific aspects student avoids',
      'Reduce task length or break into smaller components',
      'Provide choice in task order, materials, or response format',
      'Adjust difficulty level to ensure 80% success rate',
      'Use visual schedules to show task expectations clearly',
    ],
    dataCollection: [
      'Task completion rates before and after modification',
      'Time to task initiation',
      'Frequency of escape behaviors during modified vs original tasks',
    ],
    evidenceLevel: 'high',
    ageGroups: ['preschool', 'elementary', 'middle', 'high'],
    settings: ['classroom', 'home'],
    materials: ['Visual schedules', 'Choice boards', 'Modified materials'],
    frequency: 'Applied to all academic tasks initially',
    duration: 'Gradually fade modifications over 4-8 weeks',
  },
  {
    id: 'escape-002',
    name: 'High-Probability Request Sequence',
    category: 'escape',
    behaviorFunction: ['demand refusal', 'noncompliance'],
    description: 'Present several easy requests before difficult ones to build compliance momentum',
    implementation: [
      'Identify 3-5 requests student almost always complies with',
      'Present these high-probability requests in sequence',
      'Provide praise for compliance with each easy request',
      'Present target (difficult) request immediately after sequence',
      'Gradually reduce number of high-probability requests needed',
    ],
    dataCollection: [
      'Compliance rate with target requests after HP sequence',
      'Number of HP requests needed for success',
      'Generalization to requests without HP sequence',
    ],
    evidenceLevel: 'high',
    ageGroups: ['preschool', 'elementary', 'middle'],
    settings: ['classroom', 'home', 'therapy'],
    frequency: 'Before each difficult request initially',
    duration: '2-6 weeks depending on progress',
  },

  // SENSORY-SEEKING INTERVENTIONS
  {
    id: 'sensory-001',
    name: 'Sensory Breaks',
    category: 'sensory',
    behaviorFunction: ['movement seeking', 'sensory stimulation', 'fidgeting'],
    description: 'Provide scheduled sensory input to reduce inappropriate sensory-seeking behaviors',
    implementation: [
      'Identify preferred sensory activities (movement, touch, sound)',
      'Schedule regular sensory breaks every 15-30 minutes',
      'Create sensory break menu with 3-5 options',
      'Use timer and visual schedule to show when breaks are available',
      'Gradually increase time between scheduled breaks',
    ],
    dataCollection: [
      'Frequency of inappropriate sensory behaviors between breaks',
      'Engagement level during sensory breaks',
      'Optimal frequency and duration of breaks',
    ],
    evidenceLevel: 'moderate',
    ageGroups: ['preschool', 'elementary', 'middle'],
    settings: ['classroom', 'home'],
    materials: ['Sensory tools', 'Timer', 'Visual schedule', 'Designated sensory space'],
    frequency: 'Every 15-30 minutes initially',
    duration: 'Ongoing with gradual fading',
  },
  {
    id: 'sensory-002',
    name: 'Fidget Tools',
    category: 'sensory',
    behaviorFunction: ['tactile seeking', 'movement needs', 'focus enhancement'],
    description: 'Provide appropriate fidget tools to meet sensory needs while maintaining attention',
    implementation: [
      'Assess student preferences for different textures and movements',
      'Provide 2-3 fidget options that are quiet and non-disruptive',
      'Teach appropriate fidget use rules and expectations',
      'Rotate fidget options to maintain novelty',
      'Monitor that fidgets enhance rather than distract from learning',
    ],
    dataCollection: [
      'On-task behavior with vs without fidget tools',
      'Appropriate vs inappropriate use of fidgets',
      'Academic performance while using fidgets',
    ],
    evidenceLevel: 'moderate',
    ageGroups: ['elementary', 'middle', 'high'],
    settings: ['classroom', 'home', 'testing'],
    materials: ['Stress balls', 'Fidget cubes', 'Therapy putty', 'Textured strips'],
    frequency: 'Available throughout academic tasks',
    duration: 'Ongoing support tool',
  },

  // SOCIAL SKILL INTERVENTIONS
  {
    id: 'social-001',
    name: 'Social Scripts',
    category: 'social',
    behaviorFunction: ['peer interaction difficulties', 'social communication'],
    description: 'Teach specific language and behaviors for common social situations',
    implementation: [
      'Identify specific social situations where student struggles',
      'Develop simple, clear scripts for appropriate responses',
      'Practice scripts through role-play in safe environment',
      'Use visual cues or cards to prompt script use',
      'Gradually fade prompts as skills become more natural',
    ],
    dataCollection: [
      'Frequency of appropriate social initiations',
      'Use of taught scripts in natural settings',
      'Peer response to student social attempts',
    ],
    evidenceLevel: 'moderate',
    ageGroups: ['preschool', 'elementary', 'middle', 'high'],
    settings: ['classroom', 'playground', 'community'],
    materials: ['Social script cards', 'Visual prompts'],
    frequency: 'Practice 2-3 times daily, use as needed',
    duration: '4-8 weeks for acquisition, ongoing practice',
  },

  // TANGIBLE/ACCESS INTERVENTIONS
  {
    id: 'tangible-001',
    name: 'Token Economy',
    category: 'tangible',
    behaviorFunction: ['motivation', 'behavioral momentum', 'access to preferred items'],
    description: 'Systematic reinforcement program using tokens that can be exchanged for preferred items/activities',
    implementation: [
      'Identify highly preferred items/activities through preference assessment',
      'Establish clear behavioral expectations for earning tokens',
      'Create simple token board or chart',
      'Provide tokens immediately following target behaviors',
      'Allow regular opportunities to exchange tokens for rewards',
      'Gradually increase behavioral requirements for tokens',
    ],
    dataCollection: [
      'Frequency of target behaviors',
      'Tokens earned per day/session',
      'Student engagement with token system',
      'Generalization of behaviors without tokens',
    ],
    evidenceLevel: 'high',
    ageGroups: ['preschool', 'elementary', 'middle'],
    settings: ['classroom', 'home', 'therapy'],
    materials: ['Token board', 'Tokens/stickers', 'Preferred items menu'],
    frequency: 'Tokens delivered immediately, exchange 1-3 times daily',
    duration: '4-12 weeks with gradual fading',
  },

  // GENERAL POSITIVE BEHAVIOR SUPPORT
  {
    id: 'general-001',
    name: 'Environmental Modification',
    category: 'general',
    behaviorFunction: ['antecedent intervention', 'prevention'],
    description: 'Modify physical and social environment to prevent problem behaviors and promote success',
    implementation: [
      'Analyze current environment for behavioral triggers',
      'Modify physical space to reduce distractions or access to inappropriate items',
      'Adjust lighting, noise levels, and seating arrangements',
      'Create clear visual boundaries and organization systems',
      'Establish predictable routines and expectations',
    ],
    dataCollection: [
      'Frequency of problem behaviors before and after modifications',
      'Student engagement and on-task behavior',
      'Need for additional interventions',
    ],
    evidenceLevel: 'high',
    ageGroups: ['preschool', 'elementary', 'middle', 'high'],
    settings: ['classroom', 'home', 'community'],
    materials: ['Room dividers', 'Visual schedules', 'Organization systems'],
    frequency: 'Continuous environmental support',
    duration: 'Ongoing with periodic review and adjustment',
  },
  {
    id: 'general-002',
    name: 'Choice Making',
    category: 'general',
    behaviorFunction: ['self-determination', 'engagement', 'compliance'],
    description: 'Provide structured choices to increase student engagement and reduce behavioral challenges',
    implementation: [
      'Identify opportunities for meaningful choices throughout the day',
      'Create choice boards with 2-4 options',
      'Teach choice-making process explicitly',
      'Honor student choices when possible and safe',
      'Gradually expand choice opportunities',
      'Use "first/then" choices for less preferred activities',
    ],
    dataCollection: [
      'Student engagement when choices are available vs not available',
      'Frequency of problem behaviors during choice vs no-choice conditions',
      'Types of choices most motivating for individual student',
    ],
    evidenceLevel: 'high',
    ageGroups: ['preschool', 'elementary', 'middle', 'high'],
    settings: ['classroom', 'home', 'community'],
    materials: ['Choice boards', 'Visual choice options'],
    frequency: 'Multiple opportunities throughout day',
    duration: 'Ongoing strategy with expanding options',
  },
];

// Helper functions for intervention selection
export function getInterventionsByFunction(behaviorFunction: string): Intervention[] {
  return INTERVENTION_DATABASE.filter((intervention) =>
    intervention.behaviorFunction.some((func) =>
      func.toLowerCase().includes(behaviorFunction.toLowerCase()),
    ),
  );
}

export function getInterventionsByCategory(category: string): Intervention[] {
  return INTERVENTION_DATABASE.filter((intervention) =>
    intervention.category === category,
  );
}

export function getInterventionsByAgeGroup(ageGroup: string): Intervention[] {
  return INTERVENTION_DATABASE.filter((intervention) =>
    intervention.ageGroups.includes(ageGroup),
  );
}

export function getInterventionsBySetting(setting: string): Intervention[] {
  return INTERVENTION_DATABASE.filter((intervention) =>
    intervention.settings.includes(setting),
  );
}

export function getHighEvidenceInterventions(): Intervention[] {
  return INTERVENTION_DATABASE.filter((intervention) =>
    intervention.evidenceLevel === 'high',
  );
}

// Function to analyze behavior description and recommend appropriate interventions
export function analyzeAndRecommendInterventions(
    behaviorDescription: string,
    ageGroup?: string,
    setting?: string,
): {
  recommendedInterventions: Intervention[];
  behaviorAnalysis: string;
  rationale: string;
} {
  const lowerBehavior = behaviorDescription.toLowerCase();
  let recommendedInterventions: Intervention[] = [];
  const behaviorFunctions: string[] = [];

  // Analyze behavior for function
  if (lowerBehavior.includes('attention') || lowerBehavior.includes('calling out') ||
      lowerBehavior.includes('interrupt') || lowerBehavior.includes('blurt')) {
    behaviorFunctions.push('attention-seeking');
    recommendedInterventions = recommendedInterventions.concat(
        getInterventionsByCategory('attention'),
    );
  }

  if (lowerBehavior.includes('avoid') || lowerBehavior.includes('refuse') ||
      lowerBehavior.includes('won\'t') || lowerBehavior.includes('escape')) {
    behaviorFunctions.push('escape/avoidance');
    recommendedInterventions = recommendedInterventions.concat(
        getInterventionsByCategory('escape'),
    );
  }

  if (lowerBehavior.includes('movement') || lowerBehavior.includes('fidget') ||
      lowerBehavior.includes('out of seat') || lowerBehavior.includes('sensory')) {
    behaviorFunctions.push('sensory-seeking');
    recommendedInterventions = recommendedInterventions.concat(
        getInterventionsByCategory('sensory'),
    );
  }

  if (lowerBehavior.includes('peer') || lowerBehavior.includes('social') ||
      lowerBehavior.includes('friend')) {
    behaviorFunctions.push('social difficulties');
    recommendedInterventions = recommendedInterventions.concat(
        getInterventionsByCategory('social'),
    );
  }

  // Always include general interventions
  recommendedInterventions = recommendedInterventions.concat(
      getInterventionsByCategory('general'),
  );

  // Filter by age group and setting if provided
  if (ageGroup) {
    recommendedInterventions = recommendedInterventions.filter((intervention) =>
      intervention.ageGroups.includes(ageGroup),
    );
  }

  if (setting) {
    recommendedInterventions = recommendedInterventions.filter((intervention) =>
      intervention.settings.includes(setting),
    );
  }

  // Remove duplicates and prioritize high evidence interventions
  const uniqueInterventions = Array.from(
      new Map(recommendedInterventions.map((item) => [item.id, item])).values(),
  );

  const prioritizedInterventions = uniqueInterventions.sort((a, b) => {
    if (a.evidenceLevel === 'high' && b.evidenceLevel !== 'high') return -1;
    if (b.evidenceLevel === 'high' && a.evidenceLevel !== 'high') return 1;
    return 0;
  });

  const behaviorAnalysis = behaviorFunctions.length > 0 ?
    `Based on the behavior description, this appears to serve the following function(s): ${behaviorFunctions.join(', ')}.` :
    'The behavior function is unclear from the description. A comprehensive functional behavior assessment is recommended.';

  const rationale = `Interventions were selected based on evidence-based practices for the identified behavior function(s). ${
    ageGroup ? `Recommendations are appropriate for ${ageGroup} age group. ` : ''
  }${
    setting ? `Interventions are suitable for ${setting} setting. ` : ''
  }High evidence interventions are prioritized.`;

  return {
    recommendedInterventions: prioritizedInterventions.slice(0, 5), // Limit to top 5
    behaviorAnalysis,
    rationale,
  };
}
