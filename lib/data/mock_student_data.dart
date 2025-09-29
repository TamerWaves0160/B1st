// lib/data/mock_student_data.dart
// Mock student data for testing and demonstration purposes

class MockStudentData {
  static List<StudentProfile> getStudentProfiles() {
    return [
      StudentProfile(
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
        behaviorHistory: [
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 7)),
            behavior: 'Got out of seat 12 times during math lesson',
            antecedent: 'Teacher giving instructions for worksheet',
            consequence: 'Redirected back to seat, lost 5 minutes of recess',
            setting: 'Classroom - math lesson',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 5)),
            behavior: 'Called out answers 8 times in 30 minutes',
            antecedent: 'Teacher asking questions to class',
            consequence: 'Reminded about hand-raising rule',
            setting: 'Classroom - reading lesson',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 3)),
            behavior: 'Wandered around room during independent work',
            antecedent: 'Given worksheet with 20 math problems',
            consequence: 'Offered movement break, then completed work',
            setting: 'Classroom - independent work time',
          ),
        ],
      ),

      StudentProfile(
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
        behaviorHistory: [
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 10)),
            behavior: 'Refused to join group project, put head down on desk',
            antecedent: 'Teacher announced surprise group project',
            consequence: 'Allowed to work individually on modified version',
            setting: 'Classroom - science class',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 6)),
            behavior: 'Cried and rocked when assembly was announced',
            antecedent: 'Principal came to announce surprise assembly',
            consequence: 'Given 10 minutes to prepare, used calming strategies',
            setting: 'Classroom - morning announcement time',
          ),
        ],
      ),

      StudentProfile(
        id: 'student_003',
        name: 'Jordan Kim',
        age: 15,
        grade: '10th Grade',
        diagnosis: 'Oppositional Defiant Disorder',
        behaviorConcerns: [
          'Argues with teachers about assignments',
          'Refuses to follow classroom rules',
          'Uses inappropriate language when frustrated',
        ],
        strengths: [
          'Strong leadership abilities',
          'Excellent critical thinking skills',
          'Protective of younger students',
        ],
        currentInterventions: [
          'Choice in assignment format',
          'Regular check-ins with counselor',
          'Peer mediation training',
        ],
        behaviorHistory: [
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 4)),
            behavior: 'Argued loudly with teacher about homework policy',
            antecedent: 'Teacher reminded class about late work penalties',
            consequence: 'Sent to counselor\'s office to cool down',
            setting: 'English classroom',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 2)),
            behavior: 'Used profanity when asked to put phone away',
            antecedent: 'Teacher asked students to put devices in caddy',
            consequence: 'Loss of phone privileges for remainder of class',
            setting: 'History classroom',
          ),
        ],
      ),

      StudentProfile(
        id: 'student_004',
        name: 'Destiny Williams',
        age: 6,
        grade: '1st Grade',
        diagnosis: 'Sensory Processing Disorder',
        behaviorConcerns: [
          'Covers ears and hides under desk during loud activities',
          'Seeks excessive physical contact with peers',
          'Difficulty sitting still during circle time',
        ],
        strengths: [
          'Very empathetic toward others',
          'Loves art and creative activities',
          'Quick to help clean up classroom',
        ],
        currentInterventions: [
          'Noise-canceling headphones available',
          'Fidget toys during sitting activities',
          'Alternative seating options',
        ],
        behaviorHistory: [
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 8)),
            behavior: 'Crawled under desk and cried during fire drill practice',
            antecedent: 'Loud fire alarm sound',
            consequence: 'Allowed to cover ears, practiced with lower volume',
            setting: 'Classroom - safety drill',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 1)),
            behavior: 'Repeatedly hugged and touched classmates during centers',
            antecedent: 'Free choice center time with multiple students',
            consequence: 'Redirected to sensory bin activity',
            setting: 'Classroom - center time',
          ),
        ],
      ),

      StudentProfile(
        id: 'student_005',
        name: 'Marcus Johnson',
        age: 14,
        grade: '9th Grade',
        diagnosis: 'Anxiety Disorder',
        behaviorConcerns: [
          'Refuses to present in front of class',
          'Frequently asks to go to nurse when tests announced',
          'Perfectionist behaviors causing work completion issues',
        ],
        strengths: [
          'Excellent written communication skills',
          'Thoughtful and reflective learner',
          'Strong relationships with teachers',
        ],
        currentInterventions: [
          'Alternative presentation formats',
          'Extended time for assignments',
          'Regular check-ins about stress levels',
        ],
        behaviorHistory: [
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 12)),
            behavior: 'Panic attack when called to present book report',
            antecedent: 'Teacher called name for presentation',
            consequence: 'Moved to quiet space, used breathing techniques',
            setting: 'English classroom',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 9)),
            behavior: 'Erased and rewrote assignment 6 times, missed deadline',
            antecedent: 'Math homework assigned with grading rubric',
            consequence: 'Given extension and support to submit work',
            setting: 'Homework - math assignment',
          ),
        ],
      ),

      StudentProfile(
        id: 'student_006',
        name: 'Liam Chen',
        age: 10,
        grade: '5th Grade',
        diagnosis: 'Dyslexia',
        behaviorConcerns: [
          'Avoids reading aloud in class',
          'Shows frustration during writing tasks',
          'Distracts peers to avoid starting assignments',
        ],
        strengths: [
          'Strong verbal reasoning and storytelling',
          'Excels in hands-on science experiments',
          'Good at mathematical concepts',
        ],
        currentInterventions: [
          'Access to text-to-speech software',
          'Use of graphic organizers for writing',
          'Breaks during long reading passages',
        ],
        behaviorHistory: [
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 11)),
            behavior: 'Ripped up worksheet after 10 minutes of writing',
            antecedent: 'Given a one-page writing prompt',
            consequence: 'Allowed to dictate the rest of the story to a teacher',
            setting: 'Language Arts class',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 4)),
            behavior: 'Pretended to be sick to avoid reading his turn aloud',
            antecedent: 'Round-robin reading in social studies',
            consequence: 'Was not forced to read, but had to read it later with a specialist',
            setting: 'Social Studies class',
          ),
        ],
      ),

      StudentProfile(
        id: 'student_007',
        name: 'Sophia Davis',
        age: 16,
        grade: '11th Grade',
        diagnosis: 'Social Anxiety',
        behaviorConcerns: [
          'Does not participate in class discussions',
          'Avoids group work, preferring to work alone',
          'Shows physical signs of stress (e.g., shaking) when asked to present',
        ],
        strengths: [
          'Excellent writer and observer',
          'Highly dependable and turns in quality work',
          'Thrives in quiet, structured environments',
        ],
        currentInterventions: [
          'Option to submit written responses instead of speaking',
          'Paired with a trusted peer for group activities',
          'Advance notice before being called on in class',
        ],
        behaviorHistory: [
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 14)),
            behavior: 'Remained silent and looked down when asked a direct question',
            antecedent: 'Teacher asked for her opinion during a class discussion',
            consequence: 'Teacher moved on to another student to reduce pressure',
            setting: 'History class',
          ),
          BehaviorIncident(
            date: DateTime.now().subtract(Duration(days: 3)),
            behavior: 'Asked to go to the bathroom during group project assignments',
            antecedent: 'Teacher announced students would be forming groups',
            consequence: 'Allowed to work on the project alone with modified requirements',
            setting: 'Science lab',
          ),
        ],
      ),
    ];
  }

  // Common behavior scenarios for testing AI recommendations
  static List<BehaviorScenario> getTestScenarios() {
    return [
      BehaviorScenario(
        description: 'Student frequently gets out of seat during instruction',
        expectedFunctions: ['sensory-seeking', 'attention-seeking'],
        context: 'Elementary classroom during teacher-led lessons',
      ),
      BehaviorScenario(
        description: 'Student refuses to complete written assignments',
        expectedFunctions: ['escape/avoidance'],
        context: 'Middle school academic setting',
      ),
      BehaviorScenario(
        description: 'Student argues with peers during group work',
        expectedFunctions: ['social difficulties', 'attention-seeking'],
        context: 'High school collaborative learning environment',
      ),
      BehaviorScenario(
        description: 'Student covers ears and hides when noise levels increase',
        expectedFunctions: ['sensory-seeking', 'escape/avoidance'],
        context: 'Elementary classroom during transitions',
      ),
      BehaviorScenario(
        description: 'Student calls out answers without raising hand',
        expectedFunctions: ['attention-seeking'],
        context: 'Any classroom during question-answer sessions',
      ),
    ];
  }
}

