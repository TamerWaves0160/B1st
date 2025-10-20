# BehaviorFirst App - Complete Setup & Testing Guide

## 🎯 What Your App Has Now

### ✅ Complete Feature Set
1. **Behavior Observations** → Firebase Firestore (observation_page.dart)
2. **Working RAG System** → Embeddings + Vector Search + Gemini LLM
3. **Behavior Visualizer** → Charts and graphs for behavior patterns
4. **7 Mock Students** → Each with 10-14 days of realistic behavior data
5. **FBA Generation** → AI-powered Functional Behavior Assessments
6. **BIP Generation** → AI-powered Behavior Intervention Plans

---

## 🚀 Step-by-Step Setup Process

### Step 1: Populate Mock Students (5 minutes)

**Goal:** Add 7 mock students with 10-14 behavior incidents each spanning 14 days

1. Open your web app: https://behaviorfirst-515f1.web.app
2. Sign in with your credentials
3. Navigate to **"Intervention Recs"** tab
4. Look for **"Populate Database"** button (or similar - check your UI)
5. Click it to populate Firestore with:
   - 7 mock students (student_001 through student_007)
   - 10-14 behavior incidents per student
   - Incidents spread across past 14 days

**Mock Students:**
- **Alex Thompson** (8 yrs, ADHD) - Out of seat, calling out, impulsivity
- **Maria Rodriguez** (12 yrs, ASD) - Transitions, group work, social difficulties
- **Jordan Lee** (10 yrs, ODD) - Arguments, refusals, defiance
- **Emma Chen** (9 yrs, Anxiety) - Avoidance, somatic complaints, fear
- **Marcus Williams** (11 yrs, ADHD) - Impulsivity, disorganization
- **Sophia Patel** (13 yrs, ASD) - Rigid thinking, transitions
- **Tyler Brown** (7 yrs, Anxiety) - School refusal, perfectionism

### Step 2: Migrate Data to Correct Format (2 minutes)

**Goal:** Convert `behaviorHistory` arrays into `behavior_events` documents

**Why needed?** Mock students store behavior data in arrays, but FBA/BIP reports query the `behavior_events` collection.

1. Still in **"Intervention Recs"** tab
2. Find the **"Migrate Data"** button (top-right corner, small button next to "Reindex DB")
3. Click **"Migrate Data"**
4. A confirmation dialog will appear explaining:
   - Adds your user ID to all students
   - Converts behaviorHistory arrays to behavior_events documents
5. Click **"Migrate"**
6. Wait 10-30 seconds for success message
7. Success message will show: "Successfully migrated X behavior events from Y students"

**Expected Result:** ~70-98 behavior_events documents created (10-14 per student × 7 students)

### Step 3: Generate FBA Report (3 minutes)

**Goal:** Create a Functional Behavior Assessment for a student

1. In **"Intervention Recs"** tab, scroll to FBA/BIP section
2. **Select Student:** Choose "Alex Thompson" (student_001) from dropdown
3. **Report Type:** Select "FBA" (Functional Behavior Assessment)
4. **Date Range:** Leave blank to use all available data (or specify last 14 days)
5. Click **"Generate FBA Report"**
6. Wait 15-30 seconds
7. Report should appear with:
   - Student information
   - Behavior patterns analysis
   - Antecedent/trigger identification
   - Function of behavior hypothesis
   - Recommended data collection methods

### Step 4: Generate BIP Report (3 minutes)

**Goal:** Create a Behavior Intervention Plan for a student

1. Same location in **"Intervention Recs"** tab
2. **Select Student:** Choose "Maria Rodriguez" (student_002)
3. **Report Type:** Select "BIP" (Behavior Intervention Plan)
4. **Date Range:** Leave blank
5. Click **"Generate BIP Report"**
6. Wait 15-30 seconds
7. Report should appear with:
   - Target behaviors
   - Replacement behaviors to teach
   - Prevention strategies
   - Teaching strategies
   - Response strategies for problem behavior
   - Monitoring and data collection plan

---

## 🔍 Verification Checklist

### After Step 1 (Population):
- [ ] Firebase Console shows 7 documents in `students` or `mock_students` collection
- [ ] Each student has `behaviorHistory` array with 10-14 items

