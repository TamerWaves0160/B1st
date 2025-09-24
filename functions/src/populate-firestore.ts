// functions/src/populate-firestore.ts
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {getFirestore} from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';

// Initialize Firestore
const db = getFirestore();

// Intervention database data
const interventions = [
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
  {
    id: 'general-001',
    name: 'Token Economy',
    category: 'general',
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
];

// Mock student data
const mockStudents = [
  {
    id: 'student_001',
    name: 'Alex Thompson',
    age: 8,
    grade: '3rd Grade',
    diagnosis: 'ADHD',
    behaviorConcerns: [
      'Frequent out-of-seat behavior during lessons',
      'Difficulty following multi-step directions',
      'Blurting out answers without raising hand',
    ],
    strengths: [
      'Excellent reading comprehension',
      'Creative problem solver',
      'Helpful to peers when calm',
    ],
    currentInterventions: [
      'Movement breaks every 20 minutes',
      'Visual schedule for daily routine',
    ],
  },
  {
    id: 'student_002',
    name: 'Maria Rodriguez',
    age: 12,
    grade: '7th Grade',
    diagnosis: 'Autism Spectrum Disorder',
    behaviorConcerns: [
      'Refuses to participate in group activities',
      'Becomes upset with schedule changes',
      'Difficulty with peer interactions',
    ],
    strengths: [
      'Exceptional attention to detail',
      'Strong memory for facts and procedures',
      'Calm and focused during individual work',
    ],
    currentInterventions: [
      'Advance notice of schedule changes',
      'Social scripts for peer interactions',
      'Choice of group or individual work options',
    ],
  },
];

export const populateFirestore = onCall(
    {region: 'us-central1', timeoutSeconds: 300},
    async (request) => {
      const uid = request.auth?.uid;
      if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
      logger.info('populateFirestore called', {uid});

      try {
        const batch = db.batch();
        let operationCount = 0;

        // Add interventions
        for (const intervention of interventions) {
          const docRef = db.collection('interventions').doc(intervention.id);
          batch.set(docRef, {
            ...intervention,
            createdAt: new Date(),
            updatedAt: new Date(),
          });
          operationCount++;
        }

        // Add mock students
        for (const student of mockStudents) {
          const docRef = db.collection('mock_students').doc(student.id);
          batch.set(docRef, {
            ...student,
            createdAt: new Date(),
            updatedAt: new Date(),
          });
          operationCount++;
        }

        // Commit the batch
        await batch.commit();

        logger.info('Firestore populated successfully', {
          interventions: interventions.length,
          mockStudents: mockStudents.length,
          totalOperations: operationCount,
        });

        return {
          success: true,
          message: 'Firestore populated successfully',
          interventionsAdded: interventions.length,
          studentsAdded: mockStudents.length,
          totalOperations: operationCount,
        };
      } catch (error) {
        logger.error('Error populating Firestore:', error);
        throw new HttpsError('internal', 'Failed to populate Firestore');
      }
    },
);