class StudentProfile {
  final String id;
  final String name;
  final int age;
  final String grade;
  final String diagnosis;
  final List<String> behaviorConcerns;
  final List<String> strengths;
  final List<String> currentInterventions;
  final List<BehaviorIncident> behaviorHistory;

  StudentProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.diagnosis,
    required this.behaviorConcerns,
    required this.strengths,
    required this.currentInterventions,
    required this.behaviorHistory,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'grade': grade,
      'diagnosis': diagnosis,
      'behaviorConcerns': behaviorConcerns,
      'strengths': strengths,
      'currentInterventions': currentInterventions,
      'behaviorHistory': behaviorHistory
          .map((incident) => incident.toJson())
          .toList(),
    };
  }
}

class BehaviorIncident {
  final DateTime date;
  final String behavior;
  final String antecedent;
  final String consequence;
  final String setting;

  BehaviorIncident({
    required this.date,
    required this.behavior,
    required this.antecedent,
    required this.consequence,
    required this.setting,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'behavior': behavior,
      'antecedent': antecedent,
      'consequence': consequence,
      'setting': setting,
    };
  }
}

class BehaviorScenario {
  final String description;
  final List<String> expectedFunctions;
  final String context;

  BehaviorScenario({
    required this.description,
    required this.expectedFunctions,
    required this.context,
  });
}
