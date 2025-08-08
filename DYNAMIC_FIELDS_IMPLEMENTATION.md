# LawBot Dynamic Fields System - Complete Implementation Guide

## Overview
The LawBot platform uses a sophisticated dynamic field system that displays relevant form fields based on the selected crime type. This ensures users only see fields pertinent to their specific cybercrime report, improving user experience and data quality.

## Implementation Status
- ✅ **Flutter Mobile App**: Fully implemented in `lib/models/dynamic_field_config.dart`
- ✅ **Next.js Web App**: Fully implemented in `src/components/modals/case-detail-modal.tsx`
- ✅ **Database**: All fields exist as columns in the `complaints` table

## Complete Crime Type to Category Mapping

### 📱 Communication & Social Media Crimes (7 types)
- `phishing` → Phishing
- `socialEngineering` → Social Engineering  
- `spamMessages` → Spam Messages
- `fakeSocialMediaProfiles` → Fake Social Media Profiles
- `onlineImpersonation` → Online Impersonation
- `businessEmailCompromise` → Business Email Compromise
- `smsFraud` → SMS Fraud

**Dynamic Fields**: incident_location, platform_website, account_reference, financial_loss, suspect_name, suspect_relationship, suspect_contact, suspect_details

### 💰 Financial & Economic Crimes (9 types)
- `onlineBankingFraud` → Online Banking Fraud
- `creditCardFraud` → Credit Card Fraud
- `investmentScams` → Investment Scams
- `cryptocurrencyFraud` → Cryptocurrency Fraud
- `onlineShoppingScams` → Online Shopping Scams
- `paymentGatewayFraud` → Payment Gateway Fraud
- `insuranceFraud` → Insurance Fraud
- `taxFraud` → Tax Fraud
- `moneyLaundering` → Money Laundering

**Dynamic Fields**: incident_location, platform_website, account_reference, financial_loss, suspect_name, suspect_contact

### 🔒 Data & Privacy Crimes (8 types)
- `identityTheft` → Identity Theft
- `dataBreach` → Data Breach
- `unauthorizedSystemAccess` → Unauthorized System Access
- `corporateEspionage` → Corporate Espionage
- `governmentDataTheft` → Government Data Theft
- `medicalRecordsTheft` → Medical Records Theft
- `personalInformationTheft` → Personal Information Theft
- `accountTakeover` → Account Takeover

**Dynamic Fields**: incident_location, account_reference, technical_info, vulnerability_details, security_level, impact_assessment

### 💻 Malware & System Attacks (10 types)
- `ransomware` → Ransomware
- `virusAttacks` → Virus Attacks
- `trojanHorses` → Trojan Horses
- `spyware` → Spyware
- `adware` → Adware
- `worms` → Worms
- `keyloggers` → Keyloggers
- `rootkits` → Rootkits
- `cryptojacking` → Cryptojacking
- `botnetAttacks` → Botnet Attacks

**Dynamic Fields**: system_details, technical_info, attack_vector

### 👥 Harassment & Exploitation (8 types)
- `cyberstalking` → Cyberstalking
- `onlineHarassment` → Online Harassment
- `cyberbullying` → Cyberbullying
- `revengePorn` → Revenge Porn
- `sextortion` → Sextortion
- `onlinePredatoryBehavior` → Online Predatory Behavior
- `doxxing` → Doxxing
- `hateSpeech` → Hate Speech

**Dynamic Fields**: incident_location, platform_website, suspect_name, suspect_relationship, suspect_contact, suspect_details, content_description

### 🚫 Content-Related Crimes (8 types)
- `childSexualAbuseMaterial` → Child Sexual Abuse Material
- `illegalContentDistribution` → Illegal Content Distribution
- `copyrightInfringement` → Copyright Infringement
- `softwarePiracy` → Software Piracy
- `illegalOnlineGambling` → Illegal Online Gambling
- `onlineDrugTrafficking` → Online Drug Trafficking
- `illegalWeaponsSales` → Illegal Weapons Sales
- `humanTrafficking` → Human Trafficking

**Dynamic Fields**: incident_location, platform_website, financial_loss, suspect_name, suspect_contact, content_description

### ⚡ System Disruption & Sabotage (7 types)
- `denialOfServiceAttacks` → Denial of Service Attacks
- `websiteDefacement` → Website Defacement
- `systemSabotage` → System Sabotage
- `networkIntrusion` → Network Intrusion
- `sqlInjection` → SQL Injection
- `crossSiteScripting` → Cross-Site Scripting
- `manInTheMiddleAttacks` → Man-in-the-Middle Attacks

**Dynamic Fields**: system_details, technical_info, vulnerability_details, attack_vector, impact_assessment

### 🏛️ Government & Terrorism (7 types)
- `cyberterrorism` → Cyberterrorism
- `cyberWarfare` → Cyber Warfare
- `governmentSystemHacking` → Government System Hacking
- `electionInterference` → Election Interference
- `criticalInfrastructureAttacks` → Critical Infrastructure Attacks
- `propagandaDistribution` → Propaganda Distribution
- `stateSponsoredAttacks` → State-Sponsored Attacks

**Dynamic Fields**: incident_location, security_level, target_info, impact_assessment

