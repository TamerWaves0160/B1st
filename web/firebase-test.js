// Test script to call Firebase Functions directly
// Open browser console and paste this code

// Test 1: Populate Firestore with intervention database
async function testPopulateFirestore() {
  try {
    console.log('🚀 Testing populateFirestore function...');
    const functions = firebase.functions();
    const populateFirestore = functions.httpsCallable('populateFirestore');
    
    const result = await populateFirestore({});
    console.log('✅ populateFirestore result:', result.data);
    return result.data;
  } catch (error) {
    console.error('❌ populateFirestore error:', error);
    throw error;
  }
}

// Test 2: Generate interventions using Firestore data
async function testGenerateInterventions(behaviorDescription = 'Student frequently gets out of seat during lessons') {
  try {
    console.log('🧠 Testing generateInterventions function...');
    const functions = firebase.functions();
    const generateInterventions = functions.httpsCallable('generateInterventions');
    
    const result = await generateInterventions({
      behaviorDescription: behaviorDescription,
      ageGroup: 'elementary',
      setting: 'classroom'
    });
    
    console.log('✅ generateInterventions result:', result.data);
    console.log('📋 Interventions:\n', result.data.interventions);
    return result.data;
  } catch (error) {
    console.error('❌ generateInterventions error:', error);
    throw error;
  }
}

// Test 3: Run full integration test
async function runFullTest() {
  try {
    console.log('\n🧪 === FULL INTEGRATION TEST ===\n');
    
    // Step 1: Populate Firestore
    console.log('Step 1: Populating Firestore...');
    const populateResult = await testPopulateFirestore();
    
    // Step 2: Test intervention generation
    console.log('\nStep 2: Testing intervention generation...');
    const interventionResult = await testGenerateInterventions();
    
    // Step 3: Test with different behavior
    console.log('\nStep 3: Testing with different behavior...');
    const interventionResult2 = await testGenerateInterventions('Student refuses to complete written assignments');
    
    console.log('\n🎉 === ALL TESTS PASSED! ===\n');
    
    return {
      populateResult,
      interventionResult,
      interventionResult2
    };
  } catch (error) {
    console.error('💥 Test failed:', error);
    throw error;
  }
}

// Expose functions to global scope for console testing
window.testPopulateFirestore = testPopulateFirestore;
window.testGenerateInterventions = testGenerateInterventions;
window.runFullTest = runFullTest;

console.log(`
🧪 Firebase Functions Test Suite Ready!

Available test functions:
1. testPopulateFirestore() - Populate Firestore with intervention database
2. testGenerateInterventions(behaviorDescription) - Test AI intervention generation
3. runFullTest() - Run complete integration test

Example usage:
- await testPopulateFirestore()
- await testGenerateInterventions('Student frequently gets out of seat')
- await runFullTest()
`);