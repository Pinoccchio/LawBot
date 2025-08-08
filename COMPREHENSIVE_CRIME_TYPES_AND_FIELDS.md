# Comprehensive Crime Types, Categories, and Required Fields Guide

## Overview

This document provides a complete mapping of all cybercrime types, their categories, assigned PNP units, and the required/optional fields for each case type in the LawBot system.

---

## 📋 Core Fields (Always Required for All Cases)

These fields are **mandatory** for all cybercrime reports, regardless of crime type:

| Field | Label | Type | Required | Description |
|-------|-------|------|----------|-------------|
| `crimeType` | Crime Type | Enum | ✅ Yes | Specific cybercrime being reported |
| `description` | Case Description | Text | ✅ Yes | Detailed description of the incident |
| `incidentDateTime` | Incident Date & Time | DateTime | ✅ Yes | When the crime occurred |
| `fullName` | Full Name | Text | ✅ Yes | Complainant's full legal name |
| `email` | Email Address | Email | ✅ Yes | Primary contact email |
| `phone` | Phone Number | Phone | ✅ Yes | Primary contact number |
| `evidenceFiles` | Evidence Files | FileUpload | 🔹 Optional | Supporting documents/images (max 5, 25MB total) |
| `officer` | Assigned Officer | Text | ⚙️ Auto-assigned | PNP officer handling the case |

---

# 🎯 Crime Categories and Dynamic Fields

## 📱 1. COMMUNICATION & SOCIAL MEDIA CRIMES
**Assigned to:** Cyber Crime Investigation Cell

