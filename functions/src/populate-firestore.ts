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

// Helper to generate behavior history for 14 days
function generateBehaviorHistory(studentProfile: string): any[] {
  const behaviors: any[] = [];
  const now = Date.now();
  const dayMs = 24 * 60 * 60 * 1000;

  // Different behavior patterns based on student profile
  const behaviorTemplates: Record<string, any[]> = {
    'ADHD': [
      {behavior: 'Out of seat 8 times during reading lesson, wandered to window', antecedent: 'Teacher reading aloud to class', consequence: 'Redirected to seat, given fidget tool', setting: 'Classroom - reading', duration: 15},
      {behavior: 'Called out answers 12 times without raising hand', antecedent: 'Teacher asking comprehension questions', consequence: 'Reminded of hand-raising rule, lost participation points', setting: 'Classroom - reading', duration: 30},
      {behavior: 'Completed only 3 of 10 math problems, doodling on paper', antecedent: 'Independent work time - math worksheet', consequence: 'Given choice of completing now or during recess', setting: 'Classroom - math', duration: 20},
      {behavior: 'Running in hallway, bumped into peer', antecedent: 'Transition from classroom to lunch', consequence: 'Asked to walk back and try again', setting: 'Hallway', duration: 2},
      {behavior: 'Blurted out during quiet reading time 5 times', antecedent: 'Silent reading period', consequence: 'Moved to quieter area of room', setting: 'Classroom - reading', duration: 20},
      {behavior: 'Left seat to sharpen pencil 6 times in 15 minutes', antecedent: 'Writing assignment', consequence: 'Given pre-sharpened pencils at desk', setting: 'Classroom - writing', duration: 15},
      {behavior: 'Fidgeting with materials, knocked books off desk', antecedent: 'Teacher giving instructions', consequence: 'Helped clean up, given stress ball', setting: 'Classroom', duration: 5},
      {behavior: 'Talked to neighbors during independent work, distracted 3 peers', antecedent: 'Science worksheet completion', consequence: 'Moved to different seat', setting: 'Classroom - science', duration: 25},
    ],
    'ASD': [
      {behavior: 'Refused to join group, put head down on desk, covered ears', antecedent: 'Teacher announced group project', consequence: 'Allowed to work on individual version', setting: 'Classroom - science', duration: 10},
      {behavior: 'Became upset when schedule changed, crying and rocking', antecedent: 'Assembly announced instead of regular class', consequence: 'Given 5-minute warning and visual schedule', setting: 'Classroom', duration: 8},
      {behavior: 'Would not respond when peer asked to play', antecedent: 'Recess - peer invitation', consequence: 'Teacher provided social script prompt', setting: 'Playground', duration: 3},
      {behavior: 'Repetitive hand movements during math, not completing work', antecedent: 'Math problem solving', consequence: 'Given movement break, then completed work', setting: 'Classroom - math', duration: 15},
      {behavior: 'Refused to transition to next activity, stayed at computer', antecedent: 'Computer time ending', consequence: 'Visual timer used, successful transition after 2 minutes', setting: 'Computer lab', duration: 12},
      {behavior: 'Lined up pencils repeatedly instead of writing', antecedent: 'Writing prompt given', consequence: 'Pencils removed except one, task completed', setting: 'Classroom - writing', duration: 10},
      {behavior: 'Shut down when fire drill announced, would not move', antecedent: 'Fire drill alarm', consequence: 'Provided noise-canceling headphones, walked with support', setting: 'Classroom', duration: 20},
      {behavior: 'Focused on book during group discussion, did not respond', antecedent: 'Group reading discussion', consequence: 'Given written response option instead', setting: 'Classroom - reading', duration: 15},
    ],
    'ODD': [
      {behavior: 'Argued with teacher about assignment for 5 minutes', antecedent: 'Asked to complete math worksheet', consequence: 'Sent to cool-down area, completed later', setting: 'Classroom - math', duration: 5},
      {behavior: 'Refused to follow classroom rules, said "You can\'t make me"', antecedent: 'Reminded to put away phone', consequence: 'Phone confiscated, parent contacted', setting: 'Classroom', duration: 3},
      {behavior: 'Deliberately knocked materials off desk', antecedent: 'Asked to start assignment', consequence: 'Cleaned up materials, loss of preferred activity', setting: 'Classroom', duration: 2},
      {behavior: 'Talked back to teacher, used disrespectful tone', antecedent: 'Corrected for off-task behavior', consequence: 'Sent to office, conference with counselor', setting: 'Classroom', duration: 10},
      {behavior: 'Refused to work with assigned partner', antecedent: 'Partner assignment for science lab', consequence: 'Allowed to work alone with reduced points', setting: 'Classroom - science', duration: 5},
      {behavior: 'Blamed peer for own mistake, raised voice', antecedent: 'Caught not following directions', consequence: 'Reflection sheet completed', setting: 'Classroom', duration: 15},
      {behavior: 'Ignored three teacher requests to begin work', antecedent: 'Independent reading assignment', consequence: 'Moved closer to teacher, task completed', setting: 'Classroom - reading', duration: 10},
      {behavior: 'Rolled eyes and sighed loudly when corrected', antecedent: 'Teacher provided feedback on work', consequence: 'Private conversation about respect', setting: 'Classroom', duration: 5},
    ],
    'Anxiety': [
      {behavior: 'Tearful, refused to present project to class', antecedent: 'Called on to present', consequence: 'Allowed to present to teacher only after class', setting: 'Classroom', duration: 10},
      {behavior: 'Frequent bathroom requests, 4 times in one hour', antecedent: 'Math test period', consequence: 'Allowed breaks, test extended', setting: 'Classroom - math', duration: 50},
      {behavior: 'Chewing on pencil, shaking leg, not completing work', antecedent: 'Timed writing assignment', consequence: 'Given untimed option, work completed', setting: 'Classroom - writing', duration: 30},
      {behavior: 'Complained of stomachache, asked to go to nurse', antecedent: 'Before oral presentation', consequence: 'Nurse visit, counselor check-in, presentation postponed', setting: 'Classroom', duration: 15},
      {behavior: 'Avoided eye contact, minimal responses when called on', antecedent: 'Class discussion', consequence: 'Allowed to pass, can write response instead', setting: 'Classroom - reading', duration: 5},
      {behavior: 'Excessive erasing, paper torn from erasing', antecedent: 'Independent writing task', consequence: 'Reassurance provided, allowed to type instead', setting: 'Classroom - writing', duration: 20},
      {behavior: 'Cried when group assignment announced', antecedent: 'Group work introduction', consequence: 'Allowed to choose partner, successful completion', setting: 'Classroom', duration: 8},
      {behavior: 'Did not attempt new math concept, said "I can\'t do it"', antecedent: 'Introduction of fractions', consequence: 'Step-by-step support, successful with guidance', setting: 'Classroom - math', duration: 25},
    ],
    'General': [
      {behavior: 'Talking during instruction, off-task', antecedent: 'Teacher explaining assignment', consequence: 'Verbal reminder to listen', setting: 'Classroom', duration: 5},
      {behavior: 'Not following directions, needed multiple prompts', antecedent: 'Clean-up time', consequence: 'Loss of 2 minutes of break time', setting: 'Classroom', duration: 8},
      {behavior: 'Incomplete homework for third time this week', antecedent: 'Homework check', consequence: 'Parent email, homework club recommended', setting: 'Classroom', duration: 0},
      {behavior: 'Playing with materials instead of working', antecedent: 'Independent reading time', consequence: 'Materials removed, completed reading', setting: 'Classroom - reading', duration: 10},
    ],
  };

  const getTemplates = (profile: string) => behaviorTemplates[profile] || behaviorTemplates['General'];
  const templates = getTemplates(studentProfile);

  // Generate 10-14 incidents over 14 days
  const numIncidents = 10 + Math.floor(Math.random() * 5);
  for (let i = 0; i < numIncidents; i++) {
    const daysAgo = Math.floor((i / numIncidents) * 14);
    const date = new Date(now - (daysAgo * dayMs));
    const template = templates[i % templates.length];

    behaviors.push({
      date: date,
      behavior: template.behavior,
      antecedent: template.antecedent,
      consequence: template.consequence,
      setting: template.setting,
      duration: template.duration,
    });
  }

  return behaviors;
}

