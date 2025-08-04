# LawBot Novelty Features - Testing Guide

## Overview
This document provides testing instructions for the three novelty features implemented in LawBot:
1. **Smart Evidence Guidance** 💡
2. **Report Credibility Meter** 📊  
3. **Report Pattern Alerts** ⚠️

## Pre-Testing Setup

### 1. Database Schema Setup
Run the SQL commands from `NOVELTY_FEATURES_DATABASE_SCHEMA.md` in your Supabase SQL Editor in this order:

```sql
-- 1. Create scammer_patterns table
-- 2. Create report_credibility_scores table  
-- 3. Create evidence_suggestions table
-- 4. Update complaints table
-- 5. Create pattern detection functions
-- 6. Create trigger functions
```

### 2. Application Setup
Ensure the following services are properly initialized:
- Google Generative AI API key is configured
- Supabase connection is working
- Firebase authentication is set up

## Feature Testing Scenarios

### 🤖 Smart Evidence Guidance Testing

#### Test Case 1: Crime Type Selection
1. **Action**: Open complaint form and select a crime type (e.g., "Online Banking Fraud")
2. **Expected Result**: 
   - Evidence guidance card appears below crime type selection
   - Shows specific evidence recommendations for financial crimes
   - Displays priority levels (Critical, High, Medium)
   - Shows examples for each evidence type

#### Test Case 2: Different Crime Categories
1. **Action**: Switch between different crime types:
   - Financial crimes (Banking Fraud, Investment Scams)
   - Communication crimes (Phishing, Social Engineering)
   - Harassment crimes (Cyberbullying, Sextortion)
2. **Expected Result**:
   - Evidence guidance updates dynamically
   - Different recommendations for each category
   - Category-specific icons and priorities

#### Test Case 3: Evidence Guidance Content
**Financial Crimes Should Show**:
- 💰 Payment Proof (Critical)
- 🏦 Account Information (High)
- 💬 Communication Records (High)

**Communication Crimes Should Show**:
- 💬 Screenshots ng Conversation (High)
- 👤 Profile Information (High)
- 📞 Contact Details (Medium)

### 📊 Report Credibility Meter Testing

#### Test Case 1: Empty Form
1. **Action**: Select crime type but leave form mostly empty
2. **Expected Result**:
   - Credibility score appears (around 20-40%)
   - Shows "Weak" or "Needs Improvement" status
   - Red/orange color coding
   - Multiple improvement suggestions

#### Test Case 2: Partial Form Completion
1. **Action**: Fill basic info (name, email, phone, description)
2. **Expected Result**:
   - Score increases to 50-70%
   - Shows "Fair" or "Good" status
   - Yellow/orange color coding
   - Fewer suggestions

#### Test Case 3: Complete Form with Evidence
1. **Action**: Fill all relevant fields + upload evidence files
2. **Expected Result**:
   - Score reaches 80-95%
   - Shows "Very Good" or "Excellent" status
   - Green color coding
   - Minimal or no suggestions

#### Test Case 4: Real-time Updates
1. **Action**: Type in description field and watch score change
2. **Expected Result**:
   - Score updates as you type
   - Progress bars animate
   - Suggestions appear/disappear dynamically

### ⚠️ Report Pattern Alerts Testing

#### Test Case 1: New Scammer Pattern
1. **Action**: Enter suspect contact (email/phone) that hasn't been reported before
2. **Expected Result**:
   - No pattern alert shown
   - Form submission proceeds normally

#### Test Case 2: Known Scammer Pattern (Manual Setup)
1. **Setup**: Create 2-3 test complaints with same suspect email/phone in database
2. **Action**: Enter the same suspect contact information
3. **Expected Result**:
   - Pattern alert popup appears
   - Shows severity level (High Risk/Critical)
   - Displays match count and timeframe
   - Offers "I Understand" or "Cancel Report" options

