# Status Templates Testing Guide

## 🧪 **Comprehensive Testing Plan**

Test all status transition scenarios to ensure the enhanced template system works correctly with bidirectional workflows.

## **Test Scenarios**

### **Test 1: Forward Status Progression**

#### **Scenario A: Pending → Under Investigation**
1. **Open case with "Pending" status**
2. **Click "Update Status"** 
3. **Select "Under Investigation"** from radio buttons
4. **Verify Templates Appear:**
   - Should see 6 templates for "Under Investigation"
   - Categories: Transitions, Standard Updates
   - Templates should include:
     - 🔍 "Investigation Officially Started"
     - 🔬 "Evidence Collection Initiated"
     - 👥 "Witness Interview Stage"

5. **Test Template Selection:**
   - Click "Investigation Officially Started"
   - **Verify Auto-Population:**
     - ✅ Update notes filled with professional text
     - ✅ Urgency level set to "normal"
     - ✅ Follow-up date set to +7 days
   - Notes should contain: "Investigation has officially commenced..."

6. **Submit Update** and verify success

#### **Scenario B: Under Investigation → Resolved**
1. **Open case with "Under Investigation" status**
2. **Select "Resolved"** 
3. **Verify Templates:**
   - Should see 5 resolution templates
   - Category: Case Closures (purple)
   - Templates include:
     - 🚔 "Suspect Successfully Apprehended"
     - 💰 "Full Recovery Achieved"
     - ⚖️ "Case Prepared for Prosecution"

4. **Test Template with Different Urgency:**
   - Select "Suspect Successfully Apprehended"
   - Should set urgency to "low" (resolved cases)
   - No follow-up date (case closed)

### **Test 2: Bidirectional Workflows (Critical)**

#### **Scenario A: Under Investigation → Pending (Reverse)**
1. **Open "Under Investigation" case**
2. **Select "Pending"** (going backwards)
3. **Verify Special Reverse Templates:**
   - ⏸️ "Returned from Investigation" 
   - 🔺 "Escalated for Review"
   - 🏳 "Awaiting Resources"

4. **Test Reverse Template:**
   - Select "Returned from Investigation"
   - Should contain: "Case has been returned from active investigation status..."
   - Urgency: normal, Follow-up: 3 days

#### **Scenario B: Requires More Info → Under Investigation**
1. **Case status: "Requires More Information"**
2. **Select "Under Investigation"**
3. **Verify Context-Aware Templates:**
   - Should show templates appropriate for resuming investigation
   - 🔬 "Evidence Collection Initiated" (from more info status)
   - 🔍 "Investigation Officially Started"

### **Test 3: Information Request Workflows**

#### **Scenario A: Under Investigation → Requires More Information**
1. **Investigation case**
2. **Select "Requires More Information"**
3. **Verify 5 Info Request Templates:**
   - 📞 "Additional Complainant Information"
   - 🔍 "Evidence Gap Identified" 
   - 👥 "Missing Witness Information"
   - 🔧 "Technical Evidence Insufficient"
   - ⚖️ "Legal Clarification Required"

4. **Test High-Priority Template:**
   - Select "Evidence Gap Identified"
   - Should set urgency to "high"
   - Follow-up: 3 days (urgent)
   - Text: "Critical evidence gap identified..."

#### **Scenario B: Requires More Info → Resolved (Skip Investigation)**
1. **"Requires More Information" case**
2. **Select "Resolved"**
3. **Should show resolution templates**
4. **Test appropriate resolution:**
   - 🤝 "Resolved Through Mediation"
   - Should work even without going back to investigation

### **Test 4: Case Dismissal Scenarios**

#### **Test All Dismissal Paths:**
1. **From Pending → Dismissed**
   - Should see: 🏛️ "Outside PNP Jurisdiction", 📄 "Duplicate Case"
2. **From Under Investigation → Dismissed**
   - Should see: 📋 "Insufficient Evidence", 🚪 "Complainant Withdrew"
3. **From Requires More Info → Dismissed**
   - All dismissal templates should be available

### **Test 5: Visual and UX Elements**

#### **Status Transition Indicator**
1. **Open any status update modal**
2. **Verify transition display:**
   - ✅ Current status on left with icon
   - ✅ Arrow pointing right
   - ✅ New status on right with different color
   - ✅ Template count indicator at bottom

#### **Template Organization**
1. **Templates grouped by category**
2. **Color coding:**
   - 🟦 Blue: Transitions
   - 🟢 Green: Standard  
   - 🟠 Orange: Escalations
   - 🟣 Purple: Closures

#### **Template Cards**
1. **Each template shows:**
   - ✅ Icon and title
   - ✅ Urgency badge
   - ✅ Follow-up days indicator
   - ✅ Hover tooltip with full text

### **Test 6: Edge Cases**

#### **No Templates Available**
1. **Test uncommon transitions**
2. **Should show:**
   - "No templates available for this status transition"
   - File icon placeholder
   - "You can still write custom notes below"

#### **Same Status Selection**
1. **Current: "Pending", Select: "Pending"**
2. **Should show standard pending templates**
3. **Not restricted to transitions**

## **Expected Results Summary**

### **✅ Template Counts by Status:**
- **Pending**: 4 templates
- **Under Investigation**: 6 templates  
- **Requires More Information**: 5 templates
- **Resolved**: 5 templates
- **Dismissed**: 5 templates
- **Total**: 25 main templates

### **✅ Auto-Population Features:**
- **Professional text** pre-written for all scenarios
- **Appropriate urgency levels** (low/normal/high/urgent)
- **Smart follow-up dates** (1-14 days based on template)
- **Hover previews** showing full template text

### **✅ Bidirectional Support:**
- **Forward progression**: Pending → Investigation → Resolved
- **Reverse workflows**: Investigation → Pending (with different templates)
- **Skip scenarios**: Requires More Info → Resolved
- **Complex paths**: Any status to any other status

## **Common Issues to Test**

### **Template Filtering**
- ❌ **Wrong templates**: Templates for wrong status appearing
- ❌ **Missing templates**: Expected templates not showing
- ❌ **Category errors**: Templates in wrong category

### **Auto-Population**
- ❌ **Field not filled**: Notes, urgency, or date not auto-setting
- ❌ **Wrong urgency**: Template urgency not matching expectation
- ❌ **Date calculation**: Follow-up date incorrectly calculated

### **UI/UX Issues**
- ❌ **Template overflow**: Too many templates breaking layout
- ❌ **Loading state**: Templates not updating when status changes
- ❌ **Responsive design**: Templates not displaying well on mobile

## **Success Criteria**

### **Functionality (Must Pass)**
- [ ] All 25 templates load correctly
- [ ] Templates filter properly by status transition
- [ ] Auto-population works for notes, urgency, and dates
- [ ] All bidirectional workflows supported
- [ ] Professional text appropriate for each scenario

### **User Experience (Must Pass)**
- [ ] Clear visual indication of status transition
- [ ] Templates organized and easy to find
- [ ] Fast template selection and application
- [ ] Helpful when no templates available
- [ ] Responsive design works on all devices

### **Professional Quality (Must Pass)**
- [ ] All template text is professional and appropriate
- [ ] Consistent terminology across templates
- [ ] Proper urgency levels for each scenario
- [ ] Realistic follow-up timeframes
- [ ] Complete coverage of all workflow scenarios

This comprehensive template system should significantly improve the quality and consistency of status updates while reducing the time officers spend writing update notes.