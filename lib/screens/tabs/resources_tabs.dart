import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this dependency

import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class ResourcesTab extends StatefulWidget {
  const ResourcesTab({super.key});

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  List<String> get _filters => [
    'All',
    'Laws & Regulations',
    'Government Agencies',
    'Educational Material',
    'Legal Databases',
    'International Resources',
  ];

  final List<Resource> _resources = [
    // === PRIMARY CYBERCRIME LAWS ===
    Resource(
      id: '1',
      title: 'Cybercrime Prevention Act of 2012 (RA 10175)',
      description: 'The main law defining and penalizing cybercrimes in the Philippines',
      category: 'Laws & Regulations',
      url: 'https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/',
      type: ResourceType.external,
    ),
    Resource(
      id: '2',
      title: 'Data Privacy Act of 2012 (RA 10173)',
      description: 'Protects personal data and privacy rights of Filipino citizens',
      category: 'Laws & Regulations',
      url: 'https://www.officialgazette.gov.ph/2012/08/15/republic-act-no-10173/',
      type: ResourceType.external,
    ),
    Resource(
      id: '3',
      title: 'E-Commerce Act of 2000 (RA 8792)',
      description: 'Legal framework for electronic transactions and digital signatures',
      category: 'Laws & Regulations',
      url: 'https://www.officialgazette.gov.ph/2000/06/14/republic-act-no-8792/',
      type: ResourceType.external,
    ),
    Resource(
      id: '4',
      title: 'Anti-Child Pornography Act of 2009 (RA 9775)',
      description: 'Criminalizes child pornography and online sexual exploitation',
      category: 'Laws & Regulations',
      url: 'https://www.officialgazette.gov.ph/2009/11/17/republic-act-no-9775/',
      type: ResourceType.external,
    ),
    Resource(
      id: '5',
      title: 'Access Devices Regulation Act of 1998 (RA 8484)',
      description: 'Regulates access devices and penalizes fraudulent use',
      category: 'Laws & Regulations',
      url: 'https://lawphil.net/statutes/repacts/ra1998/ra_8484_1998.html',
      type: ResourceType.external,
    ),
    Resource(
      id: '6',
      title: 'Special Protection of Children (RA 7610)',
      description: 'Protects children from abuse, exploitation, and discrimination online',
      category: 'Laws & Regulations',
      url: 'https://www.officialgazette.gov.ph/1992/06/17/republic-act-no-7610/',
      type: ResourceType.external,
    ),
    Resource(
      id: '7',
      title: 'Revised Penal Code - Cybercrime Provisions',
      description: 'Traditional crimes adapted for cyberspace under RA 10175',
      category: 'Laws & Regulations',
      url: 'https://lawphil.net/statutes/repacts/ra2012/ra_10175_2012.html',
      type: ResourceType.external,
    ),
    Resource(
      id: '8',
      title: 'Anti-Money Laundering Act (RA 9160)',
      description: 'Includes provisions for digital financial crimes and cryptocurrency',
      category: 'Laws & Regulations',
      url: 'https://www.officialgazette.gov.ph/2001/09/29/republic-act-no-9160/',
      type: ResourceType.external,
    ),
    Resource(
      id: '9',
      title: 'Bayanihan to Heal as One Act - Fake News Provisions',
      description: 'Emergency powers including fake news and misinformation penalties',
      category: 'Laws & Regulations',
      url: 'https://lawphil.net/statutes/repacts/ra2020/ra_11469_2020.html',
      type: ResourceType.external,
    ),

    // === GOVERNMENT AGENCIES ===
    Resource(
      id: '10',
      title: 'DOJ Office of Cybercrime',
      description: 'Department of Justice - Official cybercrime prosecution office',
      category: 'Government Agencies',
      url: 'https://www.doj.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '11',
      title: 'National Privacy Commission (NPC)',
      description: 'Official data privacy regulator and enforcement agency',
      category: 'Government Agencies',
      url: 'https://www.privacy.gov.ph/',
      type: ResourceType.external,
    ),
    Resource(
      id: '12',
      title: 'PNP Anti-Cybercrime Group (ACG)',
      description: 'Philippine National Police cybercrime investigation unit',
      category: 'Government Agencies',
      url: 'https://pnp.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '13',
      title: 'NBI Cybercrime Division',
      description: 'National Bureau of Investigation cybercrime investigations',
      category: 'Government Agencies',
      url: 'https://nbi.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '14',
      title: 'DICT - Cybersecurity Office',
      description: 'Department of ICT cybersecurity policies and programs',
      category: 'Government Agencies',
      url: 'https://dict.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '15',
      title: 'BSP Cybersecurity Framework',
      description: 'Bangko Sentral ng Pilipinas cybersecurity for financial institutions',
      category: 'Government Agencies',
      url: 'https://www.bsp.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '16',
      title: 'CICC - Cybercrime Investigation Office',
      description: 'Cybercrime Investigation and Coordinating Center',
      category: 'Government Agencies',
      url: 'https://doj.gov.ph',
      type: ResourceType.external,
    ),

    // === LEGAL DATABASES ===
    Resource(
      id: '17',
      title: 'LawPhil - Cybercrime Laws Database',
      description: 'Comprehensive database of Philippine cybercrime laws and cases',
      category: 'Legal Databases',
      url: 'https://lawphil.net/',
      type: ResourceType.external,
    ),
    Resource(
      id: '18',
      title: 'Official Gazette - Cybercrime Laws',
      description: 'Government official publication of all cybercrime legislation',
      category: 'Legal Databases',
      url: 'https://www.officialgazette.gov.ph/',
      type: ResourceType.external,
    ),
    Resource(
      id: '19',
      title: 'Supreme Court E-Library',
      description: 'Philippine Supreme Court decisions on cybercrime cases',
      category: 'Legal Databases',
      url: 'https://elibrary.judiciary.gov.ph/',
      type: ResourceType.external,
    ),

    // === EDUCATIONAL MATERIALS ===
    Resource(
      id: '20',
      title: 'Data Privacy Information - NPC',
      description: 'National Privacy Commission data privacy information and guidelines',
      category: 'Educational Material',
      url: 'https://www.privacy.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '21',
      title: 'Anti-Cyberbullying Guidelines - DepEd',
      description: 'Department of Education guidelines for preventing cyberbullying',
      category: 'Educational Material',
      url: 'https://www.deped.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '22',
      title: 'Child Protection Resources - UNICEF Philippines',
      description: 'Guidelines for protecting children from online exploitation',
      category: 'Educational Material',
      url: 'https://www.unicef.org/philippines',
      type: ResourceType.external,
    ),
    Resource(
      id: '23',
      title: 'Financial Security Guidelines - BSP',
      description: 'Banking cybersecurity and financial fraud prevention',
      category: 'Educational Material',
      url: 'https://www.bsp.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '24',
      title: 'Cybersecurity Best Practices',
      description: 'Internal guide on cybersecurity practices and online safety tips',
      category: 'Educational Material',
      type: ResourceType.internal,
    ),
    Resource(
      id: '25',
      title: 'Online Scam Prevention Guide',
      description: 'Learn to identify and avoid common online scams and fraud',
      category: 'Educational Material',
      type: ResourceType.internal,
    ),
    Resource(
      id: '26',
      title: 'Identity Protection Tips',
      description: 'How to protect personal information from cybercriminals',
      category: 'Educational Material',
      type: ResourceType.internal,
    ),
    Resource(
      id: '27',
      title: 'Safe Social Media Practices',
      description: 'Guidelines for protecting privacy and security on social platforms',
      category: 'Educational Material',
      type: ResourceType.internal,
    ),

    // === INTERNATIONAL RESOURCES ===
    Resource(
      id: '28',
      title: 'INTERPOL Cybercrime Guidelines',
      description: 'International cybercrime investigation and cooperation protocols',
      category: 'International Resources',
      url: 'https://www.interpol.int/Crimes/Cybercrime',
      type: ResourceType.external,
    ),
    Resource(
      id: '29',
      title: 'UNODC Cybercrime Resources',
      description: 'UN Office on Drugs and Crime cybercrime prevention materials',
      category: 'International Resources',
      url: 'https://www.unodc.org/unodc/en/cybercrime/global-programme-cybercrime.html',
      type: ResourceType.external,
    ),

    // === TECHNICAL RESOURCES ===
    Resource(
      id: '30',
      title: 'Philippine CERT (PH-CERT)',
      description: 'Computer Emergency Response Team - incident reporting and response',
      category: 'Government Agencies',
      url: 'https://cert.gov.ph',
      type: ResourceType.external,
    ),
    Resource(
      id: '31',
      title: 'National Cybersecurity Framework',
      description: 'Philippine national cybersecurity policies and implementation guide',
      category: 'Educational Material',
      url: 'https://dict.gov.ph',
      type: ResourceType.external,
    ),
  ];

  List<Resource> get filteredResources {
    return _resources.where((resource) {
      final matchesSearch = resource.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          resource.description.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' ||
          resource.category == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      // Check if URL can be launched
      if (await canLaunchUrl(uri)) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault, // Let platform decide best way to open
        );

        if (!launched) {
          _showErrorSnackBar('Failed to open link');
        }
      } else {
        // Try alternative launch methods
        try {
          await launchUrl(uri);
        } catch (e) {
          _showErrorSnackBar('No app available to open this link');
        }
      }
    } catch (e) {
      print('URL launch error: $e'); // For debugging
      _showErrorSnackBar('Error opening link');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleResourceTap(Resource resource) {
    if (resource.type == ResourceType.external && resource.url != null) {
      _openUrl(resource.url!);
    } else if (resource.type == ResourceType.internal) {
      // Navigate to internal resource details page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResourceDetailsPage(resource: resource),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate('resources'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('learn_cybercrime_laws'),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${filteredResources.length} resources available',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: languageProvider.translate('search_resources'),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF334155) : Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[100],
                    selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: isSelected
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    elevation: isSelected ? 4 : 0,
                    shadowColor: isSelected
                        ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3)
                        : null,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredResources.length,
              itemBuilder: (context, index) {
                final resource = filteredResources[index];
                return ResourceCard(
                  resource: resource,
                  onTap: () => _handleResourceTap(resource),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum ResourceType {
  external, // Opens in browser
  internal, // Opens in app
}

class Resource {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? url;
  final ResourceType type;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.url,
    this.type = ResourceType.internal,
  });
}

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resource.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    if (resource.type == ResourceType.external)
                      Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  resource.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3B82F6).withOpacity(0.2)
                            : const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3B82F6).withOpacity(0.5)
                              : const Color(0xFF2563EB).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        resource.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for internal resource details page
class ResourceDetailsPage extends StatelessWidget {
  final Resource resource;

  const ResourceDetailsPage({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(resource.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              resource.description,
              style: const TextStyle(fontSize: 16),
            ),
            // Add more detailed content here
          ],
        ),
      ),
    );
  }
}