### Crime Types (7 total):
1. **Phishing** (`phishing`)
2. **Social Engineering** (`socialEngineering`)
3. **Spam Messages** (`spamMessages`)
4. **Fake Social Media Profiles** (`fakeSocialMediaProfiles`)
5. **Online Impersonation** (`onlineImpersonation`)
6. **Business Email Compromise** (`businessEmailCompromise`)
7. **SMS Fraud** (`smsFraud`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `incidentLocation` | Incident Location | Text | 🔹 Optional | Where the incident occurred |
| `platformWebsite` | Platform/Website | Text | ⭐ Important | Facebook, Instagram, Email provider, etc. |
| `accountReference` | Account/Reference | Text | 🔹 Optional | Account numbers, reference codes |
| `financialLoss` | Financial Loss (₱) | Currency | ⭐ Important | Amount lost in scams |
| `suspectName` | Suspect Name/Alias | Text | ⭐ Important | Real name, nickname, username |
| `suspectRelationship` | Relationship to Suspect | Enum | 🔹 Optional | Unknown, Acquaintance, Stranger, etc. |
| `suspectContact` | Suspect Contact Info | Text | ⭐ Important | Phone, email, social media handle |
| `suspectDetails` | Additional Suspect Details | Text | 🔹 Optional | Physical description, other details |

### Evidence Suggestions:
- Screenshots of messages/posts
- Email headers and full messages
- Account information and URLs
- Financial transaction records
- Profile pictures/fake accounts
- Communication logs

---

## 💰 2. FINANCIAL & ECONOMIC CRIMES
**Assigned to:** Economic Offenses Wing

### Crime Types (9 total):
1. **Online Banking Fraud** (`onlineBankingFraud`)
2. **Credit Card Fraud** (`creditCardFraud`)
3. **Investment Scams** (`investmentScams`)
4. **Cryptocurrency Fraud** (`cryptocurrencyFraud`)
5. **Online Shopping Scams** (`onlineShoppingScams`)
6. **Payment Gateway Fraud** (`paymentGatewayFraud`)
7. **Insurance Fraud** (`insuranceFraud`)
8. **Tax Fraud** (`taxFraud`)
9. **Money Laundering** (`moneyLaundering`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `incidentLocation` | Incident Location | Text | 🔹 Optional | Physical location if applicable |
| `platformWebsite` | Platform/Website | Text | ✅ Required | Bank website, payment platform, etc. |
| `accountReference` | Account/Reference | Text | ✅ Required | Transaction IDs, account numbers |
| `financialLoss` | Financial Loss (₱) | Currency | ✅ Required | Exact amount lost or at risk |
| `suspectName` | Suspect Name/Alias | Text | ⭐ Important | Known fraudster information |
| `suspectContact` | Suspect Contact Info | Text | ⭐ Important | How suspect contacted victim |

### Evidence Suggestions:
- Bank statements and transaction records
- Screenshots of fraudulent websites
- Email/SMS communications from fraudsters
- Payment receipts and confirmations
- Cryptocurrency wallet addresses
- Investment documentation

---

## 🔒 3. DATA & PRIVACY CRIMES
**Assigned to:** Cyber Security Division

### Crime Types (8 total):
1. **Identity Theft** (`identityTheft`)
2. **Data Breach** (`dataBreach`)
3. **Unauthorized System Access** (`unauthorizedSystemAccess`)
4. **Corporate Espionage** (`corporateEspionage`)
5. **Government Data Theft** (`governmentDataTheft`)
6. **Medical Records Theft** (`medicalRecordsTheft`)
7. **Personal Information Theft** (`personalInformationTheft`)
8. **Account Takeover** (`accountTakeover`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `incidentLocation` | Incident Location | Text | 🔹 Optional | Physical or network location |
| `accountReference` | Account/Reference | Text | ⭐ Important | Affected account identifiers |
| `technicalInfo` | Technical Information | Text | ⭐ Important | Error messages, network details |
| `vulnerabilityDetails` | Vulnerability Details | Text | 🔹 Optional | How system was compromised |
| `securityLevel` | Security Classification | Enum | ⭐ Important | Public, Confidential, Restricted |
| `impactAssessment` | Impact Assessment | Text | ✅ Required | How this affected you/organization |

### Evidence Suggestions:
- System logs and access records
- Screenshots of unauthorized access
- Data files that were compromised
- Security alerts and notifications
- Network traffic analysis
- Identity verification documents

---

## 💻 4. MALWARE & SYSTEM ATTACKS
**Assigned to:** Cyber Crime Technical Unit

### Crime Types (10 total):
1. **Ransomware** (`ransomware`)
2. **Virus Attacks** (`virusAttacks`)
3. **Trojan Horses** (`trojanHorses`)
4. **Spyware** (`spyware`)
5. **Adware** (`adware`)
6. **Worms** (`worms`)
7. **Keyloggers** (`keyloggers`)
8. **Rootkits** (`rootkits`)
9. **Cryptojacking** (`cryptojacking`)
10. **Botnet Attacks** (`botnetAttacks`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `systemDetails` | System/Device Details | Text | ✅ Required | OS, device type, affected software |
| `technicalInfo` | Technical Information | Text | ✅ Required | Error messages, file names, network details |
| `attackVector` | Attack Method/Vector | Text | ⭐ Important | How the attack was executed |

### Evidence Suggestions:
- Malware samples and file hashes
- System screenshots showing infection
- Antivirus scan results
- Network traffic logs
- Ransom notes or messages
- System performance logs

---

## 👥 5. HARASSMENT & EXPLOITATION
**Assigned to:** Cyber Crime Against Women and Children

### Crime Types (8 total):
1. **Cyberstalking** (`cyberstalking`)
2. **Online Harassment** (`onlineHarassment`)
3. **Cyberbullying** (`cyberbullying`)
4. **Revenge Porn** (`revengePorn`)
5. **Sextortion** (`sextortion`)
6. **Online Predatory Behavior** (`onlinePredatoryBehavior`)
7. **Doxxing** (`doxxing`)
8. **Hate Speech** (`hateSpeech`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `incidentLocation` | Incident Location | Text | 🔹 Optional | Platform or physical location |
| `platformWebsite` | Platform/Website | Text | ✅ Required | Where harassment occurred |
| `suspectName` | Suspect Name/Alias | Text | ⭐ Important | Harasser's identity if known |
| `suspectRelationship` | Relationship to Suspect | Enum | ✅ Required | Relationship type (important for investigation) |
| `suspectContact` | Suspect Contact Info | Text | ⭐ Important | How to identify the suspect |
| `suspectDetails` | Additional Suspect Details | Text | ⭐ Important | Physical description, patterns |
| `contentDescription` | Content Description | Text | ⭐ Important | General description (no explicit details) |

### Evidence Suggestions:
- Screenshots of harassing messages
- Social media posts and profiles
- Email communications
- Photos or videos (if appropriate)
- Witness statements
- Previous incident documentation

---

## 🚫 6. CONTENT-RELATED CRIMES
**Assigned to:** Special Investigation Team

### Crime Types (8 total):
1. **Child Sexual Abuse Material** (`childSexualAbuseMaterial`)
2. **Illegal Content Distribution** (`illegalContentDistribution`)
3. **Copyright Infringement** (`copyrightInfringement`)
4. **Software Piracy** (`softwarePiracy`)
5. **Illegal Online Gambling** (`illegalOnlineGambling`)
6. **Online Drug Trafficking** (`onlineDrugTrafficking`)
7. **Illegal Weapons Sales** (`illegalWeaponsSales`)
8. **Human Trafficking** (`humanTrafficking`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `incidentLocation` | Incident Location | Text | 🔹 Optional | Where content was found/distributed |
| `platformWebsite` | Platform/Website | Text | ✅ Required | Website or platform hosting content |
| `financialLoss` | Financial Loss (₱) | Currency | ⭐ Important | Economic impact if applicable |
| `suspectName` | Suspect Name/Alias | Text | ⭐ Important | Content distributor/seller |
| `suspectContact` | Suspect Contact Info | Text | ⭐ Important | How suspect can be reached |
| `contentDescription` | Content Description | Text | ✅ Required | General description (no explicit details) |

### Evidence Suggestions:
- URLs and website screenshots
- Payment records for illegal purchases
- Communication with sellers/distributors
- Copyright documentation
- Platform reporting confirmations
- **Note:** NO explicit content should be uploaded

---

## ⚡ 7. SYSTEM DISRUPTION & SABOTAGE
**Assigned to:** Critical Infrastructure Protection Unit

### Crime Types (7 total):
1. **Denial of Service Attacks** (`denialOfServiceAttacks`)
2. **Website Defacement** (`websiteDefacement`)
3. **System Sabotage** (`systemSabotage`)
4. **Network Intrusion** (`networkIntrusion`)
5. **SQL Injection** (`sqlInjection`)
6. **Cross-Site Scripting** (`crossSiteScripting`)
7. **Man-in-the-Middle Attacks** (`manInTheMiddleAttacks`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `systemDetails` | System/Device Details | Text | ✅ Required | Affected systems and infrastructure |
| `technicalInfo` | Technical Information | Text | ✅ Required | Technical details of the attack |
| `vulnerabilityDetails` | Vulnerability Details | Text | ⭐ Important | How system was compromised |
| `attackVector` | Attack Method/Vector | Text | ✅ Required | Method used to carry out attack |
| `impactAssessment` | Impact Assessment | Text | ✅ Required | Business/operational impact |

### Evidence Suggestions:
- Network logs and traffic analysis
- System availability reports
- Screenshots of defaced websites
- Server logs and error messages
- Security monitoring alerts
- Business impact documentation

---

## 🏛️ 8. GOVERNMENT & TERRORISM
**Assigned to:** National Security Cyber Division

### Crime Types (7 total):
1. **Cyberterrorism** (`cyberterrorism`)
2. **Cyber Warfare** (`cyberWarfare`)
3. **Government System Hacking** (`governmentSystemHacking`)
4. **Election Interference** (`electionInterference`)
5. **Critical Infrastructure Attacks** (`criticalInfrastructureAttacks`)
6. **Propaganda Distribution** (`propagandaDistribution`)
7. **State-Sponsored Attacks** (`stateSponsoredAttacks`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `incidentLocation` | Incident Location | Text | ⭐ Important | Geographic or network location |
| `securityLevel` | Security Classification | Enum | ✅ Required | Security level of affected systems |
| `targetInfo` | Target Information | Text | ✅ Required | What/who was targeted |
| `impactAssessment` | Impact Assessment | Text | ✅ Required | National security impact |

### Evidence Suggestions:
- Government system logs
- Security incident reports
- Intelligence assessments
- Network forensic evidence
- Communication intercepts
- **Note:** Classified information requires special handling

---

## 🔍 9. TECHNICAL EXPLOITATION
**Assigned to:** Advanced Cyber Forensics Unit

### Crime Types (6 total):
1. **Zero-Day Exploits** (`zeroDayExploits`)
2. **Vulnerability Exploitation** (`vulnerabilityExploitation`)
3. **Backdoor Creation** (`backdoorCreation`)
4. **Privilege Escalation** (`privilegeEscalation`)
5. **Code Injection** (`codeInjection`)
6. **Buffer Overflow Attacks** (`bufferOverflowAttacks`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `systemDetails` | System/Device Details | Text | ✅ Required | Technical system specifications |
| `technicalInfo` | Technical Information | Text | ✅ Required | Detailed technical analysis |
| `vulnerabilityDetails` | Vulnerability Details | Text | ✅ Required | Specific vulnerability exploited |
| `targetInfo` | Target Information | Text | ⭐ Important | Technical target details |
| `attackVector` | Attack Method/Vector | Text | ✅ Required | Technical attack methodology |
| `impactAssessment` | Impact Assessment | Text | ⭐ Important | Technical and business impact |

### Evidence Suggestions:
- Exploit code and payloads
- Vulnerability scan results
- System memory dumps
- Network packet captures
- Source code analysis
- Forensic imaging of affected systems

---

## 🎯 10. TARGETED ATTACKS
**Assigned to:** Special Cyber Operations Unit

### Crime Types (5 total):
1. **Advanced Persistent Threats** (`advancedPersistentThreats`)
2. **Spear Phishing** (`spearPhishing`)
3. **CEO Fraud** (`ceoFraud`)
4. **Supply Chain Attacks** (`supplyChainAttacks`)
5. **Insider Threats** (`insiderThreats`)

### Required Dynamic Fields:
| Field | Label | Type | Priority | Description |
|-------|-------|------|----------|-------------|
| `targetInfo` | Target Information | Text | ✅ Required | Who/what was specifically targeted |
| `attackVector` | Attack Method/Vector | Text | ✅ Required | How the targeted attack was executed |
| `impactAssessment` | Impact Assessment | Text | ✅ Required | Specific impact of targeted attack |

### Evidence Suggestions:
- Targeted phishing emails
- Command and control communications
- Lateral movement evidence
- Data exfiltration logs
- Timeline of attack progression
- Attribution indicators

---

# 📊 Field Priority Legend

| Symbol | Priority Level | Description |
|--------|---------------|-------------|
| ✅ | **Required** | Must be filled for case processing |
| ⭐ | **Important** | Highly recommended for investigation |
| 🔹 | **Optional** | Helpful but not essential |
| ⚙️ | **Auto-assigned** | Automatically populated by system |

---

# 🔗 Suspect Relationship Options

For cases requiring `suspectRelationship` field:

- **Unknown** - No information about relationship
- **Acquaintance** - Someone known casually
- **Friend/Ex-friend** - Current or former friend
- **Family Member** - Relative
- **Ex-partner/Romantic** - Former romantic relationship
- **Colleague/Classmate** - Work or school relationship
- **Online Contact Only** - Met only through internet
- **Complete Stranger** - No prior relationship

---

# 🚨 Important Case Processing Notes

## AI-Enhanced Processing
- All cases undergo **AI Risk Assessment** for priority scoring
- **Pattern Detection** identifies potential serial offenders
- **Evidence Guidance** provides contextual evidence suggestions
- **Credibility Scoring** assesses report completeness

## Evidence Guidelines
- **Maximum**: 5 files per case
- **Size Limit**: 25MB total
- **Accepted Formats**: Images (JPG, PNG), Documents (PDF, DOC), Videos (MP4, MOV)
- **Security**: All evidence encrypted and access-controlled

## Case Assignment Process
1. **Crime Type Selection** → Automatic PNP unit assignment
2. **AI Risk Assessment** → Priority level determination
3. **Officer Assignment** → Based on workload and specialization
4. **Status Tracking** → 5-stage workflow monitoring

## Response Time Expectations
- **High Priority**: 24 hours
- **Medium Priority**: 72 hours  
- **Low Priority**: 7 days

---

*This comprehensive guide ensures consistent, thorough cybercrime reporting and investigation across all PNP units handling cybercrime cases in the Philippines.*