#### Test Case 3: Multiple Pattern Types
Test with different pattern types:
- **Email**: scammer@test.com
- **Phone**: +639123456789
- **Platform**: Facebook profile URL
- **Website**: Fake investment site

#### Test Case 4: Pattern Alert Severity Levels
- **Low Risk**: 2 similar reports → Green alert
- **Medium Risk**: 3-4 reports → Yellow alert  
- **High Risk**: 5-9 reports → Orange alert
- **Critical**: 10+ reports → Red alert

## Integration Testing

### Test Case 1: Complete User Journey
1. **Action**: Complete entire complaint submission process
2. **Steps**:
   - Select crime type → Evidence guidance appears
   - Fill form gradually → Credibility score updates
   - Enter suspect info → Pattern check occurs
   - Submit complaint → All data saved properly

### Test Case 2: Cross-Feature Interaction
1. **Action**: Follow evidence guidance to improve credibility score
2. **Expected Result**:
   - Following guidance increases credibility score
   - Uploading recommended evidence improves rating
   - Pattern alerts don't interfere with credibility scoring

## Performance Testing

### Test Case 1: Real-time Updates
- **Metric**: Credibility score updates should occur within 500ms of form changes
- **Method**: Type quickly in description field and observe score changes

### Test Case 2: Pattern Detection Speed
- **Metric**: Pattern alerts should appear within 2 seconds of entering suspect info
- **Method**: Use stopwatch to measure from input to alert display

### Test Case 3: AI Response Time
- **Metric**: Evidence suggestions should load within 3 seconds of crime type selection
- **Method**: Measure time from selection to guidance display

## Error Handling Testing

### Test Case 1: Network Connectivity
1. **Action**: Disconnect internet during form completion
2. **Expected Result**:
   - Credibility scoring continues with local data
   - Pattern detection gracefully fails
   - Evidence guidance shows cached recommendations

### Test Case 2: AI Service Failure
1. **Action**: Use invalid API key or simulate AI service downtime
2. **Expected Result**:
   - Fallback evidence suggestions appear
   - Generic credibility analysis continues
   - User can still submit complaint

### Test Case 3: Database Connectivity
1. **Action**: Simulate Supabase connection issues
2. **Expected Result**:
   - Pattern detection fails silently
   - Form submission queued for retry
   - User experience remains smooth

## Success Criteria

### Smart Evidence Guidance ✅
- [ ] Dynamic guidance appears for all 10 crime categories
- [ ] Recommendations are relevant and specific
- [ ] Priority levels are correctly displayed
- [ ] Examples are helpful and accurate

### Report Credibility Meter ✅
- [ ] Score calculation is accurate and fair
- [ ] Real-time updates work smoothly
- [ ] Visual indicators are clear and intuitive
- [ ] Suggestions are actionable and specific

### Report Pattern Alerts ✅
- [ ] Duplicate patterns are correctly detected
- [ ] Alert severity matches pattern frequency
- [ ] User can make informed decisions
- [ ] Data privacy is maintained

## Troubleshooting Common Issues

### Evidence Guidance Not Appearing
- Check if crime type is properly selected
- Verify AI service initialization
- Check console for API errors

### Credibility Score Not Updating
- Ensure form listeners are properly attached
- Check if score calculation has errors
- Verify form data structure matches expected format

### Pattern Alerts Not Triggering
- Confirm database tables are created
- Check if test data exists in complaints table
- Verify Supabase connection permissions

## Reporting Issues

When reporting issues, include:
1. **Steps to reproduce**
2. **Expected vs actual behavior**
3. **Browser/device information**
4. **Console error messages**
5. **Network connectivity status**

## Next Steps After Testing

1. **Performance Optimization**: Based on response times
2. **User Feedback Collection**: From beta testers  
3. **AI Model Tuning**: Based on suggestion relevance
4. **Database Query Optimization**: For pattern detection
5. **UI/UX Refinements**: Based on user interactions