### 🔍 Technical Exploitation (6 types)
- `zeroDayExploits` → Zero-Day Exploits
- `vulnerabilityExploitation` → Vulnerability Exploitation
- `backdoorCreation` → Backdoor Creation
- `privilegeEscalation` → Privilege Escalation
- `codeInjection` → Code Injection
- `bufferOverflowAttacks` → Buffer Overflow Attacks

**Dynamic Fields**: system_details, technical_info, vulnerability_details, target_info, attack_vector, impact_assessment

### 🎯 Targeted Attacks (5 types)
- `advancedPersistentThreats` → Advanced Persistent Threats
- `spearPhishing` → Spear Phishing
- `ceoFraud` → CEO Fraud
- `supplyChainAttacks` → Supply Chain Attacks
- `insiderThreats` → Insider Threats

**Dynamic Fields**: target_info, attack_vector, impact_assessment

## Dynamic Field Definitions

| Field ID | Label | Type | Description | Categories Using This Field |
|----------|-------|------|-------------|-----------------------------|
| `incident_location` | 📍 Incident Location | Text | Where did this incident occur? | Communication, Financial, Data, Harassment, Content, Government |
| `platform_website` | 📱 Platform/Website | Text | Facebook, Instagram, GCash, etc. | Communication, Financial, Harassment, Content |
| `account_reference` | 🔢 Account/Reference | Text | Transaction ID, account number, reference code | Communication, Financial, Data |
| `financial_loss` | 💰 Financial Loss | Currency | Amount in Philippine Pesos (₱) | Communication, Financial, Content |
| `suspect_name` | 🎭 Suspect Name/Alias | Text | Real name, nickname, or username | Communication, Financial, Harassment, Content |
| `suspect_relationship` | 👥 Suspect Relationship | Enum | How do you know the suspect? | Communication, Harassment |
| `suspect_contact` | 📞 Suspect Contact | Text | Phone, email, social media handle | Communication, Financial, Harassment, Content |
| `suspect_details` | 📝 Suspect Details | Text | Physical description, location, other details | Communication, Harassment |
| `system_details` | 💻 System/Device Details | Text | Operating system, device type, software affected | Malware, System Disruption, Technical |
| `technical_info` | ⚙️ Technical Information | Text | Error messages, file names, network details | Data, Malware, System Disruption, Technical |
| `vulnerability_details` | 🔓 Vulnerability Details | Text | How the system was compromised | Data, System Disruption, Technical |
| `attack_vector` | 🎯 Attack Method/Vector | Text | How the attack was executed | Malware, System Disruption, Technical, Targeted |
| `security_level` | 🔒 Security Classification | Enum | Public, Confidential, Restricted, etc. | Data, Government |
| `target_info` | 🎯 Target Information | Text | Who or what was targeted | Government, Technical, Targeted |
| `content_description` | 📄 Content Description | Text | Description of illegal content (no explicit details) | Harassment, Content |
| `impact_assessment` | 📊 Impact Assessment | Text | How has this affected you or your organization? | Data, System Disruption, Government, Technical, Targeted |

## Field Display Logic

### Web App (case-detail-modal.tsx)
```typescript
// 1. Determine crime type
const crimeType = complaint.crime_type || '';

// 2. Map to category
const category = crimeTypeToCategory[crimeType];

// 3. Get relevant fields
const relevantFields = categoryFields[category] || [];

// 4. Filter populated fields
relevantFields.forEach(fieldKey => {
  const value = complaint[fieldKey];
  if (value) {
    // Display field
  }
});
```

### Mobile App (dynamic_field_config.dart)
```dart
// Get fields for category
List<ComplaintField> fields = DynamicFieldConfig.getFieldsForCategory(category);

// Check visibility
bool isVisible = DynamicFieldConfig.isFieldVisible(field, category);
```

## Special Field Behaviors

### Financial Loss
- Only displayed if value > 0
- Formatted with Philippine Peso symbol (₱)
- Uses locale formatting (en-PH)

### Security Level
- Auto-capitalized (public → Public)
- Enum values: Public, Confidential, Restricted, Top Secret

### Suspect Relationship
- Converts underscores to spaces
- Title case formatting (online_contact → Online Contact)
- Options: Unknown, Acquaintance, Friend/Ex-friend, Family Member, Ex-partner/Romantic, Colleague/Classmate, Online Contact Only, Complete Stranger

### Evidence Files
- Always visible (core field)
- Max 5 files, 25MB total
- Supports images, documents, videos

## Implementation Consistency

Both Flutter and Web implementations:
1. Use identical crime type to category mappings
2. Display same fields for each category
3. Apply same visibility rules
4. Format data consistently
5. Share field configurations

This ensures a seamless experience whether users are:
- Submitting reports via mobile app
- Viewing cases in web dashboard
- Transferring between platforms

## Testing Dynamic Fields

To test the dynamic field system:

1. **Select Crime Type**: Choose any of the 67 crime types
2. **Observe Fields**: Only relevant fields should appear
3. **Fill Data**: Enter data in displayed fields
4. **Submit**: All populated fields save to database
5. **View in Web**: Same fields display in case details

The system automatically handles:
- Field visibility based on crime category
- Data validation per field type
- Formatting for display
- Database storage and retrieval