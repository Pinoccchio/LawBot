📋 Core Fields (Always Required for All Crime Types)

  1. crimeType - Crime Type Selection
  2. description - Detailed Case Description
  3. incidentDateTime - When the Crime Occurred
  4. fullName - Complainant's Full Name
  5. email - Email Address
  6. phone - Phone Number
  7. evidenceFiles - Evidence Uploads (Optional)
  8. officer - Auto-assigned Based on Crime Category

  🏷️ Crime Categories and Their Dynamic Fields

  📱 1. Communication & Social Media Crimes

  Assigned Unit: Cyber Crime Investigation Cell

  Crime Types (7):
  - Phishing
  - Social Engineering
  - Spam Messages
  - Fake Social Media Profiles
  - Online Impersonation
  - Business Email Compromise
  - SMS Fraud

  Dynamic Fields:
  - incidentLocation - Where incident occurred
  - platformWebsite - Platform/Website involved (Facebook, Instagram,
  etc.)
  - accountReference - Account/Reference numbers
  - financialLoss - Financial Loss Amount (₱)
  - suspectName - Suspect Name/Alias
  - suspectRelationship - Relationship to Suspect
  - suspectContact - Suspect Contact Information
  - suspectDetails - Additional Suspect Details

  💰 2. Financial & Economic Crimes

  Assigned Unit: Economic Offenses Wing

  Crime Types (9):
  - Online Banking Fraud
  - Credit Card Fraud
  - Investment Scams
  - Cryptocurrency Fraud
  - Online Shopping Scams
  - Payment Gateway Fraud
  - Insurance Fraud
  - Tax Fraud
  - Money Laundering

  Dynamic Fields:
  - incidentLocation - Physical location if applicable
  - platformWebsite - Bank website, payment platform
  - accountReference - Transaction IDs, account numbers
  - financialLoss - Exact amount lost (₱)
  - suspectName - Known fraudster information
  - suspectContact - How suspect contacted victim

  🔒 3. Data & Privacy Crimes

  Assigned Unit: Cyber Security Division

  Crime Types (8):
  - Identity Theft
  - Data Breach
  - Unauthorized System Access
  - Corporate Espionage
  - Government Data Theft
  - Medical Records Theft
  - Personal Information Theft
  - Account Takeover

  Dynamic Fields:
  - incidentLocation - Physical or network location
  - accountReference - Affected account identifiers
  - technicalInfo - Error messages, network details
  - vulnerabilityDetails - How system was compromised
  - securityLevel - Security Classification
  (Public/Confidential/Restricted)
  - impactAssessment - How this affected you/organization

  💻 4. Malware & System Attacks

  Assigned Unit: Cyber Crime Technical Unit

  Crime Types (10):
  - Ransomware
  - Virus Attacks
  - Trojan Horses
  - Spyware
  - Adware
  - Worms
  - Keyloggers
  - Rootkits
  - Cryptojacking
  - Botnet Attacks

  Dynamic Fields:
  - systemDetails - OS, device type, affected software
  - technicalInfo - Error messages, file names, network details
  - attackVector - How the attack was executed

  👥 5. Harassment & Exploitation

  Assigned Unit: Cyber Crime Against Women and Children

  Crime Types (8):
  - Cyberstalking
  - Online Harassment
  - Cyberbullying
  - Revenge Porn
  - Sextortion
  - Online Predatory Behavior
  - Doxxing
  - Hate Speech

  Dynamic Fields:
  - incidentLocation - Platform or physical location
  - platformWebsite - Where harassment occurred
  - suspectName - Harasser's identity if known
  - suspectRelationship - Relationship type
  - suspectContact - How to identify suspect
  - suspectDetails - Physical description, patterns
  - contentDescription - General description (no explicit details)

  🚫 6. Content-Related Crimes

  Assigned Unit: Special Investigation Team

  Crime Types (8):
  - Child Sexual Abuse Material
  - Illegal Content Distribution
  - Copyright Infringement
  - Software Piracy
  - Illegal Online Gambling
  - Online Drug Trafficking
  - Illegal Weapons Sales
  - Human Trafficking

  Dynamic Fields:
  - incidentLocation - Where content was found
  - platformWebsite - Website or platform hosting content
  - financialLoss - Economic impact if applicable
  - suspectName - Content distributor/seller
  - suspectContact - How suspect can be reached
  - contentDescription - General description (no explicit details)

  ⚡ 7. System Disruption & Sabotage

  Assigned Unit: Critical Infrastructure Protection Unit

  Crime Types (7):
  - Denial of Service Attacks
  - Website Defacement
  - System Sabotage
  - Network Intrusion
  - SQL Injection
  - Cross-Site Scripting
  - Man-in-the-Middle Attacks

  Dynamic Fields:
  - systemDetails - Affected systems and infrastructure
  - technicalInfo - Technical details of the attack
  - vulnerabilityDetails - How system was compromised
  - attackVector - Method used to carry out attack
  - impactAssessment - Business/operational impact

  🏛️ 8. Government & Terrorism

  Assigned Unit: National Security Cyber Division

  Crime Types (7):
  - Cyberterrorism
  - Cyber Warfare
  - Government System Hacking
  - Election Interference
  - Critical Infrastructure Attacks
  - Propaganda Distribution
  - State-Sponsored Attacks

  Dynamic Fields:
  - incidentLocation - Geographic or network location
  - securityLevel - Security level of affected systems
  - targetInfo - What/who was targeted
  - impactAssessment - National security impact

  🔍 9. Technical Exploitation

  Assigned Unit: Advanced Cyber Forensics Unit

  Crime Types (6):
  - Zero-Day Exploits
  - Vulnerability Exploitation
  - Backdoor Creation
  - Privilege Escalation
  - Code Injection
  - Buffer Overflow Attacks

  Dynamic Fields:
  - systemDetails - Technical system specifications
  - technicalInfo - Detailed technical analysis
  - vulnerabilityDetails - Specific vulnerability exploited
  - targetInfo - Technical target details
  - attackVector - Technical attack methodology
  - impactAssessment - Technical and business impact

  🎯 10. Targeted Attacks

  Assigned Unit: Special Cyber Operations Unit

  Crime Types (5):
  - Advanced Persistent Threats
  - Spear Phishing
  - CEO Fraud
  - Supply Chain Attacks
  - Insider Threats

  Dynamic Fields:
  - targetInfo - Who/what was specifically targeted
  - attackVector - How the targeted attack was executed
  - impactAssessment - Specific impact of targeted attack

  📊 Dynamic Field Details

  | Field ID             | Label                   | Data Type |
  Description                                           |
  |----------------------|-------------------------|-----------|----------     
  ---------------------------------------------|
  | incidentLocation     | Incident Location       | Text      | Physical      
  or digital location where crime occurred     |
  | platformWebsite      | Platform/Website        | Text      | Digital       
  platform involved (Facebook, Bank site, etc.) |
  | accountReference     | Account/Reference       | Text      |
  Transaction IDs, account numbers, reference codes     |
  | financialLoss        | Financial Loss (₱)      | Currency  | Amount        
  lost or at risk                                |
  | suspectName          | Suspect Name/Alias      | Text      | Real
  name, nickname, or username                      |
  | suspectRelationship  | Relationship to Suspect | Enum      |
  Unknown/Acquaintance/Friend/Family/etc.               |
  | suspectContact       | Suspect Contact         | Text      | Phone,        
  email, social media handle                     |
  | suspectDetails       | Suspect Details         | Text      |
  Additional identifying information                    |
  | systemDetails        | System/Device Details   | Text      | OS,
  device type, software versions                    |
  | technicalInfo        | Technical Information   | Text      | Error
  messages, logs, technical data                  |
  | vulnerabilityDetails | Vulnerability Details   | Text      | How
  system was compromised                            |
  | attackVector         | Attack Method/Vector    | Text      | Method        
  used to execute attack                         |
  | securityLevel        | Security Classification | Enum      |
  Public/Confidential/Restricted/Top Secret             |
  | targetInfo           | Target Information      | Text      | Specific      
  target details                               |
  | contentDescription   | Content Description     | Text      | General       
  description of illegal content                |
  | impactAssessment     | Impact Assessment       | Text      |
  Consequences and effects of the incident              |