### After Step 2 (Migration):
- [ ] Firebase Console shows ~70-98 documents in `behavior_events` collection
- [ ] Each behavior_events document has:
  - `uid` (your user ID)
  - `studentId` (student_001, etc.)
  - `behaviorType` (Out of Seat, Calling Out, etc.)
  - `severity` (Mild, Moderate, Severe)
  - `antecedent`, `consequence`, `location`
  - `createdAt` (timestamp spread across 14 days)

### After Step 3 & 4 (FBA/BIP):
- [ ] Reports appear in UI with structured content
- [ ] Console shows "Found X behavior events" (not 0)
- [ ] Reports are saved to `ai_reports` collection in Firestore

---

## 🐛 Troubleshooting

### "Found 0 behavior events" Error
**Problem:** Migration didn't run or user ID mismatch  
**Solution:**
1. Check Firebase Console → behavior_events collection
2. Verify documents have your user ID in `uid` field
3. Re-run migration if needed

### "Permission Denied" Error
**Problem:** Not authenticated or Firestore rules issue  
**Solution:**
1. Ensure you're signed in
2. Check Firestore rules allow authenticated users to read behavior_events

### "No students found" in Dropdown
**Problem:** Population didn't run or ownerUid missing  
**Solution:**
1. Run Step 1 (Populate) again
2. Check students collection for documents
3. Verify migration added `ownerUid` to students

### Migration Button Not Visible
**Problem:** App must be in debug mode  
**Solution:**
1. Hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
2. Clear browser cache
3. Check if `kDebugMode` is enabled in Flutter app

---

## 📊 Behavior Data Details

### Behavior Types Included:
- **ADHD Students:** Out of seat, calling out, fidgeting, incomplete work
- **ASD Students:** Refusals, shutdowns, transitions, repetitive behaviors
- **ODD Students:** Arguments, defiance, property damage
- **Anxiety Students:** Avoidance, somatic complaints, crying, perfectionism

### Data Realism:
- **Antecedents:** Task demands, transitions, social situations
- **Consequences:** Redirections, breaks, accommodations, removals
- **Settings:** Classroom (math, reading, science), hallway, playground
- **Duration:** 2-50 minutes per incident
- **Severity:** Mix of Mild, Moderate, and Severe

---

## 🔧 Database Structure

### Collections:
```
students/
  └─ student_001
      ├─ name: "Alex Thompson"
      ├─ ownerUid: "ujbh7fonM1XmL1y3ouqXHcmA6qa2"
      └─ behaviorHistory: [array of incidents]

behavior_events/
  └─ [auto-generated-id]
      ├─ uid: "ujbh7fonM1XmL1y3ouqXHcmA6qa2"
      ├─ studentId: "student_001"
      ├─ behaviorType: "Out of Seat"
      ├─ severity: "Moderate"
      ├─ antecedent: "Teacher giving instructions"
      ├─ consequence: "Redirected to seat"
      ├─ location: "Classroom - math"
      ├─ durationSeconds: 900
      └─ createdAt: [timestamp]

ai_reports/
  └─ [auto-generated-id]
      ├─ studentId: "student_001"
      ├─ reportType: "FBA" or "BIP"
      ├─ content: "[AI-generated report]"
      └─ generatedDate: [timestamp]
```

---

## ✨ Next Steps

After completing setup:
1. **Test RAG System** → Try "Intervention Recs" with behavior scenarios
2. **View Visualizer** → Check behavior charts for each student
3. **Add Real Observations** → Use observation form to add new behavior data
4. **Export Reports** → Generate PDFs of FBA/BIP reports (if implemented)
5. **Clean Up Debug Logging** → Remove `print()` statements from ai_report_service.dart

---

## 📝 Notes

- Migration is a **one-time operation** - don't run multiple times
- Each student can have **multiple FBA/BIP reports** (different date ranges)
- Behavior data is **date-sorted** for trend analysis
- **RAG system** works independently of FBA/BIP (uses intervention database)

---

## 🆘 Support

If issues persist:
1. Check browser console for error messages
2. Verify Firebase Console shows expected data
3. Review Firestore rules for permissions
4. Check user authentication status

**Current User ID:** `ujbh7fonM1XmL1y3ouqXHcmA6qa2`  
**Web App:** https://behaviorfirst-515f1.web.app  
**Firebase Console:** https://console.firebase.google.com/project/behaviorfirst-515f1

---

Last Updated: October 19, 2025