// Mock student data with 14 days of behavior history
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
    behaviorHistory: generateBehaviorHistory('ADHD'),
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
    behaviorHistory: generateBehaviorHistory('ASD'),
  },
  {
    id: 'student_003',
    name: 'Jordan Lee',
    age: 10,
    grade: '5th Grade',
    diagnosis: 'Oppositional Defiant Disorder',
    behaviorConcerns: [
      'Argues with adults',
      'Refuses to comply with requests',
      'Deliberately annoys others',
    ],
    strengths: [
      'Strong leadership qualities',
      'Athletic abilities',
      'Loyal to friends',
    ],
    currentInterventions: [
      'Choice-making opportunities',
      'Positive adult relationship building',
      'Clear expectations with logical consequences',
    ],
    behaviorHistory: generateBehaviorHistory('ODD'),
  },
  {
    id: 'student_004',
    name: 'Emma Chen',
    age: 9,
    grade: '4th Grade',
    diagnosis: 'Anxiety Disorder',
    behaviorConcerns: [
      'Avoids academic challenges',
      'Frequent somatic complaints',
      'Difficulty with social situations',
    ],
    strengths: [
      'Highly organized',
      'Empathetic toward others',
      'Excellent written communication',
    ],
    currentInterventions: [
      'Regular check-ins with counselor',
      'Break pass when overwhelmed',
      'Alternative presentation formats',
    ],
    behaviorHistory: generateBehaviorHistory('Anxiety'),
  },
  {
    id: 'student_005',
    name: 'Marcus Williams',
    age: 11,
    grade: '6th Grade',
    diagnosis: 'ADHD - Combined Type',
    behaviorConcerns: [
      'Impulsive responses',
      'Difficulty waiting turn',
      'Loses materials frequently',
    ],
    strengths: [
      'Enthusiastic about learning',
      'Creative thinker',
      'Good sense of humor',
    ],
    currentInterventions: [
      'Organizational system with color-coding',
      'Preferential seating near teacher',
      'Frequent positive reinforcement',
    ],
    behaviorHistory: generateBehaviorHistory('ADHD'),
  },
  {
    id: 'student_006',
    name: 'Sophia Patel',
    age: 13,
    grade: '8th Grade',
    diagnosis: 'Autism Spectrum Disorder',
    behaviorConcerns: [
      'Rigid thinking patterns',
      'Difficulty with transitions',
      'Limited peer relationships',
    ],
    strengths: [
      'Advanced vocabulary',
      'Strong interest in science',
      'Honest and direct communication',
    ],
    currentInterventions: [
      'Visual schedules for transitions',
      'Social skills group participation',
      'Special interest integration in lessons',
    ],
    behaviorHistory: generateBehaviorHistory('ASD'),
  },
  {
    id: 'student_007',
    name: 'Tyler Brown',
    age: 7,
    grade: '2nd Grade',
    diagnosis: 'Generalized Anxiety Disorder',
    behaviorConcerns: [
      'School refusal behaviors',
      'Perfectionism leading to incomplete work',
      'Separation anxiety',
    ],
    strengths: [
      'Kind to peers',
      'Follows classroom rules',
      'Strong in math concepts',
    ],
    currentInterventions: [
      'Gradual exposure to anxiety triggers',
      'Positive self-talk scripts',
      'Parent communication at transitions',
    ],
    behaviorHistory: generateBehaviorHistory('Anxiety'),
  },
];

export const populateFirestore = onCall(
    {region: 'us-central1', timeoutSeconds: 300},
    async (request) => {
      const uid = request.auth?.uid || 'system';
      // Require authentication for production use
      if (!request.auth?.uid) {
        throw new HttpsError('unauthenticated', 'Admin authentication required.');
      }
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

        // Add mock students to 'students' collection (not 'mock_students')
        // This way the migration function can find them
        for (const student of mockStudents) {
          const docRef = db.collection('students').doc(student.id);
          batch.set(docRef, {
            ...student,
            ownerUid: uid, // Add owner immediately
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
