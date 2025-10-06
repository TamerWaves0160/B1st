const admin = require('firebase-admin');

// Path to your service account key
const serviceAccount = require('../assets/credentials/behaviorfirst-515f1-87e4804bb9f1.json');

// Initialize the app with a service account, granting admin privileges
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://behaviorfirst-515f1.firebaseio.com'
});

const db = admin.firestore();

// Helper function to get a date string from days ago
function getDaysAgo(days) {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date.toISOString();
}

// This data matches your mock_student_data.dart file exactly
const mockStudentProfiles = [
  {
    id: 'student_001',
    name: 'Alex Thompson',
    age: 8,
    grade: '3rd Grade',
    behaviorHistory: [
      {
        date: getDaysAgo(7),
        behavior: 'Got out of seat 12 times during math lesson',
        antecedent: 'Teacher giving instructions for worksheet',
        consequence: 'Redirected back to seat, lost 5 minutes of recess',
        setting: 'Classroom - math lesson',
        duration: 10,
      },
      {
        date: getDaysAgo(5),
        behavior: 'Called out answers 8 times in 30 minutes',
        antecedent: 'Teacher asking questions to class',
        consequence: 'Reminded about hand-raising rule',
        setting: 'Classroom - reading lesson',
        duration: 5,
      },
      {
        date: getDaysAgo(3),
        behavior: 'Wandered around room during independent work',
        antecedent: 'Given worksheet with 20 math problems',
        consequence: 'Offered movement break, then completed work',
        setting: 'Classroom - independent work time',
        duration: 15,
      },
    ],
  },
  {
    id: 'student_002',
    name: 'Maria Rodriguez',
    age: 12,
    grade: '7th Grade',
    behaviorHistory: [
      {
        date: getDaysAgo(10),
        behavior: 'Refused to join group project, put head down on desk',
        antecedent: 'Teacher announced surprise group project',
        consequence: 'Allowed to work individually on modified version',
        setting: 'Classroom - science class',
        duration: 20,
      },
      {
        date: getDaysAgo(6),
        behavior: 'Cried and rocked when assembly was announced',
        antecedent: 'Principal came to announce surprise assembly',
        consequence: 'Given 10 minutes to prepare, used calming strategies',
        setting: 'Classroom - morning announcement time',
        duration: 10,
      },
    ],
  },
  {
    id: 'student_003',
    name: 'Jordan Kim',
    age: 15,
    grade: '10th Grade',
    behaviorHistory: [
      {
        date: getDaysAgo(4),
        behavior: 'Argued loudly with teacher about homework policy',
        antecedent: 'Teacher reminded class about late work penalties',
        consequence: 'Sent to counselor\'s office to cool down',
        setting: 'English classroom',
        duration: 5,
      },
      {
        date: getDaysAgo(2),
        behavior: 'Used profanity when asked to put phone away',
        antecedent: 'Teacher asked students to put devices in caddy',
        consequence: 'Loss of phone privileges for remainder of class',
        setting: 'History classroom',
        duration: 2,
      },
    ],
  },
  {
    id: 'student_004',
    name: 'Destiny Williams',
    age: 6,
    grade: '1st Grade',
    behaviorHistory: [
      {
        date: getDaysAgo(8),
        behavior: 'Crawled under desk and cried during fire drill practice',
        antecedent: 'Loud fire alarm sound',
        consequence: 'Allowed to cover ears, practiced with lower volume',
        setting: 'Classroom - safety drill',
        duration: 7,
      },
      {
        date: getDaysAgo(1),
        behavior: 'Repeatedly hugged and touched classmates during centers',
        antecedent: 'Free choice center time with multiple students',
        consequence: 'Redirected to sensory bin activity',
        setting: 'Classroom - center time',
        duration: 10,
      },
    ],
  },
  {
    id: 'student_005',
    name: 'Marcus Johnson',
    age: 14,
    grade: '9th Grade',
    behaviorHistory: [
      {
        date: getDaysAgo(12),
        behavior: 'Panic attack when called to present book report',
        antecedent: 'Teacher called name for presentation',
        consequence: 'Moved to quiet space, used breathing techniques',
        setting: 'English classroom',
        duration: 15,
      },
      {
        date: getDaysAgo(9),
        behavior: 'Erased and rewrote assignment 6 times, missed deadline',
        antecedent: 'Math homework assigned with grading rubric',
        consequence: 'Given extension and support to submit work',
        setting: 'Homework - math assignment',
        duration: 60,
      },
    ],
  },
  {
    id: 'student_006',
    name: 'Liam Chen',
    age: 10,
    grade: '5th Grade',
    behaviorHistory: [
      {
        date: getDaysAgo(11),
        behavior: 'Ripped up worksheet after 10 minutes of writing',
        antecedent: 'Given a one-page writing prompt',
        consequence: 'Allowed to dictate the rest of the story to a teacher',
        setting: 'Language Arts class',
        duration: 3,
      },
      {
        date: getDaysAgo(4),
        behavior: 'Pretended to be sick to avoid reading his turn aloud',
        antecedent: 'Round-robin reading in social studies',
        consequence: 'Was not forced to read, but had to read it later with a specialist',
        setting: 'Social Studies class',
        duration: 5,
      },
    ],
  },
  {
    id: 'student_007',
    name: 'Sophia Davis',
    age: 16,
    grade: '11th Grade',
    behaviorHistory: [
      {
        date: getDaysAgo(14),
        behavior: 'Remained silent and looked down when asked a direct question',
        antecedent: 'Teacher asked for her opinion during a class discussion',
        consequence: 'Teacher moved on to another student to reduce pressure',
        setting: 'History class',
        duration: 1,
      },
      {
        date: getDaysAgo(3),
        behavior: 'Asked to go to the bathroom during group project assignments',
        antecedent: 'Teacher announced students would be forming groups',
        consequence: 'Allowed to work on the project alone with modified requirements',
        setting: 'Science lab',
        duration: 5,
      },
    ],
  },
];


async function populateDatabase() {
  console.log('--- Starting Database Population Script ---');
  const studentsCollection = db.collection('students');

  try {
    // 1. Clear existing documents
    console.log('Step 1: Deleting all existing documents from "students" collection...');
    const snapshot = await studentsCollection.get();
    if (snapshot.empty) {
      console.log('No existing documents found. Skipping deletion.');
    } else {
      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Successfully deleted ${snapshot.size} documents.`);
    }

    // 2. Add new documents
    console.log('\nStep 2: Adding new documents from mock data...');
    for (const student of mockStudentProfiles) {
      const docRef = studentsCollection.doc(student.id);
      await docRef.set(student);
      console.log(`- Added student: ${student.name} (ID: ${student.id})`);
    }

    console.log('\n--- Database Population Script Finished Successfully ---');

  } catch (error) {
    console.error('\n--- SCRIPT FAILED ---');
    console.error('An error occurred:', error);
    process.exit(1); // Exit with an error code
  }
}

populateDatabase();
